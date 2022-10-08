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
    type = "bool-setting",
    name = "undeletable_fluids_nope",
    setting_type = "runtime-global",
    default_value = false,
    order = "c"
  },
}
