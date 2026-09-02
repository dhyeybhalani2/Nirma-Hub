import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "@supabase/supabase-js";

// Initialize Supabase client
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36";

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Accept both POST and GET for webhook/cron triggers
  if (req.method !== "POST" && req.method !== "GET") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  try {
    console.log("Starting coding profiles update...");

    // 1. Fetch all profiles that have either LeetCode or Codeforces linked
    const { data: profiles, error: fetchError } = await supabase
      .from("coding_profiles")
      .select("id, leetcode_username, codeforces_username")
      .or("leetcode_username.not.is.null,codeforces_username.not.is.null");

    if (fetchError) {
      throw new Error(`Failed to fetch profiles: ${fetchError.message}`);
    }

    if (!profiles || profiles.length === 0) {
      return new Response(JSON.stringify({ message: "No profiles to update" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    console.log(`Found ${profiles.length} profiles to process.`);

    let cfUpdatedCount = 0;
    let lcUpdatedCount = 0;

    // --- Update Codeforces ---
    const cfProfiles = profiles.filter((p) => p.codeforces_username && p.codeforces_username.trim() !== "");
    if (cfProfiles.length > 0) {
      console.log(`Updating ${cfProfiles.length} Codeforces profiles...`);
      let batchSuccess = false;

      // Try batch fetch first
      try {
        const handles = cfProfiles.map((p) => p.codeforces_username.trim()).join(";");
        const cfResponse = await fetch(`https://codeforces.com/api/user.info?handles=${handles}`, {
          headers: { "User-Agent": USER_AGENT },
        });

        if (cfResponse.ok) {
          const cfData = await cfResponse.json();
          if (cfData.status === "OK" && cfData.result) {
            for (const cfUser of cfData.result) {
              const handle = cfUser.handle;
              const profile = cfProfiles.find(
                (p) => p.codeforces_username?.toLowerCase() === handle.toLowerCase()
              );

              if (profile) {
                const currentRating = cfUser.rating || 0;
                const maxRating = cfUser.maxRating || 0;

                const { error: updateError } = await supabase
                  .from("coding_profiles")
                  .update({
                    codeforces_rating: currentRating,
                    codeforces_max_rating: maxRating,
                    updated_at: new Date().toISOString(),
                  })
                  .eq("id", profile.id);

                if (updateError) {
                  console.error(`Error updating Codeforces for ${handle}:`, updateError.message);
                } else {
                  cfUpdatedCount++;
                  console.log(`Updated Codeforces for ${handle}: rating=${currentRating}, maxRating=${maxRating}`);
                }
              }
            }
            batchSuccess = true;
            console.log(`Codeforces batch update completed. (${cfUpdatedCount} updated)`);
          }
        } else {
          console.warn("Codeforces batch fetch returned non-200 status, falling back to individual fetching...");
        }
      } catch (batchErr) {
        console.warn("Codeforces batch fetch error, falling back to individual fetching:", batchErr);
      }

      // If batch failed (e.g. one user has an invalid username), process individually
      if (!batchSuccess) {
        console.log("Processing Codeforces profiles individually...");
        for (const profile of cfProfiles) {
          const handle = profile.codeforces_username.trim();
          try {
            const cfResponse = await fetch(
              `https://codeforces.com/api/user.info?handles=${encodeURIComponent(handle)}`,
              { headers: { "User-Agent": USER_AGENT } }
            );

            if (cfResponse.ok) {
              const cfData = await cfResponse.json();
              if (cfData.status === "OK" && cfData.result && cfData.result.length > 0) {
                const cfUser = cfData.result[0];
                const currentRating = cfUser.rating || 0;
                const maxRating = cfUser.maxRating || 0;

                const { error: updateError } = await supabase
                  .from("coding_profiles")
                  .update({
                    codeforces_rating: currentRating,
                    codeforces_max_rating: maxRating,
                    updated_at: new Date().toISOString(),
                  })
                  .eq("id", profile.id);

                if (updateError) {
                  console.error(`Error updating Codeforces for ${handle}:`, updateError.message);
                } else {
                  cfUpdatedCount++;
                  console.log(`Updated Codeforces for ${handle}: rating=${currentRating}, maxRating=${maxRating}`);
                }
              }
            } else {
              console.warn(`Codeforces user ${handle} not found or request failed.`);
            }
          } catch (e) {
            console.error(`Error fetching Codeforces for ${handle}:`, e);
          }

          // Small delay to prevent hitting rate limits
          await new Promise((resolve) => setTimeout(resolve, 250));
        }
        console.log(`Individual Codeforces update completed. (${cfUpdatedCount} updated)`);
      }
    }

    // --- Update LeetCode ---
    const lcProfiles = profiles.filter((p) => p.leetcode_username && p.leetcode_username.trim() !== "");
    if (lcProfiles.length > 0) {
      console.log(`Updating ${lcProfiles.length} LeetCode profiles...`);
      for (const profile of lcProfiles) {
        const username = profile.leetcode_username.trim();
        try {
          const lcResponse = await fetch("https://leetcode.com/graphql", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "User-Agent": USER_AGENT,
            },
            body: JSON.stringify({
              query: `
                query getUserProfile($username: String!) {
                  matchedUser(username: $username) {
                    profile { ranking }
                    submitStats {
                      acSubmissionNum {
                        difficulty
                        count
                      }
                    }
                  }
                  userContestRanking(username: $username) {
                    rating
                  }
                }
              `,
              variables: { username },
            }),
          });

          if (lcResponse.ok) {
            const lcData = await lcResponse.json();
            if (lcData.data && lcData.data.matchedUser) {
              const matchedUser = lcData.data.matchedUser;
              const contestData = lcData.data.userContestRanking;

              const ranking = matchedUser.profile?.ranking ?? 0;

              let solved = 0;
              const submissions = matchedUser.submitStats?.acSubmissionNum || [];
              for (const sub of submissions) {
                if (sub.difficulty === "All") {
                  solved = sub.count || 0;
                  break;
                }
              }

              let rating = 0;
              if (contestData && contestData.rating) {
                rating = Math.round(contestData.rating);
              }

              const { error: updateError } = await supabase
                .from("coding_profiles")
                .update({
                  leetcode_ranking: ranking,
                  leetcode_solved: solved,
                  leetcode_rating: rating,
                  updated_at: new Date().toISOString(),
                })
                .eq("id", profile.id);

              if (updateError) {
                console.error(`Error updating LeetCode for ${username}:`, updateError.message);
              } else {
                lcUpdatedCount++;
                console.log(`Updated LeetCode for ${username}: solved=${solved}, rating=${rating}, ranking=${ranking}`);
              }
            }
          }
        } catch (e) {
          console.error(`Error fetching LeetCode for ${username}:`, e);
        }

        // Add a 500ms delay between LeetCode requests to avoid rate limits
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      console.log(`LeetCode update completed. (${lcUpdatedCount} updated)`);
    }

    return new Response(
      JSON.stringify({
        message: "Update completed successfully",
        codeforces_updated: cfUpdatedCount,
        leetcode_updated: lcUpdatedCount,
        total_processed: profiles.length,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error: any) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
