-- In Factorio 2.0, marking something for deconstruction instantly pushes out all fluid (potentially deleting some if there wasn't enough space) and disconnects all pipes.
-- The on_marked_for_deconstruction is only fired AFTER that. This is VERY ANNOYING.
-- https://forums.factorio.com/viewtopic.php?t=126507

-- As a horrible bad terrible workaround, we constantly keep track of the contents of storage tanks and fluid segments in tank-contents-tracking.lua
-- Then we can use this info when something is marked for deconstruction.

-- But we must wait for all on_marked_for_deconstruction events of the same tick, for the common case of many storage tanks marked for deconstruction at once.
-- So on_marked_for_deconstruction only saves the deconstructed entity and info, and handle_deconstructions does the actual logic all at once.

---@class DeconstructedSegmentInfo
---@field deconstructed_entities { [uint]: LuaEntity }
---@field fluid_name string
---@field fluid_amount float
---@field capacity uint
---@field capacity_lost uint

---@type { [uint]: DeconstructedSegmentInfo }
local this_tick_deconstructed_segments = {}

local capacity_cache = {}
local function get_entity_capacity(entity)
  local capacity = capacity_cache[entity.name]
  if capacity == nil then
    capacity = entity.prototype.fluid_capacity
    capacity_cache[entity.name] = capacity
  end
  return capacity
end

local function on_marked_for_deconstruction(event)
  local entity = event.entity
  local previous_tick_info = storage.storage_tanks_by_unit_number[entity.unit_number]
  -- log("entity " .. entity.unit_number .. " marked for deletion - previous_tick_info: " .. serpent.line(previous_tick_info))
  if previous_tick_info == nil then
    return -- We missed this one somehow, we have nothing to go by
  end

  local minimum_fluid_threshold = settings.global["undeletable_fluids_minimum_threshold"].value

  for i = 1, entity.fluid_count do
    local previous_tick_fluidbox_info = previous_tick_info.fluidboxes[i]

    local fluid = previous_tick_fluidbox_info.fluid_segment_fluid

    if fluid ~= nil
       and is_undeletable(fluid.name)
       and fluid.amount > minimum_fluid_threshold
    then

      local fluid_segment_id = previous_tick_fluidbox_info.fluid_segment_id

      -- Save this deconstruction info for later processing
      This_tick_has_deconstructed_segments = true

      this_tick_deconstructed_segments[fluid_segment_id] = this_tick_deconstructed_segments[fluid_segment_id] or {
        deconstructed_entities = {},
        fluid_name = fluid.name,
        fluid_amount = fluid.amount,
        capacity = previous_tick_fluidbox_info.fluid_segment_capacity,
        capacity_lost = 0,
      }

      this_tick_deconstructed_segments[fluid_segment_id].deconstructed_entities[entity.unit_number] = entity
      this_tick_deconstructed_segments[fluid_segment_id].capacity_lost = this_tick_deconstructed_segments[fluid_segment_id].capacity_lost + get_entity_capacity(entity)
    end
  end
end
script.on_event(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction, Tanks_event_filter)

function handle_deconstructions()
  for segment_id, segment_info in pairs(this_tick_deconstructed_segments) do
    -- log("handling fluid segment " .. segment_id .. " deconstruction: " .. serpent.line(segment_info))

    -- Did this segment overflow?
    -- TODO: Fluid can also disappear without overflow if the game engine did not push the fluid out optimally. How to deal with this?

    -- local segment_free_space = (segment_info.capacity - segment_info.capacity_lost) - (segment_info.fluid_amount - segment_info.displaced_fluid_amount)
    -- local fluid_overflow = segment_info.displaced_fluid_amount - segment_free_space
    -- The above 2 lines can simplify to the line below:
    local fluid_overflow = segment_info.fluid_amount - (segment_info.capacity - segment_info.capacity_lost)
    if fluid_overflow > 0 then
      -- log("fluid segment " .. segment_id .. " overflowed by " .. fluid_overflow)

      -- 1) Iterate through every entity that was marked for deconstruction and cancel that
      local unit_number_deconstruction_cancelled = {}
      for unit_number, entity in pairs(segment_info.deconstructed_entities) do
        if not unit_number_deconstruction_cancelled[unit_number] then -- If we didn't do that one already (might happen if an entity belongs to 2 fluid segments)
          local force = entity.force
          unit_number_deconstruction_cancelled[unit_number] = true
          entity.cancel_deconstruction(force)
          if entity.last_user then -- Last user is always the player who deconstructed
            create_error_message(entity.last_user, {"undeletable-fluids.mining_prevented"}, segment_info.fluid_name, entity.position)
          elseif force then
            create_error_message_for_force(force, {"undeletable-fluids.mining_prevented"}, segment_info.fluid_name, entity.position)
          end
        end
      end

      -- 2) Iterate through all entities again and see how many fluid segments they are now part of

      -- In most cases this will be only 1 segment,
      -- but sometimes the deconstruction and re/construction could have split this segment into multiples
      -- e.g. full tank - pipe - full tank

      local reconstructed_segments_fluid_amount = {}
      for _unit_number, entity in pairs(segment_info.deconstructed_entities) do
         -- TODO: Handle entities with multiple segments
        local reconstructed_segment_id = entity.fluidbox.get_fluid_segment_id(1) --[[@as uint]]
        if not reconstructed_segments_fluid_amount[reconstructed_segment_id] then
          reconstructed_segments_fluid_amount[reconstructed_segment_id] = entity
        end
      end

      -- 3) Finally we can set back the fluid amount of each segment

      local fluid_per_segment = segment_info.fluid_amount / table_size(reconstructed_segments_fluid_amount)
      for _segment_id, access_entity in pairs(reconstructed_segments_fluid_amount) do
        -- TODO can we track temperature and set it here
        access_entity.set_fluid(1, {
          name = segment_info.fluid_name,
          amount = fluid_per_segment,
        })
      end
    end
  end
  this_tick_deconstructed_segments = {}
  This_tick_has_deconstructed_segments = false
end
