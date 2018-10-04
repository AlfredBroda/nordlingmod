local log = radiant.log.create_logger('kaimonkey')

local JobComponent = require 'stonehearth.components.job.job_component'
if JobComponent then
  local old_level_up = JobComponent.level_up
  function JobComponent:level_up(skip_visual_effects)
    if self._sv.job_uri == "stonehearth:jobs:worker" and self._sv.curr_job_level == 0 then
      old_level_up(self, true)
    else
      old_level_up(self, skip_visual_effects)
    end
  end

  local old_promote = JobComponent.promote_to
  function JobComponent:promote_to(job_uri, options)
    if not options then
      options = {}
    end
    if job_uri == "stonehearth:jobs:worker" and not self:_call_job('get_job_level') then
      options.skip_visual_effects = true
    end
    old_promote(self, job_uri, options)
  end

else
  log:error("Couldn't Load Job Component")
end

local JobService = require 'stonehearth.services.server.job.job_service'
local old_get_job_info = JobService.get_job_info
function JobService:get_job_info(player_id, job_id)
    local kingdom = stonehearth.player:get_kingdom(player_id)
    if kingdom == "nordlingmod:kingdoms:nordlings" and job_id == "stonehearth:jobs:farmer" then
     return old_get_job_info(self, player_id, "stonehearth:jobs:worker")
   else
     return old_get_job_info(self, player_id, job_id)
  end
end
  log:error("Monkey Patched Job Service")
--e:get_component("stonehearth:job"):level_up()
