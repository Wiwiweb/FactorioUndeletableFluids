require("__core__/lualib/util.lua") -- Gets table.deepcopy

function set_to_list(map)
  local list = {}
  for key, _ in pairs(map) do
    table.insert(list, key)
  end
  return list
end

list_to_set = util.list_to_map
