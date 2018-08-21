local rng = _radiant.math.get_default_rng()

local DestroyUnitsOfFactionScript = class()

function DestroyUnitsOfFactionScript:start(ctx, data)
   -- Find all units owned by the specified player ID. This is slow, but fine for a single-use encounter.
   for _, entity in pairs(_radiant.sim.get_all_entities()) do
      if entity:get_player_id() == data.player_id then
         radiant.entities.destroy_entity(entity)
      end
   end
end

return DestroyUnitsOfFactionScript
