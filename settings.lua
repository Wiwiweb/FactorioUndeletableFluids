data:extend{
  {
    type = "string-setting",
    name = "undeletable_fluids_flush_action",
    setting_type = "runtime-global",
    default_value = "prevent",
    allowed_values = {
      "nothing",
      "prevent",
      "explosion",
      "atomic_explosion"
    },
    order = "a"
  },
  {
    type = "string-setting",
    name = "undeletable_fluids_removal_action",
    setting_type = "runtime-global",
    default_value = "prevent",
    allowed_values = {
      "nothing",
      "prevent",
      "explosion",
      "atomic_explosion"
    },
    order = "b"
  },
  {
    type = "string-setting",
    name = "undeletable_fluids_destruction_action",
    setting_type = "runtime-global",
    default_value = "explosion",
    allowed_values = {
      "nothing",
      "prevent",
      "explosion",
      "atomic_explosion"
    },
    order = "c"
  },
  
  {
    type = "bool-setting",
    name = "undeletable_fluids_nope",
    setting_type = "runtime-global",
    default_value = false,
    order = "d"
  },
}
