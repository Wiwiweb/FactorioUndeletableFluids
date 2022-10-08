local function prevent_removal(event)
  -- We can't just clone the entity and then let Factorio continue with the removal,
  -- because that will prevent existing pipes from connecting to the new entity (they are still connected to the old).
  -- We have to actively destroy it here.
  local surface = event.entity.surface
  local fluids = event.entity.get_fluid_contents()
  local saved_surrounding_fluids = global.saved_surrounding_fluids_by_unit_number[event.entity.unit_number]
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
    log("NO SAVED FLUIDS!")
    -- Insert old fluids
    -- for fluid_name, fluid_amount in pairs(fluids) do
    --   new_entity.insert_fluid({name = fluid_name, amount = fluid_amount})
    -- end
    -- Balance out surrounding fluidboxes (Factorio just pushed fluids from this entity to surrounding fluidboxes)
    -- balance_surrounding_fluidboxes(new_entity.fluidbox)
  end

  create_error_message(event.player_index, {"undeletable-fluids.mining_prevented"}, new_entity_params.position)
end

local function on_player_removed_entity(event)
  -- At this point Factorio has already transferred fluids if possible.
  -- If there's any fluid left that means there was no space to transfer it.
  if event.entity and event.entity.valid then
    local unit_number = event.entity.unit_number
    local fluid_contents = event.entity.get_fluid_contents()
    if table_size(fluid_contents) > 0 and is_any_undeletable(fluid_contents) then
      -- Ignore leftover small amounts.
      local do_action = false
      for _, amount in pairs(event.entity.get_fluid_contents()) do
        if amount >= 1 then
          do_action = true
          break
        end
      end

      if do_action then
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
    -- Removed saved fluids from the pre-mining
    global.saved_surrounding_fluids_by_unit_number[unit_number] = nil
  end
end
local event_filter = {{filter = "type", type = "storage-tank"}, {filter = "type", type = "pipe"}}
script.on_event(defines.events.on_player_mined_entity, on_player_removed_entity, event_filter)
script.on_event(defines.events.on_robot_mined_entity, on_player_removed_entity, event_filter)

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
      global.saved_surrounding_fluids_by_unit_number[event.entity.unit_number] = {
        self = saved_self_fluids,
        surrounding = saved_surrounding_fluids
      }
    end
  end
end
script.on_event(defines.events.on_pre_player_mined_item , on_pre_player_removed_entity, event_filter)
script.on_event(defines.events.on_robot_pre_mined, on_pre_player_removed_entity, event_filter)
