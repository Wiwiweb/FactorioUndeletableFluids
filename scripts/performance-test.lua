-- TODO compare performance of entity.get_fluid(1) vs entity.fluidbox[1] vs entity.fluidbox.get_fluid_segment_contents(1) vs entity.get_fluid_contents(1).
-- TODO same with set_fluid and fluidbox =
local function perf_get_fluid(tank)
  local fluid = tank.get_fluid(1)
end

local function perf_fluid_contents(tank)
  local fluids = tank.get_fluid_contents()
end

local function perf_fluidbox_index(tank)
  local fluid = tank.fluidbox[1]
end

local function perf_fluidbox_index_from_fluidbox(fluidbox)
  local fluid = fluidbox[1]
end

local function perf_fluid_segment_contents(tank)
  local fluid = tank.fluidbox.get_fluid_segment_contents(1)
end

local function perf_fluid_segment_contents_from_fluidbox(fluidbox)
  local fluid = fluidbox.get_fluid_segment_contents(1)
end

local function perf_test_get()
  local tank = game.surfaces.nauvis.create_entity{name="storage-tank", position={20,0}}
  tank.insert_fluid{name="water", amount=10000}
  local fluidbox = tank.fluidbox

  log("start")
  for i = 1,250000 do
    perf_get_fluid(tank)
    perf_fluid_contents(tank)
    perf_fluidbox_index(tank)
    perf_fluidbox_index_from_fluidbox(fluidbox)
    perf_fluid_segment_contents(tank)
    perf_fluid_segment_contents_from_fluidbox(fluidbox)
  end
  log("end")
end
commands.add_command("perf_test_get", nil, perf_test_get)

local function perf_set_fluid(tank)
  tank.set_fluid(1, {name="water", amount=10000})
end

local function perf_fluidbox_set(tank)
  tank.fluidbox[1] = {name="water", amount=10000}
end

local function perf_fluidbox_set_from_fluidbox(fluidbox)
  fluidbox[1] = {name="water", amount=10000}
end

local function perf_test_set()
  local tank = game.surfaces.nauvis.create_entity{name="storage-tank", position={20,0}}
  tank.insert_fluid{name="water", amount=10000}
  local fluidbox = tank.fluidbox

  log("start")
  for i = 1,250000 do
    perf_set_fluid(tank)
    perf_fluidbox_set(tank)
    perf_fluidbox_set_from_fluidbox(fluidbox)
  end
  log("end")
end
commands.add_command("perf_test_set", nil, perf_test_set)
