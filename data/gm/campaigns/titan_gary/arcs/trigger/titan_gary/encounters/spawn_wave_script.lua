local SpawnWaveScript = class()

function SpawnWaveScript:start(ctx, data)
   local weather_state = stonehearth.weather._sv.current_weather_state
   if weather_state then
      assert(weather_state._sv.uri == 'stonehearth:weather:titanstorm', 'Titan waves only work during a Titanstorm.')
      weather_state._sv.script_controller:spawn_titan_wave()
   end
end

return SpawnWaveScript
