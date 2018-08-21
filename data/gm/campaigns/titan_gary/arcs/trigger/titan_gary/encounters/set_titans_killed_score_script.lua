local SetTitansKilledScoreScript = class()

function SetTitansKilledScoreScript:start(ctx, data)
   local town = stonehearth.town:get_town(ctx.player_id)
   local score_entity = town:get_banner()  -- There's gotta be a better entity!
   stonehearth.score:change_score(score_entity, 'titans_killed', 'titan killed', 1)
   radiant.events.trigger_async(stonehearth.game_master:get_game_master(ctx.player_id), 'stonehearth:titan_killed', { player_id = ctx.player_id })
end

return SetTitansKilledScoreScript
