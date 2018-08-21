local PlayTitanEffectScript = class()

function PlayTitanEffectScript:start(ctx, data)
   local weather_state = stonehearth.weather._sv.current_weather_state
   if weather_state then
      assert(weather_state._sv.uri == 'stonehearth:weather:titanstorm', 'Titan effects only work during a Titanstorm.')
      weather_state._sv.script_controller:play_titan_effect(data.effect)
   end
end

return PlayTitanEffectScript
