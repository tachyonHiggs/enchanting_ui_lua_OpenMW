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

---@class SoulsListData : UIToolkit.ListData.Column
---@field name string
---@field value number
---@field soul_name string
---@field count number

local rowHeight = 25
local souls_window_size = {620, 600}

---@type UIToolkit.SortedList.Column[]
local columns = {
    {
        id = 'icon',
        render = ColumnItem.renderIcon,
        width = rowHeight + 10,
    },
    {
        id = 'name',
        name = 'Name', --TODO: add L10N
        auto = 3,
        sort = {},
        render = ColumnItem.renderText,

    },
    {
        id = 'value',
        name = 'Value', --TODO: add L10N
        auto = 3,
        sort = { numeric = true },
        render = ColumnItem.renderText,
        arg = { textAlignH = ui.ALIGNMENT.Center },
        align = ui.ALIGNMENT.Center,
    },
    {
        id = 'soul_name',
        name = 'Soul Name', --TODO: add L10N
        auto = 2,
        sort = {},
        render = ColumnItem.renderText,
    },
    {
        id = 'count',
        name = 'Count', --TODO: add L10N
        auto = 3,
        sort = { numeric = true },
        render = ColumnItem.renderText,
        arg = { textAlignH = ui.ALIGNMENT.Center },
        align = ui.ALIGNMENT.Center,
    },
}

local souls_ui = {}

function souls_ui.on_soul_clicked(id, object, value, icon)

    ambient.playSound('Item Misc Up')

    enchanter.soul.id = id
    enchanter.soul.object = object
    enchanter.soul.icon = icon
    enchanter.soul.charge = value
    elements.set_stats_charge()

    enchanter.item.enchantment_capacity = enchanter.item.default_enchantment_capacity * enchanter.scale_enchantment_capacity_factor_from_soul_charge()
    elements.set_stats_enchantment()

    -- Update count max, but don't show it
    -- elements.count_input:set_max_min(enchanter.get_count_max(), nil)
    
    -- print("click on soul: ", id)
    -- print("at icon: ", icon)
    -- print("with a soul value of: ", value)
    -- elements.soul_input:set_image(icon)

    souls_ui.closePopup()
end

function souls_ui.closePopup()
    if not souls_ui._closeListPopup then return end
    souls_ui._closeListPopup()
    souls_ui._closeListPopup = nil
end

---@return SoulsListData
local function create_soul_item(item)
    local id = item.recordId
    print(id)
    local record = types.Miscellaneous.records[id]
    local soul = types.Item.itemData(item).soul
    local count = item.count

    print("record.icon: ", record.icon)
    ---@type SoulsListData
    return
    {
        id = item.id,
        name = record.name,
        value = types.Creature.records[soul].soulValue,
        soul_name = types.Creature.records[soul].name,
        count = count,
        icon = record.icon,
    }
end

---@return SoulsListData[]
function souls_ui.make_souls_list()
    print("make_souls_list")
    local valid_items = {}

    local items = enchanter.get_inventory_souls()
    for index, item in pairs(items) do
        table.insert(valid_items, create_soul_item(item))
    end

    return valid_items
end

function souls_ui.show_soul_list(soul_icon)
    print("souls_ui.show_soul_list")
    local theme = I.UIToolkit.getTheme()

    ambient.playSound('menu click')

    local titleHeight = math.floor(1.5 * rowHeight)
    local allItems = souls_ui.make_souls_list()

    local list = I.UIToolkit.Components.sortedList {
        size = v2(souls_window_size[1], souls_window_size[2] - titleHeight),
        columns = columns,
        rowHeight = rowHeight,
        onItemClicked = function(data)
            souls_ui.on_soul_clicked(data.id, data.object, data.value, data.icon)
        end,
    }
    list:setItems(allItems)
    list.header:toggleColumn('name')

    -- Change and update UI

    local filter = I.UIToolkit.Components.textEdit {
        width = 250,
        default = '',
        placeholder = 'Filter Soul Gems...',
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
        name = "souls_list",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = UI.content {
            {
                props = {
                    size = v2(souls_window_size[1], titleHeight),
                },
                content = ui.content {
                    {
                        template = I.UIToolkit.Templates.header(),
                        props = {
                            text = 'Select Soul Gem:',
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

    souls_ui.soul_icon = soul_icon

    souls_ui._closeListPopup = I.UIToolkit.Popups.show {
        body = layout,
    }
end

return souls_ui
