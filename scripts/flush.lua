-- This is slow because the map isn't keyed by fluid segment id
-- But attempted flushing should be rare so it's ok
local function get_temperature_from_tank_tracking(entity)
  local this_fluid_segment_id = entity.fluidbox.get_fluid_segment_id(1)
  if this_fluid_segment_id then
    for _unit_number, tank_info in pairs(storage.storage_tanks_by_unit_number) do
      for _, fluidboxes in pairs(tank_info.fluidboxes) do
        if fluidboxes.fluid_segment_id == this_fluid_segment_id then
          return fluidboxes.fluid_segment_fluid.temperature
        end
      end
    end
  end
  return nil
end

local function prevent_flushing(event)
  if event.amount < settings.global["undeletable_fluids_minimum_threshold"].value then
    return -- Don't prevent anything for fluid amounts below threshold.
  end

  -- Unfortunately the event doesn't return temperature (https://forums.factorio.com/viewtopic.php?f=28&t=109233)
  -- Try and get temperature from the tank tracking system
  -- (better than nothing)
  local temperature = get_temperature_from_tank_tracking(event.entity)

  -- I love fluids 2.0
  event.entity.insert_fluid(
    {
      name = event.fluid,
      amount = event.amount,
      temperature = temperature
    }
  )

  local player = game.get_player(event.player_index)
  if temperature then
    create_error_message(player, {"undeletable-fluids.flush_prevented"}, event.fluid)
  else
    create_error_message(player, {"undeletable-fluids.flush_prevented_temperature_reset"}, event.fluid)
  end
end


local function on_player_flushed_fluid(event)
  if is_undeletable(event.fluid) then
    local action = settings.global["undeletable_fluids_flush_action"].value
    if action == "prevent" then
      prevent_flushing(event)
    elseif action == "explosion" then
      explosion(event)
    elseif action == "atomic_explosion" then
      atomic_explosion(event)
    end
  end
end
script.on_event(defines.events.on_player_flushed_fluid, on_player_flushed_fluid)
