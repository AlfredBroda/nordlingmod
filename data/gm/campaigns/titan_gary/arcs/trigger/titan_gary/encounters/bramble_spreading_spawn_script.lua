-- Spawns entities randomly within a given distance of all towns.
-- Arguments (required unless noted otherwise):
--   uri: The URI of the entities to spawn.
--   player_id: The player ID of the entities to spawn.
--   min_count: The minimum number of entities to spawn.
--   max_count: The maximum number of entities to spawn.
--   min_distance: The minimum X/Z distance from towns to spawn in.
--   max_distance: The maximum X/Z distance from towns to spawn in.
--   size: How large an empty area is required to spawn.
--   ctx_registration_variable: (optional) Register the spawned entities in the context at this variable.
--   depth: (optional) Spawn this many voxels under the ground, destroying surrounding terrain of the specified size.

local rng = _radiant.math.get_default_rng()
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3

local MAX_TRIES_TO_SPAWN_PER_INSTANCE = 2

local SpawnAroundEntityScript = class()

function SpawnAroundEntityScript:start(ctx, data)
   local root = ctx:get(data.ctx_root_entity)

   local band_min = data.min_distance
   local band_max = data.max_distance

   local try_min = band_min
   local try_max = band_max

   local growth_attempts_remaining = data.distance_growth_attempts or 1
   local band_widen_per_growth = data.band_widen_per_growth or 0

   if root then
      while growth_attempts_remaining > 0 do
         growth_attempts_remaining = growth_attempts_remaining - 1
         if self:_spawn_bramble(root, try_min, try_max, ctx, data) then
            break;
         else
            -- one less, for some overlap
            try_min = try_min + band_max - 1
            try_max = try_max + band_max + band_widen_per_growth - 1
         end
      end
   end

end

function SpawnAroundEntityScript:_spawn_bramble(center_entity, this_try_min, this_try_max, ctx, data)
   local center_location = radiant.entities.get_world_location(center_entity)
   --move the center up onto terrain in case we're underground
   center_location = radiant.terrain.get_point_on_terrain(center_location + Point3(0, 1, 0))
      
   local min_cube = Cube3(center_location):inflated(Point3(this_try_min, this_try_min, this_try_min))
   local max_cube = Cube3(center_location):inflated(Point3(this_try_max, this_try_max, this_try_max))
   
   
   local tries_remaining = MAX_TRIES_TO_SPAWN_PER_INSTANCE
   while tries_remaining > 0 do
      local x = rng:get_int(max_cube.min.x, max_cube.max.x)
      local y = center_location.y
      local z = rng:get_int(max_cube.min.z, max_cube.max.z)
      local test_point = Point3(x,y,z)
      if not min_cube:contains(test_point) then
         local location = radiant.terrain.get_point_on_terrain(test_point)
         local range = Point3(data.size, 0, data.size) / 2
         local range_cube = Cube3(location - range, location + range + Point3(0, data.size, 0))
         for _, entity in pairs(radiant.terrain.get_entities_in_cube(range_cube)) do
            if entity == radiant._root_entity then  -- terrain
               location = nil
               break
            else
               local collision = entity:get_component('region_collision_shape')
               if collision and collision:get_region_collision_type() == 1 then  -- solid
                  location = nil
                  break
               end
            end
         end

         if location then
            local entity = radiant.entities.create_entity(data.uri, { owner = data.player_id })
            local random_facing = rng:get_int(0,3)*90
            radiant.terrain.place_entity_at_exact_location(entity, location, { force_iconic = false, facing = random_facing })
            return true 
         end
      end
      tries_remaining = tries_remaining - 1
   end
   return false
end

return SpawnAroundEntityScript
