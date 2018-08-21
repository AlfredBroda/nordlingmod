local Point3 = _radiant.csg.Point3
local Region3 = _radiant.csg.Region3
local Point2 = _radiant.csg.Point2
local Rect2 = _radiant.csg.Rect2
local rng = _radiant.math.get_default_rng()

local MAX_LOCATION_FINDING_TRIES = 100

local DestroyBuildingScript = class()

local STATE = {
   INACTIVE = 'inactive',
   SPAWNING = 'spawning',
   IDLE = 'idle',
   ATTACKING = 'attacking',
   CHILLIN = 'chillin',
   DYING = 'dying',
}

function DestroyBuildingScript:initialize()
   self._sv.ctx = nil
   self._sv.building_to_destroy = nil
   self._sv.preventer = nil
   self._sv.state = STATE.INACTIVE
   self._sv._destroy_building_timer = nil
   
   self._preventer_death_listener = nil
   self._idle_effect = nil
end

function DestroyBuildingScript:activate()
   if self._sv.preventer then
      self:_start_state(self._sv.state)
   end
end

function DestroyBuildingScript:start(ctx, data)
   self._sv.ctx = ctx

   --early out if the player isn't connected. Realllly lame to destroy a disconnected player's stuff
   if not stonehearth.presence:is_player_connected(ctx.player_id) then
      return
   end

   local buildings = stonehearth.building:get_buildings()
   local building_ids = buildings:get_keys()
   local player_building_ids = {}

   -- TODO: Choose buildings intelligently. E.g. one of the N largest.
   for _, building_id in ipairs(building_ids) do
      local building = stonehearth.building:get_building(building_id)
      if building:get('stonehearth:build2:building'):completed() and building:get_player_id() == ctx.player_id then
         table.insert(player_building_ids, building_id)
      end
   end

   if #player_building_ids == 0 then
      -- Player has no buildings.
      return
   end
   
   local building_to_destroy_id = player_building_ids[rng:get_int(1, #player_building_ids)]
   self._sv.building_to_destroy = stonehearth.building:get_building(building_to_destroy_id)

   -- Spawn preventer.
   self._sv.preventer = radiant.entities.create_entity(data.preventer, { debug_text = 'building destruction preventer', owner = data.player_id })
   local building_bounds = self._sv.building_to_destroy:get('stonehearth:build2:building'):get_bounds():project_onto_xz_plane()
   -- TODO: Use the fairer algorithm from cubemitter::OriginShapeRectangularLamina or something even better like a random walk.
   local tries_remaining = MAX_LOCATION_FINDING_TRIES
   local found = false
   while not found and tries_remaining > 0 do
      local spawn_box
      local direction = rng:get_int(1, 4)
      if direction == 1 then
         spawn_box = Rect2(Point2(building_bounds.min.x, building_bounds.min.y - data.distance_around_building), Point2(building_bounds.max.x, building_bounds.min.y))
      elseif direction == 2 then
         spawn_box = Rect2(Point2(building_bounds.min.x, building_bounds.max.y), Point2(building_bounds.max.x, building_bounds.max.y + data.distance_around_building))
      elseif direction == 3 then
         spawn_box = Rect2(Point2(building_bounds.min.x - data.distance_around_building, building_bounds.min.y), Point2(building_bounds.min.x, building_bounds.max.y))
      elseif direction == 4 then
         spawn_box = Rect2(Point2(building_bounds.max.x, building_bounds.min.y), Point2(building_bounds.max.x + data.distance_around_building, building_bounds.max.y))
      end
      local x = rng:get_int(spawn_box.min.x, spawn_box.max.x)
      local y = rng:get_int(spawn_box.min.y, spawn_box.max.y)
      
      local location = radiant.terrain.find_placement_point(Point3(x, 0, y), 0, 3, self._sv.preventer)
      if location then
         radiant.terrain.place_entity_at_exact_location(self._sv.preventer, location)
         local facing_point_2d = building_bounds:get_closest_point(Point2(location.x,location.z))
         local facing_point = Point3( facing_point_2d.x, location.y, facing_point_2d.y)
         radiant.entities.turn_to_face(self._sv.preventer, facing_point)
         found = true
      end

      tries_remaining = tries_remaining - 1
   end
   
   if found then
      radiant.entities.add_buff(self._sv.preventer, "stonehearth:buffs:titan_building_destroyer_waiting")
      ctx[data.ctx_registration_variable] = self._sv.preventer
      self._sv._destroy_building_timer = stonehearth.calendar:set_persistent_timer('destroy building', data.delay, radiant.bind(self, '_start_attack_state'))
      self:_start_state(STATE.SPAWNING)
   else
      -- Couldn't find a place to spawn. Oh well.
      radiant.entities.destroy_entity(self._sv.preventer)
   end
end

function DestroyBuildingScript:_start_state(new_state)
   self._sv.state = new_state
   if self._sv.state == STATE.SPAWNING then
      radiant.effects.run_effect(self._sv.preventer, 'spawn'):set_finished_cb(function()
         self:_start_state(STATE.IDLE)
      end)
   elseif self._sv.state == STATE.IDLE then
      self._idle_effect = radiant.effects.run_effect(self._sv.preventer, 'charging')
      if not self._preventer_death_listener then
         self._preventer_death_listener = radiant.events.listen(self._sv.preventer, 'stonehearth:expendable_resource_changed:health', function()
               if radiant.entities.get_health(self._sv.preventer) <= 0 then
                  self:_start_state(STATE.DYING)
               end
            end)
      end
   elseif self._sv.state == STATE.ATTACKING then
      if self._idle_effect then
         self._idle_effect:stop()
      end
      if radiant.entities.exists(self._sv.preventer) and radiant.entities.exists_in_world(self._sv.preventer) then
         local effect = radiant.effects.run_effect(self._sv.preventer, 'smash', nil, function()
               if self._sv.state == STATE.ATTACKING then  -- in case it's killed while attacking
                  self:_destroy_building()
               end
            end)
         effect:set_finished_cb(function()
               self:_start_state(STATE.CHILLIN)
            end)
      end
   elseif self._sv.state == STATE.CHILLIN then
      self._idle_effect = radiant.effects.run_effect(self._sv.preventer, 'idle_slow')
      if not self._preventer_death_listener then
         self._preventer_death_listener = radiant.events.listen(self._sv.preventer, 'stonehearth:expendable_resource_changed:health', function()
               if radiant.entities.get_health(self._sv.preventer) <= 0 then
                  self:_start_state(STATE.DYING)
               end
            end)
      end
   elseif self._sv.state == STATE.DYING then
      if self._idle_effect then
         self._idle_effect:stop()
      end
      if self._preventer_death_listener then
         self._preventer_death_listener:destroy()
         self._preventer_death_listener = nil
      end
      radiant.effects.run_effect(self._sv.preventer, 'death'):set_finished_cb(function()
         if radiant.entities.exists(self._sv.preventer) then
            radiant.entities.destroy_entity(self._sv.preventer)
         end
         self:_start_state(STATE.INACTIVE)
      end)
   end
end

function DestroyBuildingScript:_start_attack_state()
   self:_start_state(STATE.ATTACKING)
end

function DestroyBuildingScript:_destroy_building()
   if radiant.entities.exists(self._sv.building_to_destroy) then
      local player_id = self._sv.building_to_destroy:get_player_id()
      stonehearth.bulletin_board:post_bulletin(player_id)
         :set_type('alert')
         :set_data({
            title = 'i18n(stonehearth:data.gm.campaigns.titan.alert_building_was_destroyed.title)',
            zoom_to_entity = self._sv.preventer
         })
         :set_active_duration("2h")

      stonehearth.building:blow_up_building(self._sv.building_to_destroy:get_id(), player_id)
   end
   if self._sv._destroy_building_timer then
      self._sv._destroy_building_timer:destroy()
      self._sv._destroy_building_timer = nil
   end
end

return DestroyBuildingScript
