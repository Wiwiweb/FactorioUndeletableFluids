local function prevent_destruction(event)
  -- We can't just clone the entity and then let Factorio continue with the removal,
  -- because that will prevent existing pipes from connecting to the new entity (they are still connected to the old).
  -- We have to actively destroy it here.
  local entity = event.entity
  local surface = entity.surface

  -- Save fluids before we destroy the entity.
  -- We can't just use get_fluid_contents() because we need temperature.
  local fluids = {}
  for i = 1, #entity.fluidbox do
    table.insert(fluids, entity.fluidbox[i])
  end

  local new_entity_params = {
    name = entity.name,
    position = entity.position,
    direction = entity.direction,
    force = entity.force,
    create_build_effect_smoke = false,
    spawn_decorations = false,
  }

  entity.destroy() -- Destroy the old entity *before* creating the new one to ensure pipe connections.
  local new_entity = surface.create_entity(new_entity_params)

  -- Restore fluids as they were during pre-mining
  -- For destruction, we only need to restore the destroyed entity
  for _, fluid in pairs(fluids) do
    new_entity.insert_fluid(fluid)
  end

  if event.cause and event.cause.player then
    local fluid_name = fluids[1].name
    create_error_message(event.cause.player, {"undeletable-fluids.mining_prevented"}, fluid_name, new_entity_params.position)
  end
end

local function on_entity_died(event)
  if event.entity and event.entity.valid then
    local fluid_contents = event.entity.get_fluid_contents()
    if table_size(fluid_contents) > 0 and is_any_undeletable(fluid_contents) and is_significant_fluid_amount(fluid_contents) then
      local action = settings.global["undeletable_fluids_destruction_action"].value
      if action == "prevent" then
        prevent_destruction(event)
      elseif action == "explosion" then
        explosion(event)
      elseif action == "atomic_explosion" then
        atomic_explosion(event)
      end
    end
  end

end
script.on_event(defines.events.on_entity_died, on_entity_died, Event_filter)
