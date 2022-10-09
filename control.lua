require("scripts/util")
require("scripts/common")
require("scripts/flush")
require("scripts/removal")
require("scripts/remote-interface")
require("scripts/commands")

local function on_init()
  -- unit number (of the mined entity) -> 
  --   self: <table: fluidbox_id -> fluid>, 
  --   surrounding: table<entity -> <table: fluidbox_id -> fluid>>
  global.saved_surrounding_fluids_by_unit_number = {}
  -- set of fluid names
  global.undeletable_fluids = {}
end
script.on_init(on_init)
