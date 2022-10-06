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
    game.print("nb fluidboxes: " .. table_size(fluidboxes_list))
    game.print("total_fluid_system_capacity: " .. total_fluid_system_capacity)
    game.print("nb percent_to_fill: " .. percent_to_fill)

    for _, fluidboxes in pairs(fluidboxes_list) do
      for j = 1, #fluidboxes do
        if fluidboxes.get_fluid_system_id(j) == this_fluid_system_id then
          fluidboxes[j] = {name = event.fluid, amount = fluidboxes.get_capacity(j) * percent_to_fill}
        end
      end
    end

  end

  local player = game.get_player(event.player_index)
  if player then
    local message = settings.global["undeletable_fluids_nope"].value and {"undeletable-fluids.nope"} or {"undeletable-fluids.prevented"}
    player.create_local_flying_text({
      text = message,
      create_at_cursor = true
    })
    player.play_sound({path="utility/cannot_build"})
  end

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
