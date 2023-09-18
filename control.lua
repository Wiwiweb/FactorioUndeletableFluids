require("scripts/util")
require("scripts/common")
require("scripts/flush")
require("scripts/removal")
require("scripts/destruction")
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
    global.undeletable_fluids = list_to_set(undeletable_fluids)
  else
    global.undeletable_fluids = {}
  end
end

local function on_init()
  -- unit number (of the mined entity) -> 
  --   self: <table: fluidbox_id -> fluid>, 
  --   surrounding: table<entity -> <table: fluidbox_id -> fluid>>
  global.saved_surrounding_fluids_by_unit_number = {}
  -- set of fluid names
  global.undeletable_fluids = {}
  global.deletable_fluids = {}
  check_for_nullius()
end
script.on_init(on_init)

local function on_configuration_changed()
  check_for_nullius()
  global.deletable_fluids = global.deletable_fluids or {} -- Lazy man's migration
end
script.on_configuration_changed(on_configuration_changed)
