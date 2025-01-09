local function prevent_removal(event)
  -- We can't just clone the entity and then let Factorio continue with the removal,
  -- because that will prevent existing pipes from connecting to the new entity (they are still connected to the old).
  -- We have to actively destroy it here.
  local surface = event.entity.surface
  local saved_surrounding_fluids = storage.saved_surrounding_fluids_by_unit_number[event.entity.unit_number]
  local fluid_name = event.entity.fluidbox[1].name
  local new_entity_params = {
    name = event.entity.name,
    position = event.entity.position,
    direction = event.entity.direction,
    force = event.entity.force,
    create_build_effect_smoke = false,
    spawn_decorations = false,
  }

  event.buffer.clear() -- Remove the resulting item from mining.
  event.entity.destroy() -- Destroy the old entity *before* creating the new one to ensure pipe connections.
  local new_entity = surface.create_entity(new_entity_params)

  -- Restore fluids as they were during pre-mining
  if saved_surrounding_fluids then
    for index, fluid in pairs(saved_surrounding_fluids.self) do
      new_entity.fluidbox[index] = fluid
    end
    for entity, fluid_table in pairs(saved_surrounding_fluids.surrounding) do
      for index, fluid in pairs(fluid_table) do
        if fluid == "empty" then fluid = nil end
        entity.fluidbox[index] = fluid
      end
    end
  else
    log("Error: No saved fluids!")
  end

  local player
  local force
  if event.player_index then
    -- Removed by player
    player = game.get_player(event.player_index)
  elseif event.robot then
    if event.robot.logistic_network and event.robot.logistic_network.cells[1] and event.robot.logistic_network.cells[1].owner.type == "character" then
      -- Removed by personal bot
      player = event.robot.logistic_network.cells[1].owner.player
    else
      -- Removed by bot
      force = event.robot.force
    end
  end

  if player then
    create_error_message(player, {"undeletable-fluids.mining_prevented"}, fluid_name, new_entity_params.position)
  elseif force then
    create_error_message_for_force(force, {"undeletable-fluids.mining_prevented"}, fluid_name, new_entity_params.position)
  end
end

local function on_player_removed_entity(event)
  -- At this point Factorio has already transferred fluids if possible.
  -- If there's any fluid left that means there was no space to transfer it.
  if event.entity and event.entity.valid then
    local unit_number = event.entity.unit_number
    local fluid_contents = event.entity.get_fluid_contents()
    if table_size(fluid_contents) > 0 and is_any_undeletable(fluid_contents) and is_significant_fluid_amount(fluid_contents) then
      local action = settings.global["undeletable_fluids_removal_action"].value
      if action == "prevent" then
        prevent_removal(event)
      elseif action == "explosion" then
        explosion(event)
      elseif action == "atomic_explosion" then
        atomic_explosion(event)
      end
    end
    -- Removed saved fluids from the pre-mining
    storage.saved_surrounding_fluids_by_unit_number[unit_number] = nil
  end
end
script.on_event(defines.events.on_player_mined_entity, on_player_removed_entity, Event_filter)
script.on_event(defines.events.on_robot_mined_entity, on_player_removed_entity, Event_filter)

local function on_pre_player_removed_entity(event)
  if settings.global["undeletable_fluids_removal_action"].value == "prevent" then
    -- Save fluid amounts of entity and neighbours to potentially restore them during on_player_removed_entity
    if event.entity and event.entity.valid and table_size(event.entity.get_fluid_contents()) > 0 then
      local saved_self_fluids = {}
      local saved_surrounding_fluids = {}
      local mined_fluidbox = event.entity.fluidbox

      for i = 1, #mined_fluidbox do
        local this_fluid_system_id = mined_fluidbox.get_fluid_system_id(i)
        saved_self_fluids[i] = mined_fluidbox[i]

        for _, connected_fluidboxes in pairs(mined_fluidbox.get_connections(i)) do
          local this_entity_saved_fluids = {}
          for j = 1, #connected_fluidboxes do
            if connected_fluidboxes.get_fluid_system_id(j) == this_fluid_system_id then
              this_entity_saved_fluids[j] = connected_fluidboxes[j] or "empty" -- Empty fluidboxes are `nil` which will mess with loop iteration later.
            end
          end
          saved_surrounding_fluids[connected_fluidboxes.owner] = this_entity_saved_fluids
        end
      end
      storage.saved_surrounding_fluids_by_unit_number[event.entity.unit_number] = {
        self = saved_self_fluids,
        surrounding = saved_surrounding_fluids
      }
    end
  end
end
script.on_event(defines.events.on_pre_player_mined_item , on_pre_player_removed_entity, Event_filter)
script.on_event(defines.events.on_robot_pre_mined, on_pre_player_removed_entity, Event_filter)
