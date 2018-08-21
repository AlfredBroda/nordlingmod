-- Replaces an entity owned by the player (the first one found) with another one. If not found, just grants them the new entity as an iconic.
-- Arguments:
--   old_uri: The URI of the entity to replace.
--   new_uri: The URI of the entity to create.
--   effect: The effect to play during the transformation.

local CleanseOrcGongScript = class()

function CleanseOrcGongScript:initialize()
   self._sv.ctx = nil
   self._sv.old_entity = nil
   self._sv.data = nil
end

function CleanseOrcGongScript:activate()
   if self._sv.old_entity then
      self:_swap()
   end
end

function CleanseOrcGongScript:start(ctx, data)
   self._sv.ctx = ctx
   self._sv.data = data
   self._sv.old_entity = self:_find_old_entity()

   self:_swap()
end

function CleanseOrcGongScript:_find_old_entity()
   local best_match
   local inventory = stonehearth.inventory:get_inventory(self._sv.ctx.player_id)
   local matching = inventory and inventory:get_items_of_type(self._sv.data.old_uri)
   if matching and matching.items then
      for _, entity in pairs(matching.items) do
         if radiant.entities.exists_in_world(entity) then
            return entity
         elseif not best_match then
            best_match = entity
         end
      end
   end
   return best_match
end

function CleanseOrcGongScript:_swap()
   if self._sv.old_entity and radiant.entities.exists_in_world(self._sv.old_entity) then
      -- Deployed. Replace exactly.
      local do_the_swap = function()
         if not self._sv.old_entity then
            return
         end

         local new_entity = radiant.entities.create_entity(self._sv.data.new_uri, { owner = self._sv.ctx.player_id })
         stonehearth.inventory:get_inventory(self._sv.ctx.player_id):add_item(new_entity)

         local location = radiant.entities.get_world_grid_location(self._sv.old_entity)
         local facing = radiant.entities.get_facing(self._sv.old_entity)

         radiant.terrain.remove_entity(self._sv.old_entity)
         radiant.entities.destroy_entity(self._sv.old_entity)
         radiant.terrain.place_entity_at_exact_location(new_entity, location, { facing = facing, force_iconic = false })

         self._sv.old_entity = nil
      end

      if self._sv.data.effect then
         local proxy = radiant.entities.create_entity('stonehearth:object:transient', { debug_text = 'replace item effect anchor' })
         local location = radiant.entities.get_world_grid_location(self._sv.old_entity)
         radiant.terrain.place_entity_at_exact_location(proxy, location)
         radiant.effects.run_effect(proxy, self._sv.data.effect, nil, do_the_swap):set_finished_cb(do_the_swap)
      else
         do_the_swap()
      end
   else
      if self._sv.old_entity then
         radiant.entities.destroy_entity(self._sv.old_entity)
         self._sv.old_entity = nil
      end

      local new_entity = radiant.entities.create_entity(self._sv.data.new_uri, { owner = self._sv.ctx.player_id })
      stonehearth.inventory:get_inventory(self._sv.ctx.player_id):add_item(new_entity)

      local town = stonehearth.town:get_town(self._sv.ctx.player_id)
      local location = town:get_landing_location()
      radiant.terrain.place_entity_at_exact_location(new_entity, location, { force_iconic = true })
   end
end

return CleanseOrcGongScript
