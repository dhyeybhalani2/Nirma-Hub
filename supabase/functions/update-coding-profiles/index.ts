import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "@supabase/supabase-js";

// Initialize Supabase client
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

serve(async (req) => {
  // We only accept POST requests to run this task
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
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
        headers: { "Content-Type": "application/json" },
        status: 200,
      });
    }

    console.log(`Found ${profiles.length} profiles to update.`);

    // --- Update Codeforces ---
    const cfProfiles = profiles.filter((p) => p.codeforces_username);
    if (cfProfiles.length > 0) {
      console.log(`Updating ${cfProfiles.length} Codeforces profiles...`);
      // Codeforces allows fetching multiple users at once by separating handles with a semicolon
      const handles = cfProfiles.map((p) => p.codeforces_username).join(";");
      const cfResponse = await fetch(`https://codeforces.com/api/user.info?handles=${handles}`);
      
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
                  codeforces_current_rating: currentRating,
                  codeforces_max_rating: maxRating,
                  updated_at: new Date().toISOString(),
                })
                .eq("id", profile.id);

              if (updateError) {
                console.error(`Error updating Codeforces for ${handle}:`, updateError.message);
              }
            }
          }
          console.log("Codeforces update complete.");
        }
      } else {
        console.error("Codeforces API failed:", await cfResponse.text());
      }
    }

    // --- Update LeetCode ---
    const lcProfiles = profiles.filter((p) => p.leetcode_username);
    if (lcProfiles.length > 0) {
      console.log(`Updating ${lcProfiles.length} LeetCode profiles...`);
      // LeetCode doesn't support batch fetching easily, so we process sequentially 
      // (or in small batches) to avoid rate limits.
      for (const profile of lcProfiles) {
        const username = profile.leetcode_username;
        try {
          const lcResponse = await fetch("https://leetcode.com/graphql", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              // Required User-Agent to prevent 403 Forbidden
              "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
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
              }
            }
          }
        } catch (e) {
          console.error(`Error fetching LeetCode for ${username}:`, e);
        }

        // Add a 500ms delay between Leetcode requests to avoid rate limits
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      console.log("LeetCode update complete.");
    }

    return new Response(JSON.stringify({ message: "Update completed successfully" }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error: any) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
