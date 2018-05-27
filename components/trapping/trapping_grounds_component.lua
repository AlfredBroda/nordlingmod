local rng = _radiant.math.get_default_rng()
local WeightedSet = require 'stonehearth.lib.algorithms.weighted_set'

local TrappingGroundsComponent = require 'stonehearth.components.trapping.trapping_grounds_component'

local log = radiant.log.create_logger('Mod')
log:always("Bee Test")

function TrappingGroundsComponent:_create_set_trap_task()
  local trap_uri = self:_choose_trap_type()
  
  log:always("trap_uri: %s", trap_uri)
  local town = stonehearth.town:get_town(self._entity)

  if self._set_trap_task or self._sv.num_traps >= self.max_traps or not town then
     return
  end

  local location = self:_pick_next_trap_location()
  if not location then
     return
  end

  self._set_trap_task = town:create_task_for_group('stonehearth:task_groups:trapping',
                                                   'stonehearth:trapping:set_bait_trap',
                                                   {
                                                      location = location,
                                                      trap_uri = trap_uri,
                                                      trapping_grounds = self._entity
                                                   })
     :set_source(self._entity)
     :once()
     :notify_completed(
        function ()
           self._set_trap_task = nil
           self:_create_set_trap_task() -- keep setting traps serially until done
        end
     )
     :start()
end

function TrappingGroundsComponent:load_tuning(json)
  local spawn_json = json.terrain_spawn_intervals[self._sv.terrain_kind]
  if not spawn_json then
     spawn_json = json.terrain_spawn_intervals.default
  end
  self.trap_weights = json.trap_weights
  for trap, weight in pairs(self.trap_weights) do
    log:always("trap: %s, weights: %s", trap, weight)
  end

  self.max_traps = json.max_traps or 4
  self.min_distance_between_traps = json.min_distance_between_traps or 16

  self.spawn_interval_min = stonehearth.calendar:parse_duration(spawn_json.spawn_interval_min)
  self.spawn_interval_max = stonehearth.calendar:parse_duration(spawn_json.spawn_interval_max)
  self.check_traps_interval = stonehearth.calendar:parse_duration(json.check_traps_interval)

  self.trappable_animal_weights = json.trappable_animal_weights
  self.base_trap_chance = json.base_trap_chance -- do we want to use this someday? currently unused
end

function TrappingGroundsComponent:_choose_trap_type()
  local weighted_set = WeightedSet(rng)

  for uri, weight in pairs(self.trap_weights) do
    weighted_set:add(uri,weight)
    log:always("trap weights: %s", weight)
  end

  local uri = weighted_set:choose_random()
  return uri
end


function TrappingGroundsComponent:_try_spawn()
  -- must be within the interaction sensor range of the trap
  local max_spawn_distance = 15
  -- won't spawn if threat within this distance of trap or spawn location
  -- TODO: refactor this distance with the avoid_threatening_entities_observer
  local threat_distance = 16

  local trap = self:_choose_random_trap_for_critter()

  -- don't retry if there are threats detected. you lose this spawn, do not pass go
  -- place trapping grounds away from trafficed areas if you want to catch things
  if trap and self:_location_is_clear_of_threats(trap, threat_distance) then
    local critter_uri = nil
     if trap:get_uri() ~= "nordlingmod:bee_hive" then
      critter_uri = self:_choose_spawned_critter_type()
     else
      critter_uri = "nordlingmod:critters:bee"
     end
     local critter = self:_create_critter(critter_uri)

     local spawn_location = self:_get_spawn_location(trap, max_spawn_distance, critter)

     if spawn_location and self:_location_is_clear_of_threats(spawn_location, threat_distance) then
        radiant.terrain.place_entity(critter, spawn_location)
        self:_create_try_bait_task(critter, trap)
        -- BUG: saving the game before untrapped critters despawn leaves them in the world
     else
        radiant.entities.destroy_entity(critter)
     end
  end

  local duration = self:_get_spawn_duration()
  self:_start_spawn_timer(duration)
end


return TrappingGroundsComponent