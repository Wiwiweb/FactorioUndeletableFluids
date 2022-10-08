require("__core__/lualib/util.lua") -- Gets table.deepcopy

function create_error_message(player_index, default_message, position)
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
