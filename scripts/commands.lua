commands.add_command("undeletable-fluids-nullius-preset", "Temporary command to set up all Nullius unvoidable fluids as undeletable fluids.", function()
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
  game.print("Set all Nullius unvoidable fluids as undeletable fluids.")
end)
