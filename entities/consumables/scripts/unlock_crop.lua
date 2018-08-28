
local UnlockCrop = class()

function UnlockCrop.use(consumable, consumable_data, player_id, target_entity)
    local kingdom = stonehearth.player:get_kingdom(player_id)
    if kingdom == "nordlings:kingdom:nordlings" then
        local worker_job = stonehearth.job:get_job_info(player_id, "stonehearth:jobs:worker")
        if worker_job then  
            worker_job:manually_unlock_crop(consumable_data.crop)
        end
    else
        local farmer_job = stonehearth.job:get_job_info(player_id, "stonehearth:jobs:farmer")
        if farmer_job then  
            farmer_job:manually_unlock_crop(consumable_data.crop)
        end
    end
    return true
end

return UnlockCrop