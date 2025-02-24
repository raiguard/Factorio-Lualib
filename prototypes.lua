--- Provides utilities for locating and iterating prototypes in `data.raw`.
--- @class flib_prototypes
local flib_prototypes = {}

--- Returns a list of all prototypes with the given `base_type`.
--- @overload fun(base_type: "achievement"): data.AchievementPrototype[]
--- @overload fun(base_type: "active-trigger"): data.ActiveTriggerPrototype[]
--- @overload fun(base_type: "airborne-pollutant"): data.AirbornePollutantPrototype[]
--- @overload fun(base_type: "ambient-sound"): data.AmbientSound[]
--- @overload fun(base_type: "ammo-category"): data.AmmoCategory[]
--- @overload fun(base_type: "animation"): data.AnimationPrototype[]
--- @overload fun(base_type: "asteroid-chunk"): data.AsteroidChunkPrototype[]
--- @overload fun(base_type: "autoplace-control"): data.AutoplaceSpecification[]
--- @overload fun(base_type: "burner-usage"): data.BurnerUsagePrototype[]
--- @overload fun(base_type: "collision-layer"): data.CollisionLayerPrototype[]
--- @overload fun(base_type: "custom-event"): data.CustomEventPrototype[]
--- @overload fun(base_type: "custom-input"): data.CustomInputPrototype[]
--- @overload fun(base_type: "damage-type"): data.DamageType[]
--- @overload fun(base_type: "decorative"): data.DecorativePrototype[]
--- @overload fun(base_type: "deliver-category"): data.DeliverCategory[]
--- @overload fun(base_type: "deliver-impact-combination"): data.DeliverImpactCombination[]
--- @overload fun(base_type: "editor-controller"): data.EditorControllerPrototype[]
--- @overload fun(base_type: "entity"): data.EntityPrototype[]
--- @overload fun(base_type: "equipment"): data.EquipmentPrototype[]
--- @overload fun(base_type: "equipment-category"): data.EquipmentCategory[]
--- @overload fun(base_type: "equipment-grid"): data.EquipmentGridPrototype[]
--- @overload fun(base_type: "fluid"): data.FluidPrototype[]
--- @overload fun(base_type: "font"): data.FontPrototype[]
--- @overload fun(base_type: "fuel-category"): data.FuelCategory[]
--- @overload fun(base_type: "god-controller"): data.GodControllerPrototype[]
--- @overload fun(base_type: "gui-style"): data.GuiStyle[]
--- @overload fun(base_type: "impact-category"): data.ImpactCategory[]
--- @overload fun(base_type: "item"): data.ItemPrototype[]
--- @overload fun(base_type: "item-group"): data.ItemGroup[]
--- @overload fun(base_type: "item-subgroup"): data.ItemSubGroup[]
--- @overload fun(base_type: "map-gen-presets"): data.MapGenPresets[]
--- @overload fun(base_type: "map-settings"): data.MapSettings[]
--- @overload fun(base_type: "module-category"): data.ModuleCategory[]
--- @overload fun(base_type: "mouse-cursor"): data.MouseCursor[]
--- @overload fun(base_type: "noise-expression"): data.NamedNoiseExpression[]
--- @overload fun(base_type: "noise-function"): data.NamedNoiseFunction[]
--- @overload fun(base_type: "particle"): data.ParticlePrototype[]
--- @overload fun(base_type: "procession"): data.ProcessionPrototype[]
--- @overload fun(base_type: "procession-layer-inheritance-group"): data.ProcessionLayerInheritanceGroup[]
--- @overload fun(base_type: "quality"): data.QualityPrototype[]
--- @overload fun(base_type: "recipe"): data.RecipePrototype[]
--- @overload fun(base_type: "recipe-category"): data.RecipeCategory[]
--- @overload fun(base_type: "remote-controller"): data.RemoteControllerPrototype[]
--- @overload fun(base_type: "resource-category"): data.ResourceCategory[]
--- @overload fun(base_type: "shortcut"): data.ShortcutPrototype[]
--- @overload fun(base_type: "sound"): data.SoundPrototype[]
--- @overload fun(base_type: "space-connection"): data.SpaceConnectionPrototype[]
--- @overload fun(base_type: "space-location"): data.SpaceLocationPrototype[]
--- @overload fun(base_type: "spectator-controller"): data.SpectatorControllerPrototype[]
--- @overload fun(base_type: "sprite"): data.SpritePrototype[]
--- @overload fun(base_type: "surface"): data.SurfacePrototype[]
--- @overload fun(base_type: "surface-property"): data.SurfacePropertyPrototype[]
--- @overload fun(base_type: "technology"): data.TechnologyPrototype[]
--- @overload fun(base_type: "tile"): data.TilePrototype[]
--- @overload fun(base_type: "tile-effect"): data.TileEffectDefinition[]
--- @overload fun(base_type: "tips-and-tricks-item"): data.TipsAndTricksItem[]
--- @overload fun(base_type: "tips-and-tricks-item-category"): data.TipsAndTricksItemCategory[]
--- @overload fun(base_type: "trigger-target-type"): data.TriggerTargetType[]
--- @overload fun(base_type: "trivial-smoke"): data.TrivialSmokePrototype[]
--- @overload fun(base_type: "tutorial"): data.TutorialDefinition[]
--- @overload fun(base_type: "utility-constants"): data.UtilityConstants[]
--- @overload fun(base_type: "utility-sounds"): data.UtilitySounds[]
--- @overload fun(base_type: "utility-sprites"): data.UtilitySounds[]
--- @overload fun(base_type: "virtual-signal"): data.VirtualSignalPrototype[]
function flib_prototypes.all(base_type)
  if not base_type then
    error("Did not provide a base_type")
  end
  if type(base_type) ~= "string" then
    error("base_type must be a string")
  end
  if not defines.prototypes[base_type] then
    error("'" .. base_type .. "' is not a valid base prototype type")
  end

  local result = {}
  local result_len = 0
  for prototype_type in pairs(defines.prototypes[base_type]) do
    for _, prototype in pairs(data.raw[prototype_type] or {}) do
      result_len = result_len + 1
      result[result_len] = prototype
    end
  end
  return result
