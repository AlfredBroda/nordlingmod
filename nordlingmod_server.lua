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

--e:get_component("stonehearth:job"):level_up()
