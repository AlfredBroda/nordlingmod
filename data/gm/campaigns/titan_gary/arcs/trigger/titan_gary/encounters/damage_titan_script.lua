local DamageTitanScript = class()

function DamageTitanScript:start(ctx, data)
   local weather_state = stonehearth.weather._sv.current_weather_state
   if weather_state then
      if weather_state._sv.uri == 'stonehearth:weather:titanstorm' then  -- Can trigger from minions dying after the titan is defeated.
         weather_state._sv.script_controller:apply_damage_to_titan(data.damage_amount, data.animation_name)
      end
   end
end

return DamageTitanScript
