import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } },
  );

  const { sessionId, zoneId } = await req.json();
  if (!sessionId || !zoneId) {
    return new Response(JSON.stringify({ error: "sessionId and zoneId required" }), { status: 400 });
  }

  const { data: session } = await supabase.from("sessions").select("*").eq("id", sessionId).single();
  if (!session) {
    return new Response(JSON.stringify({ error: "session not found" }), { status: 404 });
  }

  const { data: zone } = await supabase.from("zones").select("*").eq("id", zoneId).single();
  if (!zone) {
    return new Response(JSON.stringify({ error: "zone not found" }), { status: 404 });
  }

  const { data: hit } = await supabase.rpc("route_intersects_zone", {
    route_geojson: session.route_geojson,
    zone_id: zoneId,
  });
  if (!hit) {
    return new Response(
      JSON.stringify({ claimStatus: "rejected_no_intersection", guardianUserId: zone.current_guardian_user_id, auraAwarded: 0 }),
      { headers: { "Content-Type": "application/json" } },
    );
  }

  const auraAwarded = Math.round(100 * (zone.score_multiplier ?? 1));

  await supabase.from("zones").update({ current_guardian_user_id: session.user_id }).eq("id", zoneId);
  await supabase.from("zone_claim_events").insert({
    zone_id: zoneId,
    user_id: session.user_id,
    session_id: sessionId,
    aura_awarded: auraAwarded,
  });
  await supabase.rpc("increment_user_aura", { user_id: session.user_id, delta: auraAwarded });

  return new Response(
    JSON.stringify({ claimStatus: "claimed", guardianUserId: session.user_id, auraAwarded }),
    { headers: { "Content-Type": "application/json" } },
  );
});
