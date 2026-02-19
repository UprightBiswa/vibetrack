import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } },
  );

  const { sessionId } = await req.json();
  if (!sessionId) {
    return new Response(JSON.stringify({ error: "sessionId required" }), { status: 400 });
  }

  const { data: session } = await supabase.from("sessions").select("*").eq("id", sessionId).single();
  if (!session) {
    return new Response(JSON.stringify({ error: "session not found" }), { status: 404 });
  }

  const auraAwarded = Math.max(
    0,
    Math.round((session.distance_m / 100) + (session.duration_s / 60) + ((session.distance_m / Math.max(session.duration_s, 1)) * 6)),
  );

  const { data: profile } = await supabase.from("profiles").select("aura_points").eq("id", session.user_id).single();
  const totalAura = (profile?.aura_points ?? 0) + auraAwarded;
  await supabase.from("profiles").update({ aura_points: totalAura }).eq("id", session.user_id);

  return new Response(JSON.stringify({ auraAwarded, totalAura }), {
    headers: { "Content-Type": "application/json" },
  });
});
