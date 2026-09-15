local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local ui = require("openmw.ui")
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local async = require('openmw.async')

local enchanter = require("scripts.enchanting_ui.enchanter")
local elements = require("scripts.enchanting_ui.ui.elements")
local templates = require("scripts.enchanting_ui.templates") -- only for padding rn
local customize_effect_ui = require("scripts.enchanting_ui.ui_toolkit.customize_effect_ui")
local magic_effects_ui = require("scripts.enchanting_ui.ui_toolkit.magic_effects_ui")

local T  = I.UIToolkit.Templates

local current_effects_ui = {}
local current_effects_ui_size = {500, 200}
local rowHeight = 25
local effects_padding = 5

-- Responsible for the current effects list and the add effect button

local ColumnItem = require 'scripts.UIToolkit.components.list_items.column_item'
---@class CurrentEffectsListData : UIToolkit.ListData.Column
---@field effect_text string
---@field cost number


local textSize   = I.UIToolkit.getTheme().Sizes.textNormal
local rowHeight  = 1.5 * (textSize + 2)

local provider = ColumnItem:new()
provider:init({
    { id = 'icon',   render = ColumnItem.renderIcon, width = 1.5 * rowHeight},
    { id = 'text',   render = ColumnItem.renderText, width = 375},
    { id = 'cost',   render = ColumnItem.renderText, arg = { textAlignH = ui.ALIGNMENT.End }, align = ui.ALIGNMENT.End, width = 1.5 * rowHeight },
    { id = 'effect_id',   render = ColumnItem.renderIcon, width = 0}
}, rowHeight)


function current_effects_ui.generate_effect_item(wnd, effect_to_add, index)
    print("current_effects_ui for effect: ", effect_to_add.id)

    local icon = core.magic.effects.records[effect_to_add.id].icon

    local effect_id = effect_to_add.id

    local cost = effect_to_add.cost

    local name = tostring(core.magic.effects.records[effect_to_add.id].name)
    print("Name: ", name)

    local parts = { name }

    if core.magic.effects.records[effect_to_add.id].hasSkill then
        table.insert(parts, effect_to_add.affectedSkill)
    end

    if core.magic.effects.records[effect_to_add.id].hasAttribute then
        table.insert(parts, effect_to_add.affectedAttribute)
    end

    if core.magic.effects.records[effect_to_add.id].hasMagnitude then
        table.insert(parts, ("%d to %d"):format(effect_to_add.magnitudeMin, effect_to_add.magnitudeMax))
    end

    if core.magic.effects.records[effect_to_add.id].hasDuration and enchanter.enchantment.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        table.insert(parts, ("for %d sec"):format(effect_to_add.duration))
    end
    
    if effect_to_add.range ~= core.magic.RANGE.Self and effect_to_add.area > 0 then
        table.insert(parts, ("in %d ft"):format(effect_to_add.area))
    end

    print("range is: ", tostring(effect_to_add.range))
    if effect_to_add.range == core.magic.RANGE.Self then
        table.insert(parts, "on Self")
        print("range is: on Self" )
    elseif effect_to_add.range == core.magic.RANGE.Target then
        table.insert(parts, "on Target")
        print("range is: on Target" )
    else 
        table.insert(parts, "on Touch")
        print("range is: on Touch" )
    end

    local text = table.concat(parts, " ")
    print("text: ", text)

    return {
        id = index,
        icon = icon,
        text = text,
        cost = cost,
        effect_id = effect_id,
    }
end


current_effects_ui.clear_effects = function(effects_list)
    print("clear_effects")
    enchanter.reset_effect_to_add()
    
    effects_list:setItems({})
end

current_effects_ui.regen_effects = function(effects_list)
    print("regen effects")
    
    local new_effect_elements = {}
    for index, effect in ipairs(enchanter.effects_with_params) do
        local effect_element = current_effects_ui.generate_effect_item(wnd, effect, index)
        table.insert(new_effect_elements, effect_element)
    end
    
    effects_list:setItems()
    
end

---@param wnd EnchantingHandler
current_effects_ui.create_effect_ui = function(wnd)
    local theme = I.UIToolkit.getTheme()


    function wnd:add_effect()
        print("wnd:add_effect, adding", enchanter.effect_to_add.id )

        local effect_element = current_effects_ui.generate_effect_item(wnd, enchanter.effect_to_add, #enchanter.effects_with_params + 1)

        local current_effect_elements = wnd.effects_list:getItems()
        table.insert(current_effect_elements, effect_element)
        wnd.effects_list:setItems(current_effect_elements)

        table.insert(enchanter.effects_with_params, enchanter.effect_to_add)
    end

    function wnd:modify_effect(index)
        print("wnd:modify_effect, modifying", enchanter.effect_to_add.id )
        print("index: ", index)

        local effect_element = current_effects_ui.generate_effect_item(wnd, enchanter.effect_to_add, index)

        local current_effect_elements = wnd.effects_list:getItems()
        current_effect_elements[index] = effect_element
        wnd.effects_list:setItems(current_effect_elements)

         enchanter.effects_with_params[index] = enchanter.effect_to_add -- replace existing entry
    end

    local add_effect_btn = I.UIToolkit.Components.textButton { text = "Add Effect", scrollWidth = 1, slimScroll = true, onClick = function()
        magic_effects_ui.show_add_effect_list(wnd)
    end}
    add_effect_btn:updateProps{
        anchor = v2(1, 0),      relativePosition = v2(1, 0),
    }

    local effects_list_title = ui.create { template = T.text(), props = { text = 'Effects', textSize = textSize+5, anchor = v2(0,0), relativePosition = v2(0,0)} }
    local effects_list = I.UIToolkit.Components.itemList {
        size = v2(current_effects_ui_size[1], current_effects_ui_size[2] - (textSize+8)),
        provider = provider,
        onItemClicked = function(data)
            print("On current effect clicked: ", data.effect_id)
            print("On current effect clicked: ", data.id)
            customize_effect_ui.show_customize_effect_ui(wnd, data.effect_id, true, data.id)
        end,
    }
    wnd.effects_list = effects_list

    effects_list:updateProps{
        anchor = v2(0, 1),
        relativePosition = v2(0, 1),
    }

    return
    {
        name = "current_effects",
        type = UI.TYPE.Widget,
        props = {
            size = v2(current_effects_ui_size[1],current_effects_ui_size[2]),
            anchor = v2(0.5, 1),
            relativePosition = v2(0.5, 1)
        },
        content = UI.content {
            effects_list_title,
            add_effect_btn.element,
            effects_list.element,
        }
    }
end

return current_effects_ui