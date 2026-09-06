---@omw-context player

local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local ui = require("openmw.ui")
local ambient = require('openmw.ambient')
local core = require('openmw.core')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")
local elements = require("scripts.enchanting_ui.ui.elements")
local customize_effect_ui = require("scripts.enchanting_ui.ui_toolkit.customize_effect_ui")


local ColumnItem = require 'scripts.UIToolkit.components.list_items.column_item'

---@class EffectListData : UIToolkit.ListData.Column
---@field name string
---@field school string
---@field baseCost number

local rowHeight = 25

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
        auto = 10,
        sort = {},
        render = ColumnItem.renderText,

    },
    {
        id = 'school',
        name = 'School', --TODO: add L10N
        auto = 5,
        sort = {},
        render = ColumnItem.renderText,
        arg = { textAlignH = ui.ALIGNMENT.Center },
        align = ui.ALIGNMENT.Center,
    },
    {
        id = 'baseCost',
        name = 'Base Cost', --TODO: add L10N
        auto = 3,
        sort = { numeric = true },
        render = ColumnItem.renderText,
        arg = { textAlignH = ui.ALIGNMENT.End },
        align = ui.ALIGNMENT.End,
    },
}

local magic_effects_ui = {}

magic_effects_ui.on_magic_effect_clicked = function(id)
    print("On magic effect clicked: ", id)

    ambient.playSound('menu click')
    if #enchanter.effects_with_params >= 8 then
        print("Max effects added, returning!")
        UI.showMessage("Max number of effects reached")
        return
    end

    enchanter.reset_effect_to_add()
    enchanter.effect_to_add.id = id
    enchanter.effect_to_modify = false

    -- Close this popup
    magic_effects_ui.closePopup()
    -- create customize_effect_ui popup
    customize_effect_ui.show_customize_effect_ui()
end

function magic_effects_ui.closePopup()
    if not magic_effects_ui._closeListPopup then return end
    magic_effects_ui._closeListPopup()
    magic_effects_ui._closeListPopup = nil
end

---@return EffectListData
local function create_magic_effect_item(id)
    local record = core.magic.effects.records[id]
    local school = record.school
    local skill = core.stats.Skill.record(school)
    if skill then school = skill.name end

    ---@type EffectListData
    return
    {
        id = id,
        name = record.name,
        school = school,
        baseCost = record.baseCost,
        icon = record.icon,
        tooltip = { key = id, type = I.UTKTooltips.TYPE.MagicEffect },
    }
end

---@return EffectListData[]
function magic_effects_ui.make_magic_effects_list()
    local known_magic_effects = enchanter.get_known_magic_effects()
    if known_magic_effects == nil then
        print("!! ERROR magic_effects_list is NIL")
        return {}
    end
    local items = {}

    for id in pairs(known_magic_effects) do
        table.insert(items, create_magic_effect_item(id))
    end

    return items or {} -- return the list or just an empty one
end

function magic_effects_ui.show_add_effect_list()
    print("magic_effects_ui.show_add_effect_list")
    local theme = I.UIToolkit.getTheme()

    ambient.playSound('menu click')

    local titleHeight = math.floor(1.5 * rowHeight)
    local allItems = magic_effects_ui.make_magic_effects_list()

    local list = I.UIToolkit.Components.sortedList {
        size = v2(elements.magic_effects_window_size[1], elements.magic_effects_window_size[2] - titleHeight),
        columns = columns,
        rowHeight = rowHeight,
        onItemClicked = function(data)
            magic_effects_ui.on_magic_effect_clicked(data.id)
        end,
    }
    list:setItems(allItems)
    list.header:toggleColumn('name')

    local filter = I.UIToolkit.Components.textEdit {
        width = 250,
        default = '',
        placeholder = 'Filter effects...',
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
        name = "magic_effects_list",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = UI.content {
            {
                props = {
                    size = v2(elements.magic_effects_window_size[1], titleHeight),
                },
                content = ui.content {
                    {
                        template = I.UIToolkit.Templates.header(),
                        props = {
                            text = 'Select Effect:',
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

    magic_effects_ui._closeListPopup = I.UIToolkit.Popups.show {
        body = layout,
    }
end

return magic_effects_ui
