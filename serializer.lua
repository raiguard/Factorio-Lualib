--[[ Copyright (c) 2020 robot256 (MIT License)
 * Project: Robot256's Library
 * File: save_restore.lua
 * Description: Functions for converting between inventory, burner, and grid objects and native Lua table structures.
 *   Functions handle items in arrays of SimpleItemStack tables, with the extra "data" field to store blueprints etc.
 *   Functions include nil checking for both objects and arrays.
 *   Functions to insert items into objects return list of stacks representing the items that could not be inserted.
 -]]

require("util")

local flib_serialize = {}
local flib_deserialize = {}

local __saveGridStacks__ = nil
local __saveGrid__ = nil

local exportable_items = {
  ["blueprint"] = true,
  ["blueprint-book"] = true,
  ["upgrade-planner"] = true,
  ["deconstruction-planner"] = true,
  ["item-with-tags"] = true,
}
                    
local blank_planner_strings = {
  ["blueprint-book"] = "0eNqrVkrKKU0tKMrMK4lPys/PVrKqVsosSc1VskJI6IIldJQSk0syy1LjM/NSUiuUrAx0lMpSi4oz8/OUrIwsDE3MLY3MDc3MzS0tjWprAVWnHQo=",
  ["upgrade-planner"] = "0eNo1yk0KgCAQBtC7fGtbKNGklwmhQQSbxJ824t1b+dZvoOdQ/M1XTl6EC9xA5daihAonPSWF2PiBW3NbU+HjUuMrcObUO1lD+iCy1sz5A4aSHcM=",
  ["deconstruction-planner"] = "0eNpdy8EKgCAMANB/2dkOSmTuZyJshGAz3Owi/XtdunR98DpsFAuL1hY1FV7OvDJTBewgpJp4F0BuORtISgfgLwxfMHBRlVcA3WxHH5y3k/chuPt+ALDXI9s=",
}

--- 
local function mergeStackLists(stacks1, stacks2)
  if not stacks2 then
    return stacks1
  end
  if not stacks1 then
    return stacks2
  end
  for _,s in pairs(stacks2) do
    if not s.count then s.count = 1 end
    if s.data or s.health or s.durability or s.ammo then
      table.insert(stacks1, s)
    else
      local found = false
      for _,t in pairs(stacks1) do
        if not t.count then t.count = 1 end
        if s.name == t.name and not (t.ammo or t.data or t.durability) then
          t.count = t.count + s.count
          found = true
          break
        end
      end
      if not found then
        table.insert(stacks1, s)
      end
    end
  end
  return stacks1
end


local function itemsToStacks(items)
  local stacks = {}
  if items then
    for name, count in pairs(items) do
      table.insert(stacks, {name=name, count=count})
    end
    if #stacks == 0 then stacks = nil end
    return stacks
  end
end


