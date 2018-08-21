local rng = _radiant.math.get_default_rng()

local DestroyCropsScript = class()

function DestroyCropsScript:start(ctx, data)
   -- Find all fields owned by this player. This is slow, but fine for tesing purposes.
   -- TODO: Do something more efficient here if we keep it.
   for _, entity in pairs(_radiant.sim.get_all_entities()) do
      if entity:get_component('stonehearth:crop') then
         if rng:get_real(0, 1) <= data.chance_per_crop then
            if data.ctx_entity_registration_path then
               -- Overwritten every time, so you will only zoom on the last one, but is probably fine.
               ctx[data.ctx_entity_registration_path] = entity:get_component('stonehearth:crop'):get_field()._entity
            end

            local proxy = radiant.entities.create_entity('stonehearth:object:transient', { debug_text = 'running death effect' })
            local location = radiant.entities.get_world_grid_location(entity)
            radiant.terrain.place_entity(proxy, location)
            radiant.effects.run_effect(proxy, data.effect):set_finished_cb(function()
                  radiant.entities.destroy_entity(proxy)
               end)
            radiant.entities.kill_entity(entity)
         end
      end
   end
end

return DestroyCropsScript
