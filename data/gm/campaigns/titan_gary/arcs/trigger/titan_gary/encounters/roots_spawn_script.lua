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
local Region3 = _radiant.csg.Region3

local MAX_TRIES_TO_SPAWN_PER_INSTANCE = 5

local ScatterSpawnScript = class()

function ScatterSpawnScript:start(ctx, data)
   
   if data.ctx_root_list_variable then
      ctx[data.ctx_root_list_variable] = {}
   end

   local territory = stonehearth.terrain:get_total_territory():get_region()
   local min_region = territory:inflated(_radiant.csg.Point2(data.min_distance, data.min_distance))
   local max_region_bounds = territory:inflated(_radiant.csg.Point2(data.max_distance, data.max_distance)):get_bounds()
   local num_to_spawn = rng:get_int(data.min_count, data.max_count)
   local tries_remaining = MAX_TRIES_TO_SPAWN_PER_INSTANCE * num_to_spawn
   while tries_remaining > 0 and num_to_spawn > 0 do
      local x = rng:get_int(max_region_bounds.min.x, max_region_bounds.max.x)
      local y = rng:get_int(max_region_bounds.min.y, max_region_bounds.max.y)
      if not min_region:contains(Point2(x, y)) then
         local location = radiant.terrain.get_point_on_terrain(Point3(x, 0, y)) + Point3(0, 1, 0)
         local range_radius = math.ceil((data.size-1)/2)
         local range = Point3(range_radius, 0, range_radius)
         
         local range_cube = Cube3(location - range, location + range + Point3(0, data.size, 0))
         for _, entity in pairs(radiant.terrain.get_entities_in_cube(range_cube)) do
            if entity:get_component('stonehearth:water') then  -- Don't spawn underwater.
               location = nil
               break
            end
            if not data.depth then
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
         end

         if location then
            if data.depth then
               location.y = math.max(location.y - data.depth, stonehearth.terrain:get_bounds().min.y + 1)
               local range_cube = Cube3(location - range, location + range + Point3(1, data.size, 1)) --why the 1's in the last Point3? Because subtractregion doesn't seem to take high-end bounds into account correctly and always shorts me one x and one z...
            
               radiant.terrain.subtract_region(Region3(range_cube))
            
               --update x-ray mode - disabled for now b/c it's buggy
               --local interior_tiles = radiant.terrain.get_terrain_component():get_interior_tiles()
               --interior_tiles:add_cube(range_cube)
               --interior_tiles:optimize_changed_tiles('optimizing root spawn interior tiles')
               --interior_tiles:clear_changed_set()
            end

            if location then
               local entity = radiant.entities.create_entity(data.uri, { owner = data.player_id })
               radiant.terrain.place_entity_at_exact_location(entity, location)
               table.insert(ctx[data.ctx_root_list_variable], entity)
               num_to_spawn = num_to_spawn - 1
            end
         end
      end
      tries_remaining = tries_remaining - 1
   end
end

return ScatterSpawnScript
