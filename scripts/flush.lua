local function prevent_flushing(event)
  if event.amount < settings.global["undeletable_fluids_minimum_threshold"].value then
    return -- Don't prevent anything for fluid amounts below threshold.
  end

  -- I love fluids 2.0
  event.entity.insert_fluid(
    {name = event.fluid, amount = event.amount}
  )

  local player = game.get_player(event.player_index)
  create_error_message(player, {"undeletable-fluids.flush_prevented"}, event.fluid)
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
