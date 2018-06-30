local ResourceNodeComponent = class()
local LootTable = require 'lib.loot_table.loot_table'
local HARVEST_ACTION = 'stonehearth:harvest_resource'

function ResourceNodeComponent:initialize()
   local json = radiant.entities.get_json(self)
   self._json = json

   -- Save variables
   self._sv.durability = json.durability or 1

   self._description = json.description -- This appears to need to exist because it can be accessed after the entity is destroyed?

   -- not passing in anything so we default to json tuning
   self:set_harvestable_by_harvest_tool()
end

function ResourceNodeComponent:is_harvestable_by_harvest_tool()
   return self._harvestable_by_harvest_tool
end

function ResourceNodeComponent:set_harvestable_by_harvest_tool(harvestable_by_harvest_tool)
   if harvestable_by_harvest_tool == nil then
      self._harvestable_by_harvest_tool = true
      local json = radiant.entities.get_json(self)
      if json.harvestable_by_harvest_tool ~= nil then
         self._harvestable_by_harvest_tool = json.harvestable_by_harvest_tool
      end
   else
      self._harvestable_by_harvest_tool = harvestable_by_harvest_tool
   end
end

function ResourceNodeComponent:is_harvestable()
   return self._sv.durability > 0
end

function ResourceNodeComponent:get_harvester_effect()
   local json = radiant.entities.get_json(self)
   return json.harvester_effect or 'fiddle'
end

function ResourceNodeComponent:get_description()
   return self._description
end

function ResourceNodeComponent:get_harvested_item_uri()
   local json = radiant.entities.get_json(self)
   if json then
      return json.resource
   else
      return nil
   end
end

function ResourceNodeComponent:get_harvester_thought()
   local json = radiant.entities.get_json(self)
   if json then
      return json.harvester_thought
   else
      return nil
   end
end

function ResourceNodeComponent:_place_spawned_items(owner, collect_location)
   local json = radiant.entities.get_json(self)
   if not json then
      return {}
   end
   local resource = json.resource
   local loot_table = nil
   if json.resource_loot_table then
      loot_table = LootTable(json.resource_loot_table)
   end
   local spawned_items
   if loot_table then
      spawned_items = radiant.entities.spawn_items(loot_table:roll_loot(), collect_location, 1, 3, { owner = owner })
   else
      spawned_items = {}
   end

   if resource then
      local item = radiant.entities.create_entity(resource, { owner = owner })

      local pt = radiant.terrain.find_placement_point(collect_location, 0, 4)
      radiant.terrain.place_entity(item, pt)
      spawned_items[item:get_id()] = item
   end

   return spawned_items
end

-- If the resource is nil, the object will still eventually disappear
function ResourceNodeComponent:spawn_resource(harvester_entity, collect_location, owner_player_id)
   local spawned_resources = self:_place_spawned_items(harvester_entity, collect_location)
   local player_id = owner_player_id or (harvester_entity and radiant.entities.get_player_id(harvester_entity))
   if harvester_entity then
      for id, item in pairs(spawned_resources) do
         -- add it to the inventory of the owner
         stonehearth.inventory:get_inventory(player_id)
                                 :add_item_if_not_full(item)

         --trigger an event on the entity that they've harvested something, and what they're harvesting
         --Note this cannot be async because the entity can be killed
         radiant.events.trigger(harvester_entity, 'stonehearth:gather_resource',
            {harvested_target = self._entity, spawned_item = item})
      end
   end

   -- If we have the vitality town bonus, there's a chance we don't consume durability.
   local durability_to_consume = 1
   local town = harvester_entity and stonehearth.town:get_town(radiant.entities.get_player_id(harvester_entity))
   if town then
      local vitality_bonus = town:get_town_bonus('stonehearth:town_bonus:vitality')
      if vitality_bonus then
         local catalog_data = stonehearth.catalog:get_catalog_data(self._entity:get_uri())
         if catalog_data and catalog_data.category == 'plants' then  -- Not log piles.
            local is_wood_resource = false
            for _, item in pairs(spawned_resources) do
               if radiant.entities.is_material(item, 'wood resource') then
                  is_wood_resource = true
                  break
               end
            end
            if is_wood_resource then
               durability_to_consume = vitality_bonus:apply_consumed_wood_durability_bonus(durability_to_consume)
            end
         end
      end
   end

   self._sv.durability = self._sv.durability - durability_to_consume

   if self._sv.durability <= 0 then
      radiant.entities.kill_entity(self._entity)
   end

   self.__saved_variables:mark_changed()
end

-- Add the resource to the list of harvestables for the specified player id
function ResourceNodeComponent:request_harvest(player_id)
   if not self:is_harvestable() then
      return false
   end

   local json = self._json

   if json.check_owner and radiant.entities.is_owned_by_another_player(self._entity, player_id) then
      return false
   end

   local task_tracker_component = self._entity:add_component('stonehearth:task_tracker')
   if task_tracker_component:is_activity_requested(HARVEST_ACTION) then
      return false -- If someone has requested to harvest already
   end

   task_tracker_component:cancel_current_task(false) -- cancel current task first and force the resource node harvest

   local category = json.category or 'harvest'
   local success = task_tracker_component:request_task(player_id, category, HARVEST_ACTION, json.harvest_overlay_effect)
   return success
end

return ResourceNodeComponent
