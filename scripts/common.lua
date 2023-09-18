Event_filter = {{filter = "type", type = "storage-tank"}, {filter = "type", type = "pipe"}}

function is_undeletable(fluid_name)
  if table_size(global.deletable_fluids) > 0 then
    return not global.deletable_fluids[fluid_name]
  elseif table_size(global.undeletable_fluids) > 0 then
    return global.undeletable_fluids[fluid_name]
  else
    return true -- No lists, everything is undeletable
  end
end

function is_any_undeletable(fluid_contents)
  if (table_size(global.deletable_fluids) > 0) then
    -- Whitelist
    for fluid_name, _amount in pairs(fluid_contents) do
      if not global.deletable_fluids[fluid_name] then return true end
    end
    return false
  else
    -- Blacklist
    if table_size(global.undeletable_fluids) == 0 then return true end -- No lists, everything is undeletable
    for fluid_name, _amount in pairs(fluid_contents) do
      if global.undeletable_fluids[fluid_name] then return true end
    end
    return false
  end
end

function is_significant_fluid_amount(fluid_contents)
  local minimum_threshold = settings.global["undeletable_fluids_minimum_threshold"].value
  for _, amount in pairs(fluid_contents) do
    if amount >= minimum_threshold then
      return true
    end
  end
  return false
end

function create_error_message_for_force(force, default_message, fluid_name, position)
  for _, player in pairs(force.players) do
    create_error_message(player, default_message, fluid_name, position)
  end
end


function create_error_message(player, default_message, fluid_name, position)
  if player then
    local message
    if settings.global["undeletable_fluids_nope"].value then
      message = {"undeletable-fluids.nope"}
    elseif table_size(global.undeletable_fluids) > 0 or table_size(global.deletable_fluids) > 0 then
      local sprite_name = "fluid."..fluid_name
      local localised_name = game.fluid_prototypes[fluid_name].localised_name
      message = {default_message[1] .. '_specific_fluid', sprite_name, localised_name}
    else
      message = default_message
    end

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

function explosion(event)
  event.entity.surface.create_entity({
    name = "explosive-rocket",
    position = event.entity.position,
    target = event.entity.position,
    speed = 1,
  })
end

function atomic_explosion(event)
  event.entity.surface.create_entity({
    name = "atomic-rocket",
    position = event.entity.position,
    target = event.entity.position,
    speed = 1,
  })
end