end

--- Returns the prototype with the given `base_type` and `name`, if it exists.
--- @overload fun(base_type: "achievement", name: string): data.AchievementPrototype?
--- @overload fun(base_type: "active-trigger", name: string): data.ActiveTriggerPrototype?
--- @overload fun(base_type: "airborne-pollutant", name: string): data.AirbornePollutantPrototype?
--- @overload fun(base_type: "ambient-sound", name: string): data.AmbientSound?
--- @overload fun(base_type: "ammo-category", name: string): data.AmmoCategory?
--- @overload fun(base_type: "animation", name: string): data.AnimationPrototype?
--- @overload fun(base_type: "asteroid-chunk", name: string): data.AsteroidChunkPrototype?
--- @overload fun(base_type: "autoplace-control", name: string): data.AutoplaceSpecification?
--- @overload fun(base_type: "burner-usage", name: string): data.BurnerUsagePrototype?
--- @overload fun(base_type: "collision-layer", name: string): data.CollisionLayerPrototype?
--- @overload fun(base_type: "custom-event", name: string): data.CustomEventPrototype?
--- @overload fun(base_type: "custom-input", name: string): data.CustomInputPrototype?
--- @overload fun(base_type: "damage-type", name: string): data.DamageType?
--- @overload fun(base_type: "decorative", name: string): data.DecorativePrototype?
--- @overload fun(base_type: "deliver-category", name: string): data.DeliverCategory?
--- @overload fun(base_type: "deliver-impact-combination", name: string): data.DeliverImpactCombination?
--- @overload fun(base_type: "editor-controller", name: string): data.EditorControllerPrototype?
--- @overload fun(base_type: "entity", name: string): data.EntityPrototype?
--- @overload fun(base_type: "equipment", name: string): data.EquipmentPrototype?
--- @overload fun(base_type: "equipment-category", name: string): data.EquipmentCategory?
--- @overload fun(base_type: "equipment-grid", name: string): data.EquipmentGridPrototype?
--- @overload fun(base_type: "fluid", name: string): data.FluidPrototype?
--- @overload fun(base_type: "font", name: string): data.FontPrototype?
--- @overload fun(base_type: "fuel-category", name: string): data.FuelCategory?
--- @overload fun(base_type: "god-controller", name: string): data.GodControllerPrototype?
--- @overload fun(base_type: "gui-style", name: string): data.GuiStyle?
--- @overload fun(base_type: "impact-category", name: string): data.ImpactCategory?
--- @overload fun(base_type: "item", name: string): data.ItemPrototype?
--- @overload fun(base_type: "item-group", name: string): data.ItemGroup?
--- @overload fun(base_type: "item-subgroup", name: string): data.ItemSubGroup?
--- @overload fun(base_type: "map-gen-presets", name: string): data.MapGenPresets?
--- @overload fun(base_type: "map-settings", name: string): data.MapSettings?
--- @overload fun(base_type: "module-category", name: string): data.ModuleCategory?
--- @overload fun(base_type: "mouse-cursor", name: string): data.MouseCursor?
--- @overload fun(base_type: "noise-expression", name: string): data.NamedNoiseExpression?
--- @overload fun(base_type: "noise-function", name: string): data.NamedNoiseFunction?
--- @overload fun(base_type: "particle", name: string): data.ParticlePrototype?
--- @overload fun(base_type: "procession", name: string): data.ProcessionPrototype?
--- @overload fun(base_type: "procession-layer-inheritance-group", name: string): data.ProcessionLayerInheritanceGroup?
--- @overload fun(base_type: "quality", name: string): data.QualityPrototype?
--- @overload fun(base_type: "recipe", name: string): data.RecipePrototype?
--- @overload fun(base_type: "recipe-category", name: string): data.RecipeCategory?
--- @overload fun(base_type: "remote-controller", name: string): data.RemoteControllerPrototype?
--- @overload fun(base_type: "resource-category", name: string): data.ResourceCategory?
--- @overload fun(base_type: "shortcut", name: string): data.ShortcutPrototype?
--- @overload fun(base_type: "sound", name: string): data.SoundPrototype?
--- @overload fun(base_type: "space-connection", name: string): data.SpaceConnectionPrototype?
--- @overload fun(base_type: "space-location", name: string): data.SpaceLocationPrototype?
--- @overload fun(base_type: "spectator-controller", name: string): data.SpectatorControllerPrototype?
--- @overload fun(base_type: "sprite", name: string): data.SpritePrototype?
--- @overload fun(base_type: "surface", name: string): data.SurfacePrototype?
--- @overload fun(base_type: "surface-property", name: string): data.SurfacePropertyPrototype?
--- @overload fun(base_type: "technology", name: string): data.TechnologyPrototype?
--- @overload fun(base_type: "tile", name: string): data.TilePrototype?
--- @overload fun(base_type: "tile-effect", name: string): data.TileEffectDefinition?
--- @overload fun(base_type: "tips-and-tricks-item", name: string): data.TipsAndTricksItem?
--- @overload fun(base_type: "tips-and-tricks-item-category", name: string): data.TipsAndTricksItemCategory?
--- @overload fun(base_type: "trigger-target-type", name: string): data.TriggerTargetType?
--- @overload fun(base_type: "trivial-smoke", name: string): data.TrivialSmokePrototype?
--- @overload fun(base_type: "tutorial", name: string): data.TutorialDefinition?
--- @overload fun(base_type: "utility-constants", name: string): data.UtilityConstants?
--- @overload fun(base_type: "utility-sounds", name: string): data.UtilitySounds?
--- @overload fun(base_type: "utility-sprites", name: string): data.UtilitySounds?
--- @overload fun(base_type: "virtual-signal", name: string): data.VirtualSignalPrototype?
function flib_prototypes.find(base_type, name)
  if not base_type then
    error("Did not provide a base_type")
  end
  if type(base_type) ~= "string" then
    error("base_type must be a string")
  end
  if not defines.prototypes[base_type] then
    error("'" .. base_type .. "' is not a valid base prototype type")
  end

  if not name then
    error("Did not provide a name")
  end
  if type(name) ~= "string" then
    error("name must be a string")
  end

  for derived_type in pairs(defines.prototypes[base_type]) do
    local prototypes = data.raw[derived_type]
    if prototypes then
      local prototype = prototypes[name]
      if prototype then
        return prototype
      end
    end
  end
