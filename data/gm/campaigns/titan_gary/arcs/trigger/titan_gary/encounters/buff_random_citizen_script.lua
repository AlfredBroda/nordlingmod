local game_master_lib = require 'lib.game_master.game_master_lib'
local rng = _radiant.math.get_default_rng()

local BuffRandomCitizenScript = class()

function BuffRandomCitizenScript:start(ctx, data)
   local population = stonehearth.population:get_population(ctx.player_id)
   local citizens = {}
   for _, citizen in population:get_citizens():each() do
      if not data.excluded_role or not citizen:get_component('stonehearth:job'):get_roles()[data.excluded_role] then
         table.insert(citizens, citizen)
      end
   end
   if #citizens > 0 then
      local entity = citizens[rng:get_int(1, #citizens)]
      radiant.entities.add_buff(entity, data.buff)

      if data.ctx_entity_registration_path then
         ctx[data.ctx_entity_registration_path] = entity
      end
   end
end

return BuffRandomCitizenScript
