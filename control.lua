require("__core__/lualib/util.lua")

local function create_error_message(player_index, default_message, position)
  local player = game.get_player(player_index)
  if player then
    local message = settings.global["undeletable_fluids_nope"].value and {"undeletable-fluids.nope"} or default_message
    local flying_text_params = {
      text = message
    }
    if position then
      flying_text_params.position = position
    else
      flying_text_params.create_at_cursor = true
    end
    player.create_local_flying_text(flying_text_params)
    player.play_sound({path="utility/cannot_build"})
  end
end

local function prevent_flushing(event)
  if event.only_this_entity then
    event.entity.insert_fluid(
      {name = event.fluid, amount = event.amount}
    )
  else
    -- We can't know what used to be in each fluidbox, let's find them all and then fill them an equal % of their capacity.
    local this_fluid_system_id = event.entity.fluidbox.get_fluid_system_id(1)
    local fluidboxes_list = {}
    local entity_unit_ids_processed = {}
    local total_fluid_system_capacity = 0
    local fluidboxes_to_process = {event.entity.fluidbox}

    local i = 1
    while i <= #fluidboxes_to_process do
      local entity_fluidboxes = fluidboxes_to_process[i]
      local entity = entity_fluidboxes.owner

      if not entity_unit_ids_processed[entity.unit_number] then
        entity_unit_ids_processed[entity.unit_number] = true
        for j = 1, #entity_fluidboxes do
          if entity_fluidboxes.get_fluid_system_id(j) == this_fluid_system_id then
            -- This fluidbox is part of the system
            total_fluid_system_capacity = total_fluid_system_capacity + entity_fluidboxes.get_capacity(j)
            table.insert(fluidboxes_list, entity_fluidboxes)
            for _, connected_fluidboxes in pairs(entity_fluidboxes.get_connections(j)) do
              table.insert(fluidboxes_to_process, connected_fluidboxes)
            end
          end
        end
      end

      i = i + 1
    end

    local percent_to_fill = event.amount / total_fluid_system_capacity
    -- log("nb fluidboxes: " .. table_size(fluidboxes_list))
    -- log("total_fluid_system_capacity: " .. total_fluid_system_capacity)
    -- log("nb percent_to_fill: " .. percent_to_fill)

    for _, fluidboxes in pairs(fluidboxes_list) do
      for j = 1, #fluidboxes do
        if fluidboxes.get_fluid_system_id(j) == this_fluid_system_id then
          fluidboxes[j] = {name = event.fluid, amount = fluidboxes.get_capacity(j) * percent_to_fill}
        end
      end
    end

  end

  create_error_message(event.player_index, {"undeletable-fluids.flush_prevented"})

end

local function explosion(event)
  event.entity.surface.create_entity({
    name = "explosive-rocket",
    position = event.entity.position,
    target = event.entity.position,
    speed = 1,
  })
end

local function atomic_explosion(event)
  event.entity.surface.create_entity({
    name = "atomic-rocket",
    position = event.entity.position,
    target = event.entity.position,
    speed = 1,
  })
end

local function on_player_flushed_fluid(event)
  local action = settings.global["undeletable_fluids_flush_action"].value
  if action == "prevent" then
    prevent_flushing(event)
  elseif action == "explosion" then
    explosion(event)
  elseif action == "atomic_explosion" then
    atomic_explosion(event)
  end
end
script.on_event(defines.events.on_player_flushed_fluid, on_player_flushed_fluid)

local function balance_surrounding_fluidboxes(starting_fluidboxes)
  for i = 1, #starting_fluidboxes do
    local surrounding_fluidboxes_list = {
      {fluidboxes = starting_fluidboxes, index = i}
    }
    local surrounding_fluidboxes_total_amount = starting_fluidboxes[i].amount
    local surrounding_fluidboxes_total_capacity = starting_fluidboxes.get_capacity(i)
    local fluid_name = starting_fluidboxes[i].name
    local this_fluid_system_id = starting_fluidboxes.get_fluid_system_id(i)
    for _, connected_fluidboxes in pairs(starting_fluidboxes.get_connections(i)) do
      -- Only need to check all direct connections, not recursively,
      -- because the Factorio engine only transfers to those.
      for j = 1, #connected_fluidboxes do
        if connected_fluidboxes.get_fluid_system_id(j) == this_fluid_system_id and connected_fluidboxes[j].name == fluid_name then
          table.insert(surrounding_fluidboxes_list, {fluidboxes = connected_fluidboxes, index = j})
          surrounding_fluidboxes_total_amount = surrounding_fluidboxes_total_amount + connected_fluidboxes[j].amount
          surrounding_fluidboxes_total_capacity = surrounding_fluidboxes_total_capacity + connected_fluidboxes.get_capacity(j)
        end
      end
    end

    -- TODO: This won't work with fluidboxes that have height and base_level.
    local percent_to_fill = surrounding_fluidboxes_total_amount / surrounding_fluidboxes_total_capacity
    for _, surrounding_fluidboxes in pairs(surrounding_fluidboxes_list) do
      local fluid = surrounding_fluidboxes.fluidboxes[surrounding_fluidboxes.index]
      fluid.amount = percent_to_fill * surrounding_fluidboxes.fluidboxes.get_capacity(surrounding_fluidboxes.index)
      surrounding_fluidboxes.fluidboxes[surrounding_fluidboxes.index] = fluid
    end
  end
end

local function prevent_removal(event)
  -- We can't just clone the entity and then let Factorio continue with the removal,
  -- because that will prevent existing pipes from connecting to the new entity (they are still connected to the old).
  -- We have to actively destroy it here.
  local surface = event.entity.surface
  local fluids = event.entity.get_fluid_contents()
  local new_entity_params = {
    name = event.entity.name,
    position = event.entity.position,
    direction = event.entity.direction,
    force = event.entity.force,
    create_build_effect_smoke = false,
    spawn_decorations = false,
  }

  event.buffer.clear() -- Remove the resulting item from mining.

  event.entity.destroy()
  local new_entity = surface.create_entity(new_entity_params)
  for fluid_name, fluid_amount in pairs(fluids) do
    new_entity.insert_fluid({name = fluid_name, amount = fluid_amount})
  end

  -- Balance out surrounding fluidboxes (Factorio just pushed fluids from this entity to surrounding fluidboxes)
  balance_surrounding_fluidboxes(new_entity.fluidbox)

  create_error_message(event.player_index, {"undeletable-fluids.mining_prevented"}, new_entity_params.position)

end

local function on_player_removed_entity(event)
  -- At this point Factorio has already transferred fluids if possible.
  -- If there's any fluid left that means there was no space to transfer it.
  if event.entity and event.entity.valid and table_size(event.entity.get_fluid_contents()) > 0 then

    -- Ignore leftover small amounts.
    local do_action = false
    for _, amount in pairs(event.entity.get_fluid_contents()) do
      if amount >= 1 then
        do_action = true
        break
      end
    end

    if do_action then
      prevent_removal(event)
    end
  end
end


local event_filter = {{filter = "type", type = "storage-tank"}, {filter = "type", type = "pipe"}}
script.on_event(defines.events.on_player_mined_entity, on_player_removed_entity, event_filter)
script.on_event(defines.events.on_robot_mined_entity, on_player_removed_entity, event_filter)