end

--- Returns the prototype with the given `base_type` and `name`, throwing an error if it doesn't exist.
--- @overload fun(base_type: "achievement", name: string): data.AchievementPrototype
--- @overload fun(base_type: "active-trigger", name: string): data.ActiveTriggerPrototype
--- @overload fun(base_type: "airborne-pollutant", name: string): data.AirbornePollutantPrototype
--- @overload fun(base_type: "ambient-sound", name: string): data.AmbientSound
--- @overload fun(base_type: "ammo-category", name: string): data.AmmoCategory
--- @overload fun(base_type: "animation", name: string): data.AnimationPrototype
--- @overload fun(base_type: "asteroid-chunk", name: string): data.AsteroidChunkPrototype
--- @overload fun(base_type: "autoplace-control", name: string): data.AutoplaceSpecification
--- @overload fun(base_type: "burner-usage", name: string): data.BurnerUsagePrototype
--- @overload fun(base_type: "collision-layer", name: string): data.CollisionLayerPrototype
--- @overload fun(base_type: "custom-event", name: string): data.CustomEventPrototype
--- @overload fun(base_type: "custom-input", name: string): data.CustomInputPrototype
--- @overload fun(base_type: "damage-type", name: string): data.DamageType
--- @overload fun(base_type: "decorative", name: string): data.DecorativePrototype
--- @overload fun(base_type: "deliver-category", name: string): data.DeliverCategory
--- @overload fun(base_type: "deliver-impact-combination", name: string): data.DeliverImpactCombination
--- @overload fun(base_type: "editor-controller", name: string): data.EditorControllerPrototype
--- @overload fun(base_type: "entity", name: string): data.EntityPrototype
--- @overload fun(base_type: "equipment", name: string): data.EquipmentPrototype
--- @overload fun(base_type: "equipment-category", name: string): data.EquipmentCategory
--- @overload fun(base_type: "equipment-grid", name: string): data.EquipmentGridPrototype
--- @overload fun(base_type: "fluid", name: string): data.FluidPrototype
--- @overload fun(base_type: "font", name: string): data.FontPrototype
--- @overload fun(base_type: "fuel-category", name: string): data.FuelCategory
--- @overload fun(base_type: "god-controller", name: string): data.GodControllerPrototype
--- @overload fun(base_type: "gui-style", name: string): data.GuiStyle
--- @overload fun(base_type: "impact-category", name: string): data.ImpactCategory
--- @overload fun(base_type: "item", name: string): data.ItemPrototype
--- @overload fun(base_type: "item-group", name: string): data.ItemGroup
--- @overload fun(base_type: "item-subgroup", name: string): data.ItemSubGroup
--- @overload fun(base_type: "map-gen-presets", name: string): data.MapGenPresets
--- @overload fun(base_type: "map-settings", name: string): data.MapSettings
--- @overload fun(base_type: "module-category", name: string): data.ModuleCategory
--- @overload fun(base_type: "mouse-cursor", name: string): data.MouseCursor
--- @overload fun(base_type: "noise-expression", name: string): data.NamedNoiseExpression
--- @overload fun(base_type: "noise-function", name: string): data.NamedNoiseFunction
--- @overload fun(base_type: "particle", name: string): data.ParticlePrototype
--- @overload fun(base_type: "procession", name: string): data.ProcessionPrototype
--- @overload fun(base_type: "procession-layer-inheritance-group", name: string): data.ProcessionLayerInheritanceGroup
--- @overload fun(base_type: "quality", name: string): data.QualityPrototype
--- @overload fun(base_type: "recipe", name: string): data.RecipePrototype
--- @overload fun(base_type: "recipe-category", name: string): data.RecipeCategory
--- @overload fun(base_type: "remote-controller", name: string): data.RemoteControllerPrototype
--- @overload fun(base_type: "resource-category", name: string): data.ResourceCategory
--- @overload fun(base_type: "shortcut", name: string): data.ShortcutPrototype
--- @overload fun(base_type: "sound", name: string): data.SoundPrototype
--- @overload fun(base_type: "space-connection", name: string): data.SpaceConnectionPrototype
--- @overload fun(base_type: "space-location", name: string): data.SpaceLocationPrototype
--- @overload fun(base_type: "spectator-controller", name: string): data.SpectatorControllerPrototype
--- @overload fun(base_type: "sprite", name: string): data.SpritePrototype
--- @overload fun(base_type: "surface", name: string): data.SurfacePrototype
--- @overload fun(base_type: "surface-property", name: string): data.SurfacePropertyPrototype
--- @overload fun(base_type: "technology", name: string): data.TechnologyPrototype
--- @overload fun(base_type: "tile", name: string): data.TilePrototype
--- @overload fun(base_type: "tile-effect", name: string): data.TileEffectDefinition
--- @overload fun(base_type: "tips-and-tricks-item", name: string): data.TipsAndTricksItem
--- @overload fun(base_type: "tips-and-tricks-item-category", name: string): data.TipsAndTricksItemCategory
--- @overload fun(base_type: "trigger-target-type", name: string): data.TriggerTargetType
--- @overload fun(base_type: "trivial-smoke", name: string): data.TrivialSmokePrototype
--- @overload fun(base_type: "tutorial", name: string): data.TutorialDefinition
--- @overload fun(base_type: "utility-constants", name: string): data.UtilityConstants
--- @overload fun(base_type: "utility-sounds", name: string): data.UtilitySounds
--- @overload fun(base_type: "utility-sprites", name: string): data.UtilitySounds
--- @overload fun(base_type: "virtual-signal", name: string): data.VirtualSignalPrototype
function flib_prototypes.get(base_type, name)
  local result = flib_prototypes.find(base_type, name)
  if not result then
    error("Prototype '" .. base_type .. "/" .. name .. "' does not exist.")
  end
  return result
end

return flib_prototypes
