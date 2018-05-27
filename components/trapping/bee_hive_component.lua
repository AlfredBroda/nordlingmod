local BeeHiveComponent = require'stonehearth.components.trapping.bait_trap_component'

local log = radiant.log.create_logger('Mod')
log:always("Bee Test")

function BeeHiveComponent:can_trap(traget)
  local json = radiant.entities.get_json(self)
  local bee_hive = json.bee_hive or false

  local data = radiant.entities.get_entity_data(target, 'stonehearth:bait_trap')
  local can_trap = data and data.can_trap
  local can_hive = data.can_hive
  if not can_trap or (not can_hive and bee_hive) then
     return false
  end


  -- check for any other dynamic conditions here
  -- specifically, don't trap animals that are pets of the trapper's town
  local player_id = radiant.entities.get_player_id(target)
  return player_id == 'critters'

end

return BeeHiveComponent