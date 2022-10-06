data:extend{
  {
      type = "bool-setting",
      name = "undeletable_fluids_nope",
      setting_type = "runtime-global",
      default_value = false,
  },
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
    }
}
}
