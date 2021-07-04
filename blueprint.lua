--- Adds functions to replace to replace entities in blueprints and cursor selections.
-- Useful for preventing non-buildable entities from being acquired in cheat mode or 
-- placed as ghosts.
-- @module blueprint
-- @alias flib_blueprint
-- @usage local blueprint = require("__flib__.blueprint")  
local flib_blueprint = {}

--- Replace entities and icons in a blueprint.
-- @tfunction replace_blueprint_entities
-- @tparam LuaItemStack blueprint
-- @tparam dictionary entity_map[old_entity_name]->string new_entity_name
local function replace_blueprint_entities(blueprint, entity_map)
  local entities = blueprint.get_blueprint_entities()
  if entities and next(entities) then
    for _, entity in pairs(entities) do
      if entity_map[entity.name] then
        entity.name = entity_map[entity.name]
      end
    end
    blueprint.set_blueprint_entities(entities)
  end
  local icons = blueprint.blueprint_icons
  if icons and next(icons) then
    for _, icon in pairs(icons) do
      if icon.signal.type == "item" then
        if entity_map[icon.signal.name] then
          icon.signal.name = entity_map[icon.signal.name]
        end
      end
    end
    blueprint.blueprint_icons = icons
  end
end

--- Replace entities and icons in a blueprint during on_player_configured_blueprint and 
-- on_player_setup_blueprint events.
-- @tfunction replace_player_blueprint_entities
-- @tparam LuaEvent event
-- @tparam dictionary entity_map[old_entity_name]->string new_entity_name
-- @usage
-- -- replace entities when player picks up a blueprint item in the cursor
-- local uncraftable_mapping = {
--   ["old-entity-1"] = "new_entity-1",
--   ["old-entity-2"] = "new-entity-2",
-- }
-- script.on_event(
--   {
--     defines.events.on_player_setup_blueprint,
--     defines.events.on_player_configured_blueprint,
--   },
--   function (event) 
--     blueprint.replace_blueprint_entities(event, uncraftable_mapping)
--   end
-- )
function flib_blueprint.map_player_blueprint_entities(event, entity_map)
  -- Get Blueprint from player (LuaItemStack object)
  -- If this is a Copy operation, BP is in cursor_stack
  -- If this is a Blueprint operation, BP is in blueprint_to_setup
  -- Need to use "valid_for_read" because "valid" returns true for empty LuaItemStack in cursor
  
  local item1 = game.get_player(event.player_index).blueprint_to_setup
  local item2 = game.get_player(event.player_index).cursor_stack
  if item1 and item1.valid_for_read then
    replace_blueprint_entities(item1, entity_map)
  elseif item2 and item2.valid_for_read and item2.is_blueprint then
    replace_blueprint_entities(item2, entity_map)
  end
  
end

--- Replace or delete disallowed items added to player cursor by the pipette tool.
-- @tfunction map_pipette_item
-- @tparam LuaEvent event
-- @tparam dictionary entity_map[old_entity_name]->string new_entity_name
-- @usage
-- -- replace items in the cursor when player uses the pipette tool on an entity
-- local uncraftable_mapping = {
--   ["old-entity-1"] = "new_entity-1",
--   ["old-entity-2"] = "new-entity-2",
-- }
-- script.on_event(
--   defines.events.on_player_pipette,
--   function (event) 
--     blueprint.map_pipette_item(event, uncraftable_mapping)
--   end
-- )
function flib_blueprint.map_pipette_item(event, entity_map)
  local item = event.item
  if item and item.valid then
    local new_item_name = entity_map[item.name]
    if new_item_name then
      local player = game.players[event.player_index]
      local cursor = player.cursor_stack
      -- Check if the player got the disallowed item from inventory, and convert them
      if cursor.valid_for_read and not event.used_cheat_mode then
        -- Huh, he actually had MU items.
        cursor.set_stack({name = new_item_name, count = cursor.count})
      else
        -- Check if the player could have gotten the right thing from inventory/cheat, otherwise clear the cursor
        local inventory = player.get_main_inventory()
        local new_item_stack = inventory.find_item_stack(new_item_name)
        cursor.set_stack(new_item_stack)
        if not cursor.valid_for_read then
          if player.cheat_mode then
            cursor.set_stack({name = new_item_name, count = game.item_prototypes[new_item_name].stack_size})
          end
        else
          inventory.remove(new_item_stack)
        end
      end
    end
  end
end

return flib_blueprint
