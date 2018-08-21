local PromoteUnitToClassScript = class()

function PromoteUnitToClassScript:start(ctx, data)
	
	print("=================================")
	print(data.unit_reference)
    local citizen = ctx:get(data.unit_reference)
    print( citizen)
    print( data.job)
    if citizen and data.job then
   		citizen:get_component('stonehearth:job'):promote_to(data.job)
   	end
end

return PromoteUnitToClassScript
