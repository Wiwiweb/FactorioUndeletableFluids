local function prevent_removal(event)
  -- We can't just clone the entity and then let Factorio continue with the removal,
  -- because that will prevent existing pipes from connecting to the new entity (they are still connected to the old).
  -- We have to actively destroy it here.
  local surface = event.entity.surface
  local new_entity_params = {
    name = event.entity.name,
    position = event.entity.position,
    direction = event.entity.direction,
    force = event.entity.force,
    create_build_effect_smoke = false,
    spawn_decorations = false,
    raise_built = true,
  }

  local saved_fluid_segments_fluids = {}
  local fluidboxes = event.entity.fluidbox
  for i = 1, #fluidboxes do
    saved_fluid_segments_fluids[i] = event.entity.get_fluid(i)
  end

  event.buffer.clear() -- Remove the resulting item from mining.
  event.entity.destroy() -- Destroy the old entity *before* creating the new one to ensure pipe connections.
  local new_entity = surface.create_entity(new_entity_params)

  -- Restore fluids
  local new_fluidboxes = new_entity.fluidbox
  for i = 1, #new_fluidboxes do
    new_fluidboxes[i] = saved_fluid_segments_fluids[i]
  end

  -- Can't undo the +1 deconstruction on time graphs but let's at least undo them in the All graph
  local construction_stats = new_entity.force.get_entity_build_count_statistics(surface)
  construction_stats.set_output_count(new_entity.name, construction_stats.get_output_count(new_entity.name) - 1)

  local player
  local force
  if event.player_index then
    -- Removed by player
    player = game.get_player(event.player_index)
  elseif event.robot then
    -- As far as I know this can't happen in 2.0
    -- Because marking a tank for deconstruction disconnects it from fluid networks
    -- But just in case...
    if event.robot.logistic_network and event.robot.logistic_network.cells[1] and event.robot.logistic_network.cells[1].owner.type == "character" then
      -- Removed by personal bot
      player = event.robot.logistic_network.cells[1].owner.player
    else
      -- Removed by bot
      force = event.robot.force
    end
  end

  local fluid_name = new_fluidboxes[1].name -- Good enough
  if player then
    create_error_message(player, {"undeletable-fluids.mining_prevented"}, fluid_name, new_entity_params.position)
  elseif force then
    create_error_message_for_force(force, {"undeletable-fluids.mining_prevented"}, fluid_name, new_entity_params.position)
  end
end

-- Checks if removing this entity would cause fluid deletion
local function would_fluid_be_deleted(entity)
  local entity_capacity = entity.prototype.fluid_capacity
  local fluidboxes = entity.fluidbox
  for i = 1, #fluidboxes do
    local fluid_segment_contents = entity.get_fluid(i)
    local fluid_segment_capacity = fluidboxes.get_capacity(i)
    if fluid_segment_capacity - entity_capacity < fluid_segment_contents.amount then
      return true
    end
  end
  return false
end

local function on_player_removed_entity(event)
  -- At this point in 2.0, Factorio has yet to transfer fluids
  if event.entity and event.entity.valid then
    storage.storage_tanks_by_unit_number[event.entity.unit_number] = nil
    local fluid_contents = event.entity.get_fluid_contents()
    -- Technically there are some uncaught edge cases with tanks that have >1 fluidboxes, 
    -- e.g. a tank that has a large amount of a deletable fluid, and an unsignificant amount of an undeletable fluid, would be wrongly prevented from deletion,
    -- but I'm not aware of any mod using >1 fluidboxes for a tank, so good enough.
    if table_size(fluid_contents) > 0
      and is_any_undeletable(fluid_contents)
      and is_significant_fluid_amount(fluid_contents)
      and would_fluid_be_deleted(event.entity)
    then
      local action = settings.global["undeletable_fluids_removal_action"].value
      if action == "prevent" then
        prevent_removal(event)
      elseif action == "explosion" then
        explosion(event)
      elseif action == "atomic_explosion" then
        atomic_explosion(event)
      end
    end
  end
end
script.on_event(defines.events.on_player_mined_entity, on_player_removed_entity, Tanks_and_pipes_event_filter)
-- Don't catch on_robot_mined_entity because robots can't mine storage tanks that are not marked for deconstruction anyway
