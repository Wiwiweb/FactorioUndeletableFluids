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

-- function balance_surrounding_fluidboxes(starting_fluidboxes)
--   for i = 1, #starting_fluidboxes do
--     local surrounding_fluidboxes_list = {
--       {fluidboxes = starting_fluidboxes, index = i}
--     }
--     local surrounding_fluidboxes_total_amount = starting_fluidboxes[i].amount
--     local surrounding_fluidboxes_total_capacity = starting_fluidboxes.get_capacity(i)
--     local fluid_name = starting_fluidboxes[i].name
--     local this_fluid_system_id = starting_fluidboxes.get_fluid_system_id(i)
--     for _, connected_fluidboxes in pairs(starting_fluidboxes.get_connections(i)) do
--       -- Only need to check all direct connections, not recursively,
--       -- because the Factorio engine only transfers to those.
--       for j = 1, #connected_fluidboxes do
--         if connected_fluidboxes.get_fluid_system_id(j) == this_fluid_system_id and connected_fluidboxes[j].name == fluid_name then
--           table.insert(surrounding_fluidboxes_list, {fluidboxes = connected_fluidboxes, index = j})
--           surrounding_fluidboxes_total_amount = surrounding_fluidboxes_total_amount + connected_fluidboxes[j].amount
--           surrounding_fluidboxes_total_capacity = surrounding_fluidboxes_total_capacity + connected_fluidboxes.get_capacity(j)
--         end
--       end
--     end

--     -- TODO: This won't work with fluidboxes that have height and base_level.
--     local percent_to_fill = surrounding_fluidboxes_total_amount / surrounding_fluidboxes_total_capacity
--     for _, surrounding_fluidboxes in pairs(surrounding_fluidboxes_list) do
--       local fluid = surrounding_fluidboxes.fluidboxes[surrounding_fluidboxes.index]
--       fluid.amount = percent_to_fill * surrounding_fluidboxes.fluidboxes.get_capacity(surrounding_fluidboxes.index)
--       surrounding_fluidboxes.fluidboxes[surrounding_fluidboxes.index] = fluid
--     end
--   end
-- end