local CountSpawnedBugsScript = class()

function CountSpawnedBugsScript:start(ctx, data)
   
   if data.entity_list then
   		local list = ctx:get(data.entity_list)
   		local count = #list
   		if data.counter_name then
   			local old_counter = ctx.campaign:get_counter_value(data.counter_name)
   			ctx.campaign:set_counter_value(data.counter_name, old_counter + count)
   		end
   	end
end

return CountSpawnedBugsScript