---------------------------------------------------------------
-- Insert Stack Structure into Inventory.
-- Arguments:  source -> LuaInventory to save contents of
-- Returns:    stacks -> Dictionary [slot#] -> SimpleItemStack with extra optional field "data" storing blueprint export string
---------------------------------------------------------------
local function saveInventoryStacks(source)
  if source and source.valid and not source.is_empty() then
    local stacks = {}
    for slot = 1, #source do
      local stack = source[slot]
      if stack and stack.valid_for_read then
        if exportable_items[stack.name] then
          table.insert(stacks, {name=stack.name, count=1, data=stack.export_stack()})
        else
          local s = {name=stack.name, count = stack.count}
          if stack.prototype.magazine_size then
            if stack.ammo < stack.prototype.magazine_size then
              s.ammo = stack.ammo
            end
          end
          if stack.prototype.durability then
            if stack.durability < stack.prototype.durability then
              s.durability = stack.durability
            end
          end
          if stack.health < 1 then
            s.health = stack.health
          end
          -- Merge with existing stacks to avoid duplicates
          mergeStackLists(stacks, {s})
          
          -- Can't restore equipment to an item's grid, have to unpack it to the inventory
          if stack.grid and stack.grid.valid then
            local equipStacks, fuelStacks = __saveGridStacks__(__saveGrid__(stack.grid))
            mergeStackLists(stacks, equipStacks)
            mergeStackLists(stacks, fuelStacks)
          end
          
        end
      end
    end
    return stacks
  end
end

---------------------------------------------------------------
-- Insert Stack Structure into Inventory.
-- Arguments:  target -> LuaInventory to insert items into
--             stack -> SimpleItemStack with extra optional field "data" storing blueprint export string.
--             stack_limit (optional) -> integer maximum number of items to insert from the given stack.
-- Returns:    remainder -> SimpleItemStack with extra field "data", representing all the items that could not be inserted at this time.
---------------------------------------------------------------
local function insertStack(target, stack, stack_limit)
  local proto = game.item_prototypes[stack.name]
  if not stack.count then stack.count = 1 end
  local remainder = table.deepcopy(stack)
  if proto then
    if target.can_insert(stack) then
      if stack.data then
        -- Insert bp item, find ItemStack, import data string
        for i = 1, #target do
          if not target[i].valid_for_read then
            -- this stack is empty, set it to blueprint
            target[i].set_stack(stack)
            target[i].import_stack(stack.data)
            return nil  -- no remainders after insertion
          end
        end
      else
        -- Handle normal item, break into chunks if need be, correct for oversized stacks
        if not stack_limit then
          stack_limit = math.huge
        end
        local d = 0
        if stack.count > stack_limit then
          -- This time we limit ourselves to part of the given stack.
          d = target.insert({name=stack.name, count=stack_limit})
        else
          -- Only the last part gets assigned ammo and durability ratings of the original stack
          d = target.insert(stack)
        end
        remainder.count = stack.count - d
        if remainder.count == 0 then
          return nil  -- All items inserted, no remainder
        else
          return remainder  -- Not all items inserted, return remainder with original ammo/durability ratings
        end
      end
    else
      -- Can't insert this stack, entire thing is remainder.
      return remainder
    end
  else
    -- Prototype for this item was removed from the game, don't give a remainder.
    return nil
  end
end

---------------------------------------------------------------
-- Spill Stack Structure onto ground.
-- Arguments:  target -> LuaInventory to insert items into
--             stack -> SimpleItemStack with extra optional field "data" storing blueprint export string.
--             stack_limit (optional) -> integer maximum number of items to insert from the given stack.
-- Returns:    remainder -> SimpleItemStack with extra field "data", representing all the items that could not be inserted at this time.
---------------------------------------------------------------
local function spillStack(stack, surface, position)
  if stack then
    surface.spill_item_stack(position, stack)
    if stack.data then
      -- This is a bp item, find it on the surface and restore data
      for _,entity in pairs(surface.find_entities_filtered{name="item-on-ground",position=position,radius=1000}) do
        -- Check if these are the droids we are looking for
        if entity.stack.valid_for_read then
          local es = entity.stack
          if es.name == stack.name then
            -- TODO: Handle detection of empty deconstruction_planner, upgrade_planner, item_with_tags
            if es.is_blueprint and not es.is_blueprint_setup() then
              -- New empty blueprint, let's import into it
              es.import_stack(stack.data)
              break
            elseif es.is_blueprint_book then
              -- Compare export string to empty blueprint book
              if es.export_stack() == blank_planner_strings["blueprint-book"] then
                es.import_stack(stack.data)
                break
              end
            elseif es.is_upgrade_item then
              -- Compare export string to empty upgrade planner
              if es.export_stack() == blank_planner_strings["upgrade-planner"] then
                es.import_stack(stack.data)
                break
              end
            elseif es.is_deconstruction_item then
              -- Compare export string to empty deconstruction planner
              if es.export_stack() == blank_planner_strings["deconstruction-planner"] then
                es.import_stack(stack.data)
                break
              end
            elseif es.is_item_with_tags  then
              if not es.tags or table_size(es.tags) == 0 then
                es.import_stack(stack.data)
                break
              end
            end
          end
        end
      end
    end
  end
end

local function spillStacks(stacks, surface, position)
  if stacks then
    for _,s in pairs(stacks) do
      spillStack(s, surface, position)
    end
  end
end


---------------------------------------------------------------
-- Restore Inventory Stack List to Inventory.
-- Arguments:  target -> LuaInventory to insert items into
--             stacks -> List of SimpleItemStack with extra optional field "data" storing blueprint export string.
-- Returns:    remainders -> List of SimpleItemStacks representing all the items that could not be inserted at this time.
---------------------------------------------------------------
local function insertInventoryStacks(target, stacks)
  local remainders = {}
  if target and target.valid and stacks then
    for _,stack in pairs(stacks) do
      local r = insertStack(target, stack)
      if r then 
        table.insert(remainders, r)
      end
    end
  elseif stacks then
    -- If inventory invalid, return entire contents
    return stacks
  end
  if #remainders > 0 then
    return remainders
  else
    return nil
  end
end



---------------------------------------------------------------
-- Save the contents of a LuaBurner object.
-- Arguments:  burner -> LuaBurner
-- Returns:    saved -> List structure with stats and inventories of the burner.
---------------------------------------------------------------
local function saveBurner(burner)
  if burner and burner.valid then
    local saved = {heat = burner.heat}
    if burner.currently_burning then
      saved.currently_burning = burner.currently_burning.name
      saved.remaining_burning_fuel = burner.remaining_burning_fuel
    end
    if burner.inventory and burner.inventory.valid then
      saved.inventory = itemsToStacks(burner.inventory.get_contents())
    end
    if burner.burnt_result_inventory and burner.burnt_result_inventory.valid then
      saved.burnt_result_inventory = itemsToStacks(burner.burnt_result_inventory.get_contents())
    end
    return saved
  end
end


---------------------------------------------------------------
-- Restore the contents of a LuaBurner object.
-- Arguments:  target -> LuaBurner
--             saved -> List structure returned by saveBurner()
-- Returns:    remainders -> List of SimpleItemStack containing items from saved structure
--                that could not be inserted into target, or nil if none.
---------------------------------------------------------------
local function restoreBurner(target, saved)
  local remainders = {}
  if target and target.valid and saved then
    -- Only restore burner heat if the fuel prototype still exists and is valid in this burner.
    if (saved.currently_burning and 
        game.item_prototypes[saved.currently_burning] and 
        target.inventory.can_insert({name=saved.currently_burning, count=1})) then
      target.currently_burning = game.item_prototypes[saved.currently_burning]
      target.remaining_burning_fuel = saved.remaining_burning_fuel
      target.heat = saved.heat
    end
    local r1 = insertInventoryStacks(target.inventory, saved.inventory)
    local r2 = insertInventoryStacks(target.burnt_result_inventory, saved.burnt_result_inventory)
    remainders = mergeStackLists(remainders, r1)
    remainders = mergeStackLists(remainders, r2)
    return remainders
  elseif saved then
    -- Return entire contents if target invalid
    remainders = mergeStackLists(remainders, saved.burnt_result_inventory)
    remainders = mergeStackLists(remainders, saved.inventory)
    return remainders
  end
end

--- Convert equipment grid layout to a table containing all attributes of the equipment.
-- Saves position in grid, accumulator & shield energy, and burner inventory & energy.
-- @tfunction serialize.grid
-- @tparam LuaEquipmentGrid grid source
-- @treturn Table structure of saved_grid
function flib_serialize.grid(grid)
  if grid and grid.valid then
    local saved_grid = {}
    for _, equipment in pairs(grid.equipment) do
      local item = {name = equipment.name, position = equipment.position}
      local burner = saveBurner(equipment.burner)
      local energy = nil
      local shield = nil
      if equipment.energy > 0 then
        energy = equipment.energy
      end
      if equipment.shield > 0 then
        shield = equipment.shield
      end
      table.insert(
        saved_grid,
        {
          item = item,
          energy = energy,
          shield=shield,
          burner=burner
        }
      )
    end
    return saved_grid
  else
    return nil
  end
end

__saveGrid__ = flib_serialize.grid

--- Place all the equipment from a saved_grid table into the given grid.
-- @tfunction deserialize.grid
-- @tparam LuaEquipmentGrid grid target
-- @tparam Table saved_grid structure produced by serialize.grid()
-- @treturn List of SimpleItemStack all items that could not be inserted in the target grid
function flib_deserialize.grid(grid, saved_grid)
  local remainder_stacks = {}
  if grid and grid.valid and saved_grid then
    -- Insert as much as possible into this grid, return items not inserted as remainder stacks
    for _, saved_equipment in pairs(saved_grid) do
      if game.equipment_prototypes[saved_equipment.item.name] then
        local equipment = grid.put(saved_equipment.item)
        if equipment then
          if saved_equipment.energy then
            equipment.energy = saved_equipment.energy
          end
          if saved_equipment.shield and saved_equipment.shield > 0 then
            equipment.shield = saved_equipment.shield
          end
          if saved_equipment.burner then
            local fuel_remainder = restoreBurner(equipment.burner, saved_equipment.burner)
            remainder_stacks = mergeStackLists(remainder_stacks, fuel_remainder)
          end
        else
          remainder_stacks = mergeStackLists(
            remainder_stacks,
            {
              {name = saved_equipment.item.name, count = 1}
            }
          )
          if saved_equipment.burner then
            remainder_stacks = mergeStackLists(
              remainder_stacks,
              saved_equipment.burner.inventory
            )
            remainder_stacks = mergeStackLists(
              remainder_stacks,
              saved_equipment.burner.burnt_result_inventory
            )
          end
        end
      end
    end
    
  elseif saved_grid then
    -- If grid is invalid but we have saved items, return the whole grid as a remainder
    local remainder_equipment, remainder_fuel = __saveGridStacks__(saved_grid)
    remainder_stacks = mergeStackLists(remainder_stacks, remainder_equipment)
    remainder_stacks = mergeStackLists(remainder_stacks, remainder_fuel)
  end
  
  if #remainder_stacks > 0 then
    return remainder_stacks
  end
end

--- Modify a saved grid table by removing a particular item.
-- If equipment is removed before its burner fuel, fuel will be lost.
-- @tfunction deserialize.saved_grid_stack
-- @tparam List saved_grid record produced by serialize.save_grid
-- @tparam SimpleItemStack stack item and max count to remove (default count is 1)
function flib_deserialize.remove_grid_stack(saved_grid, stack)
  if saved_grid and stack then
    if not stack.count then
      stack.count = 1
    end
    for i, saved_equip in pairs(saved_grid) do
      if saved_equip.item.name == stack.name then
        saved_grid[i] = nil
        stack.count = stack.count - 1
      elseif saved_equip.burner then
        if saved_equip.burner.inventory then
          for j, fuel_stack in pairs(saved_equip.burner.inventory) do
            if fuel_stack.name == stack.name then
              if fuel_stack.count <= stack.count then
                stack.count = stack.count - fuel_stack.count
                saved_equip.burner.inventory[j] = nil
              else
                fuel_stack.count = fuel_stack.count - stack.count
                stack.count = 0
              end
            end
          end
        end
      end
      if stack.count == 0 then
        break
      end
    end
  end
end

--- Convert the contents of the grid to a list of SimpleItemStack
-- @tfunction serialize.grid_to_stacks
-- @tparam LuaEquipmentGrid grid
-- @treturn List of SimpleItemStack equipment items from the grid
-- @treturn List of SimpleItemStack fuel items from the grid
function flib_serialize.grid_to_stacks(grid)
  local items = {}
  local fuel_items = {}
  if grid then
    for _, equipment in pairs(grid) do
      if equipment.burner then
        fuel_items = mergeStackLists(fuel_items, equipment.burner.inventory)
        fuel_items = mergeStackLists(fuel_items, equipment.burner.burnt_result_inventory)
      end
      items = mergeStackLists(items, {{name = equipment.item.name, count = 1}})
    end
    return items, fuel_items
  end
end

__saveGridStacks__ = flib_serialize.grid_to_stacks

--- Save the inventory slot filters and limit bar position of the source inventory.
-- @tfunction serialize.inventory_filters
-- @tparam LuaInventory source
-- @treturn nil|dictionary uint slot -> string item-name, ["bar"] -> bar position
function flib_serialize.inventory_filters(source)
  local filters = nil
  if source and source.valid then
    if source.is_filtered() then
      filters = {}
      for f = 1, #source do
        filters[f] = source.get_filter(f)
      end
    end
    if source.supports_bar() and source.get_bar() <= #source then
      filters = filters or {}
      filters.bar = source.get_bar()
    end
  end
  return filters
end

--- Apply the inventory slot filters and limit bar position to the target inventory.
-- @tfunction deserialize.inventory_filters
-- @tparam LuaInventory target
-- @tparam dictionary filters uint slot -> string item-name AND ["bar"] -> bar position
function flib_deserialize.inventory_filters(target, filters)
  if target and target.valid and filters then
    if target.supports_filters() then
      for f = 1, #target do
        target.set_filter(f, filters[f])
      end
    end
    if target.supports_bar() then
      if filters.bar then
        target.set_bar(filters.bar)
      else
        target.set_bar()  -- Call with no arguments to clear bar
      end
    end
  end
end

--- Returns a list of items being requested by proxies on the target entity.
-- Assumes proxies are created by the force that owns the target.
-- @tfunction serialize.item_request_proxy
-- @tparam LuaEntity target
-- @treturn nil|dictionary string -> uint  Mapping item-name to request count
-- @usage
-- -- read request proxies on old_entity and create them on new_entity
-- local item_requests = serialize.item_request_proxy(old_entity)
-- if item_requests then
--   surface.create_entity{
--     name = "item-request-proxy",
--     position = new_entity.position,
--     force = new_entity.force,
--     target = new_entity,
--     modules = item_requests
--   }
-- end
function flib_serialize.item_request_proxy(target)
  -- Search for item_request_proxy ghosts targeting this entity
  local proxies = target.surface.find_entities_filtered{
    name = "item-request-proxy",
    force = target.force,
    position = target.position
  }
  for _, proxy in pairs(proxies) do
    if proxy.proxy_target == target and proxy.valid then
      local items = nil
      for item, count in pairs(proxy.item_requests) do
        items = items or {}
        items[item] = count
      end
      -- Return nil if proxy contains empty item list (caused by editor mode)
      return items
    end
  end
end

return flib_serialize, flib_deserialize
