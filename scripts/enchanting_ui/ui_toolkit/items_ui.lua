---@omw-context player

local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local ui = require("openmw.ui")
local ambient = require('openmw.ambient')
local types = require('openmw.types')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")
local elements = require("scripts.enchanting_ui.ui.elements")


local ColumnItem = require 'scripts.UIToolkit.components.list_items.column_item'

---@class ItemsListData : UIToolkit.ListData.Column
---@field name string
---@field enchant_pts number
---@field type string
---@field count number
---@field item userdata

local rowHeight = 25
local items_window_size = {620, 600}
local icon_width = 35
local enchant_pts_width = 100

---@type UIToolkit.SortedList.Column[]
local columns = {
    {
        id = 'icon',
        render = ColumnItem.renderIcon,
        width = icon_width,
    },
    {
        id = 'name',
        name = 'Name', --TODO: add L10N
        auto = 5,
        sort = {},
        render = ColumnItem.renderText,

    },
    {
        id = 'type',
        name = 'Type', --TODO: add L10N
        auto = 2,
        sort = {},
        render = ColumnItem.renderText,

    },
    {
        id = 'enchant_pts',
        name = 'Enchant Pts', --TODO: add L10N
        width = enchant_pts_width,
        sort = { numeric = true },
        render = ColumnItem.renderText,
        arg = { textAlignH = ui.ALIGNMENT.End },
        align = ui.ALIGNMENT.End,
    },
    {
        id = 'count',
        name = 'Count', --TODO: add L10N
        width = enchant_pts_width,
        sort = { numeric = true },
        render = ColumnItem.renderText,
        arg = { textAlignH = ui.ALIGNMENT.End },
        align = ui.ALIGNMENT.End,
    },
}

local items_ui = {}

-- TODO: should this only pass object?
function items_ui.on_item_clicked(id, object, icon, enchant_pts, type_text)

    -- TODO: add appropiate sound to play depending on item type
    ambient.playSound('Item Misc Up')

    -- Reset data
    enchanter.reset_enchantment()
    enchanter.reset_item()

    -- if item == ammo/throwable
    enchanter.item.count = 1
    elements.count_input:hide()
    if object.type == types.Weapon then
        local weapon_type = object.type.records[id].type
        local is_ammo = weapon_type == types.Weapon.TYPE.Arrow or weapon_type == types.Weapon.TYPE.Bolt or weapon_type == types.Weapon.TYPE.MarksmanThrown
        if is_ammo then
            enchanter.item.count = object.count
            print("Projectile item selected with a total of: ", enchanter.item.count)
            elements.count_input:set_max_min(enchanter.get_count_max(), nil)
            elements.count_input:show()
        end
    end
    enchanter.item.id = id
    enchanter.item.object = object
    enchanter.item.icon = icon
    enchanter.item.type = type_text
    enchanter.item.default_enchantment_capacity = enchant_pts
    enchanter.item.enchantment_capacity = enchanter.item.default_enchantment_capacity * enchanter.scale_enchantment_capacity_factor_from_soul_charge()

    -- print("click on item: ", id)
    -- print("Icon: ", icon)
    -- print("Type: ", type_text)
    -- print("enchant_pts: ", string.format("%.1f", enchant_pts))
    elements.item_input:set_image(icon)
    
    elements.show_valid_cast_types()

    elements.set_stats_charge()
    elements.set_stats_enchantment()
    elements.set_chance()

    elements.effects:clear()
    
    elements.reset_type_buttons_backgrounds()
    
    elements.root:show()

    elements.items_root:destroy()
end

---@return ItemsListData
local function create_enchantable_item(item)
    local id = item.recordId

    ---@type ItemsListData
    return
    {
        id = id,
        name = item.type.records[id].name,
        enchant_pts = item.type.records[id].enchantCapacity,
        type = item.type,
        count = item.count,
        icon = item.type.records[id].icon,
        item = item,
    }
end

---@return ItemsListData[]
function items_ui.make_enchantable_items_list()
    print("make_enchantable_items_list")
    local valid_items = {}

    local items = enchanter.get_enchantable_inventory_items()
    for _, item in pairs(items) do
        table.insert(valid_items, create_enchantable_item(item))
    end

    return valid_items
end

function items_ui.show_items_list()
    print("items_ui.show_items_list")
    local theme = I.UIToolkit.getTheme()

    ambient.playSound('menu click')

    local titleHeight = math.floor(1.5 * rowHeight)
    local allItems = items_ui.make_enchantable_items_list()

    local list = I.UIToolkit.Components.sortedList {
        size = v2(items_window_size[1], items_window_size[2] - titleHeight),
        columns = columns,
        rowHeight = rowHeight,
        onItemClicked = function(data)
            items_ui.on_item_clicked(data.id, data.item, data.icon, data.enchant_pts, data.type)
        end,
    }
    list:setItems(allItems)
    list.header:toggleColumn('name')

    -- Change and update UI
    elements.root:hide()
    local props = {
        relativeSize = v2(1, 1),
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
        visible = true,
    }

    local filter = I.UIToolkit.Components.textEdit {
        width = 250,
        default = '',
        placeholder = 'Filter items...',
        showClearButton = true,
        onValueChanged = function(value)
            if value == nil or value == '' then
                list:setItems(allItems)
                return
            end
            value = value:lower()
            local filtered = {}
            for i = 1, #allItems do
                local item = allItems[i]
                if item.name:lower():find(value, 1, true) then
                    filtered[#filtered + 1] = item
                end
            end
            list:setItems(filtered)
        end,
    }
    filter:updateProps {
        anchor = v2(1, 0),
        relativePosition = v2(1, 0),
        position = v2(-5, 5),
    }

    local layout = {
        name = "items_list",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = UI.content {
            {
                props = {
                    size = v2(items_window_size[1], titleHeight),
                },
                content = ui.content {
                    {
                        template = I.UIToolkit.Templates.header(),
                        props = {
                            text = 'Select Item:',
                            textSize = theme.Sizes.textNormal + 2,
                            position = v2(5, 5),
                        },
                    },
                    filter.element,
                },
            },
            list.element,
        }
    }

    elements.items_root = templates.window.new("items_window", UI.TYPE.Container,
        I.UIToolkit.Templates.box { padding = 5, background = 'transparent' }, props, { layout })
    elements.items_root:create()
end
function items_ui.update()
    if elements.items_root.created then
        elements.items_root:update()
    end
end

return items_ui
