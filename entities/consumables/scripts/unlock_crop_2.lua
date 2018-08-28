
local UnlockCrop = class()

function UnlockCrop.use(consumable, consumable_data, player_id, target_entity)
  local farmer_job = stonehearth.job:get_job_info(player_id, "stonehearth:jobs:worker")
  farmer_job:manually_unlock_crop(consumable_data.crop)
  return true
end

return UnlockCrop