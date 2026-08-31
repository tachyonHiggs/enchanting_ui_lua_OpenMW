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
local effect_ui = require("scripts.enchanting_ui.ui.effect_ui")


local ColumnItem = require 'scripts.UIToolkit.components.list_items.column_item'

---@class EffectListData : UIToolkit.ListData.Column
---@field name string
---@field school string
---@field baseCost number

local rowHeight = elements.add_effects_list_sizes[1]

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
        auto = 5,
        sort = {},
        render = ColumnItem.renderText,

    },
    {
        id = 'school',
        name = 'School', --TODO: add L10N
        auto = 3,
        sort = {},
        render = ColumnItem.renderText,
        arg = { textAlignH = ui.ALIGNMENT.Center },
        align = ui.ALIGNMENT.Center,
    },
    {
        id = 'baseCost',
        name = 'Base Cost', --TODO: add L10N
        auto = 2,
        sort = { numeric = true },
        render = ColumnItem.renderText,
        arg = { textAlignH = ui.ALIGNMENT.End },
        align = ui.ALIGNMENT.End,
    },
}

local add_effect_ui = {}

add_effect_ui.on_magic_effect_clicked = function(id)
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

    print("CREATING MAGIC EFFECT ADD UI")

    local props = {
        relativeSize = v2(1, 1),
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
        visible = true,
    }
    local effect_ui_add = effect_ui.new(enchanter.effect_to_modify, enchanter.effect_to_add)
    elements.effects_root = templates.window.new("effects_window", UI.TYPE.Container, I.MWUI.templates.boxSolid, props,
        { effect_ui_add:create() })
    elements.effects_root:create()
    add_effect_ui.closeEffectListPopup()
end

function add_effect_ui.closeEffectListPopup()
    if not add_effect_ui._closeListPopup then return end
    add_effect_ui._closeListPopup()
    add_effect_ui._closeListPopup = nil
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
function add_effect_ui.make_magic_effects_list()
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

function add_effect_ui.show_add_effect_list()
    print("add_effect_ui.show_add_effect_list")
    local theme = I.UIToolkit.getTheme()

    ambient.playSound('menu click')

    local titleHeight = math.floor(1.5 * rowHeight)
    local allItems = add_effect_ui.make_magic_effects_list()

    local list = I.UIToolkit.Components.sortedList {
        size = v2(elements.add_effects_size[1], elements.add_effects_size[2] - titleHeight),
        columns = columns,
        rowHeight = rowHeight,
        onItemClicked = function(data)
            add_effect_ui.on_magic_effect_clicked(data.id)
        end,
    }
    list:setItems(allItems)
    list.header:toggleColumn('name')

    -- Change and update UI
    elements.root:hide()

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
                    size = v2(elements.add_effects_size[1], titleHeight),
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

    add_effect_ui._closeListPopup = I.UIToolkit.Popups.show {
        body = layout,
    }
end

function add_effect_ui.update()
    if elements.add_effects_root.created then
        elements.add_effects_root:update()
        elements.magic_effects_list:set_input_text()
    end
end

return add_effect_ui
