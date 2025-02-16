

local function on_tick()
  local fluid_segment_infos_by_id = {}
  for unit_number, tank_info in pairs(storage.storage_tanks_by_unit_number) do
    local entity = tank_info.entity
    if not entity.valid then
      storage.storage_tanks_by_unit_number[unit_number] = nil
    else
      for i = 1, #entity.fluidbox do
        local fluid_segment_id = entity.fluidbox.get_fluid_segment_id(i)
        if fluid_segment_infos_by_id[fluid_segment_id] == nil then
          fluid_segment_infos_by_id[fluid_segment_id] = {
            contents = entity.fluidbox.get_fluid_segment_contents(i),
            capacity = entity.fluidbox.get_capacity(i)
          }
        end
        tank_info.fluidboxes[i] = {
          contents = entity.fluidbox[i],
          fluid_segment_id = fluid_segment_id,
          fluid_segment_info = fluid_segment_infos_by_id[fluid_segment_id] -- Intentionally not deepcopied
        }
      end
    end
  end
end
script.on_event(defines.events.on_tick, on_tick)

function on_new_storage_tank(entity)
  local tank_info = {
    entity = entity,
    fluidboxes = {},
  }
  for i = 1, #entity.fluidbox do
    table.insert(tank_info.fluidboxes, {
      contents = entity.fluidbox[i],
      fluid_segment_id = entity.fluidbox.get_fluid_segment_id(i),
      fluid_segment_contents = entity.fluidbox.get_fluid_segment_id(i),
    })
  end
  storage.storage_tanks_by_unit_number[entity.unit_number] = tank_info
end

local function on_built(event)
  if event.entity.valid then
    on_new_storage_tank(event.entity)
  end
end
script.on_event(defines.events.on_built_entity, on_built, Tanks_event_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, Tanks_event_filter)
script.on_event(defines.events.script_raised_built, on_built, Tanks_event_filter)
script.on_event(defines.events.script_raised_revive, on_built, Tanks_event_filter)

local function on_cloned(event)
  if event.destination.valid then
    on_new_storage_tank(event.destination)
  end
end
script.on_event(defines.events.on_entity_cloned, on_cloned, Tanks_event_filter)
