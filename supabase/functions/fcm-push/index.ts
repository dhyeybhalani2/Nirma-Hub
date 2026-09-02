import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    
    // We only care about INSERT events
    if (payload.type !== 'INSERT') {
      return new Response(JSON.stringify({ message: "Not an INSERT event" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const record = payload.record;
    if (!record || !record.title || !record.message) {
      return new Response(JSON.stringify({ error: "Missing title or message" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    // Read Firebase credentials from environment variables (stored in Supabase Secrets)
    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL');
    const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n');
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID');

    if (!clientEmail || !privateKey || !projectId) {
      throw new Error("Missing Firebase environment variables");
    }

    // 1. Create JWT
    const iat = Math.floor(Date.now() / 1000);
    const exp = iat + 3600;
    
    const pkcs8Key = await jose.importPKCS8(privateKey, 'RS256');
    const jwt = await new jose.SignJWT({
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
    })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuedAt(iat)
      .setExpirationTime(exp)
      .sign(pkcs8Key);

    // 2. Exchange JWT for Google OAuth2 Access Token
    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    });
    
    const tokenData = await tokenRes.json();
    if (!tokenRes.ok) throw new Error(tokenData.error_description || 'Failed to get auth token');

    // 3. Send FCM Push Notification
    // If target_year exists and is not 'All', we could use a specific topic.
    // For now, based on the flutter app code, the app subscribes to 'all_users'
    let topic = 'all_users';
    
    const fcmRes = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${tokenData.access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          topic: topic,
          notification: {
            title: record.title,
            body: record.message,
          },
          data: {
            type: record.type || 'other',
          },
          android: {
            priority: 'high',
            notification: {
              channel_id: 'high_importance_channel',
              click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
          },
          apns: {
            payload: {
              aps: {
                contentAvailable: true,
                sound: 'default'
              }
            }
          }
        }
      })
    });
    
    const fcmData = await fcmRes.json();
    if (!fcmRes.ok) throw new Error(fcmData.error?.message || 'Failed to send push notification');

    return new Response(JSON.stringify({ success: true, message: "Push sent via FCM" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
    
  } catch (error) {
    console.error("Error sending push notification:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
