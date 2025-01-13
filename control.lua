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
    storage.undeletable_fluids = list_to_set(undeletable_fluids)
  else
    storage.undeletable_fluids = {}
  end
end

local function on_init()
  -- set of fluid names
  storage.undeletable_fluids = {}
  storage.deletable_fluids = {}
  check_for_nullius()
end
script.on_init(on_init)

local function on_configuration_changed()
  check_for_nullius()

  -- Lazy man's migrations
  storage.deletable_fluids = storage.deletable_fluids or {}
  storage.saved_surrounding_fluids_by_unit_number = nil
end
script.on_configuration_changed(on_configuration_changed)
