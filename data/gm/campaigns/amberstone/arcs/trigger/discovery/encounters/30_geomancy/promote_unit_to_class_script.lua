local PromoteUnitToClassScript = class()

function PromoteUnitToClassScript:start(ctx, data)
   local citizen = ctx:get(data.unit_reference)
   if citizen and data.job then
      citizen:get_component('stonehearth:job'):promote_to(data.job)
   end
end

return PromoteUnitToClassScript
