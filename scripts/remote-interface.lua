remote.add_interface("undeletable-fluid", {
  get_undeletable_fluid_list = function()
    return set_to_list(global.undeletable_fluids)
  end,

  set_undeletable_fluid_list = function(list)
    global.undeletable_fluids = list_to_set(list)
  end,

  add_undeletable_fluid = function(fluid_name)
    global.undeletable_fluids[fluid_name] = true
  end,

  remove_undeletable_fluid = function(fluid_name)
    global.undeletable_fluids[fluid_name] = nil
  end,
})
