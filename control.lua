require("scripts/util")
require("scripts/common")
require("scripts/flush")
require("scripts/removal")
require("scripts/marked-for-deconstruction")
require("scripts/destruction")
require("scripts/tank-contents-tracking")
require("scripts/remote-interface")

local function check_for_nullius()
  if script.active_mods["nullius"] then
    local undeletable_fluids = {
      "nullius-sludge",
      "nullius-chlorine",
      "nullius-hydrogen-chloride",
      "nullius-acid-hydrochloric",
      "nullius-ethylene",
      "nullius-propene",
      "nullius-benzene",
      "nullius-acid-sulfuric",
      "nullius-butadiene",
      "nullius-styrene",
      "nullius-acrylonitrile",
      "nullius-ech",
      "nullius-glycerol",
      "nullius-lubricant",
      "nullius-solvent",
      "nullius-epoxy",
      "nullius-titanium-tetrachloride",
      "nullius-acid-nitric",
      "nullius-fatty-acids",
      "nullius-oil",
      "nullius-biodiesel",
      "nullius-copper-solution",
    }
    storage.undeletable_fluids = list_to_set(undeletable_fluids)
  else
    storage.undeletable_fluids = {}
  end
end

---@class StorageTankInfo
---@field entity LuaEntity
---@field single_fluidbox boolean For optimization
---@field fluidboxes FluidboxInfo[]

---@class FluidboxInfo
---@field fluid_segment_id uint
---@field fluid_segment_fluid Fluid
---@field fluid_segment_capacity uint

-- Fluid API notes:
-- Returns info about or affects the entire segment:
-- * LuaEntity#get_fluid()
-- * LuaFluidbox#get_fluid_segment_contents()
-- * LuaFluidbox#get_capacity()
-- * LuaEntity#set_fluid()
-- * LuaFluidbox[] = (set)
-- Only returns info about the entity's or fluidbox's contents:
-- * LuaEntity#get_fluid_contents()
-- * LuaFluidbox#[] (get)

local function on_init()
  -- set of fluid names
  storage.undeletable_fluids = {}
  storage.deletable_fluids = {}

  ---@type { [uint]: StorageTankInfo }
  storage.storage_tanks_by_unit_number = {}
  check_for_nullius()

  for _, surface in pairs(game.surfaces) do
    local tanks = surface.find_entities_filtered({type="storage-tank"})
    for _, tank in pairs(tanks) do
      on_new_storage_tank(tank)
    end
  end
end
script.on_init(on_init)

local function on_configuration_changed()
  check_for_nullius()

  -- Lazy man's migrations
  storage.deletable_fluids = storage.deletable_fluids or {}
  storage.storage_tanks_by_unit_number = storage.storage_tanks_by_unit_number or {}
end
script.on_configuration_changed(on_configuration_changed)
