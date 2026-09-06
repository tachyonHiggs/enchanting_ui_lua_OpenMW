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

local current_effects_ui = {}
local current_effects_ui_size = {500, 200}
local rowHeight = 25
local effects_padding = 5

-- Responsible for the current effects list and the add effect button

local ColumnItem = require 'scripts.UIToolkit.components.list_items.column_item'
---@class CurrentEffectsListData : UIToolkit.ListData.Column
---@field effect_text string
---@field cost number

---@type UIToolkit.SortedList.Column[]
local columns = {
    {
        id = 'icon',
        render = ColumnItem.renderIcon,
        width = rowHeight + 10,
    },
    {
        id = 'text',
        name = 'Effect', --TODO: add L10N
        auto = 10,
        sort = {},
        render = ColumnItem.renderText,

    },
    {
        id = 'cost',
        name = 'Cost', --TODO: add L10N
        auto = 3,
        sort = { numeric = true },
        render = ColumnItem.renderText,
        arg = { textAlignH = ui.ALIGNMENT.End },
        align = ui.ALIGNMENT.End,
    },
}

-- TODO: move this to be in enchanting_UI or subscript
current_effects_ui.on_effect_clicked = function(index)
    print("On current effect clicked: ", id)
    customize_effect_ui.on_effect_clicked(true, index, function() elements.root:hide() end)
end

---@return CurrentEffectsListData[]
current_effects_ui.generate_effect_items = function()

    for index, effect in ipairs(enchanter.effects_with_params) do
        local effect_element = customize_effect_ui.create_effect_item(effect)
        -- elements.effects:update_item(index, effect_element)
    end
        
    -- Update base cost
    enchanter.enchantment.base_cost = enchanter.get_effects_total_base_cost()
    elements.set_stats_enchantment()
    
    -- Udpate chance since base_cost changed
    enchanter.chance = enchanter.get_success_rate()
    elements.set_chance()

    -- Update effective cost
    enchanter.enchantment.effective_cost = enchanter.get_effective_cost()
    elements.set_stats_charge()
    
    -- Update count max, but don't show it
    elements.count_input:set_max_min(enchanter.get_count_max(), nil)
    
    -- Update price
    if elements.is_vendor then
        enchanter.calculate_price()
        elements.set_price()
    end

end

current_effects_ui.create_effect_ui = function( on_add_effect_clicked )
    local theme = I.UIToolkit.getTheme()

    local add_effect_btn = I.UIToolkit.Components.textButton { text = "Add Effect", onClick = function()
        if on_add_effect_clicked then
            on_add_effect_clicked()
        end
    end}
    add_effect_btn:updateProps {
        anchor = v2(1, 0),
        relativePosition = v2(1, 0),
    }

    local effects_list = I.UIToolkit.Components.sortedList {
        size = v2(current_effects_ui_size[1], current_effects_ui_size[2]),
        columns = columns,
        rowHeight = rowHeight,
        onItemClicked = function(data)
            current_effects_ui.on_effect_clicked(data.id)
        end,
    }

    return
    {
        name = "current_effects",
        type = UI.TYPE.Widget,
        props = {
            size = v2(current_effects_ui_size[1],current_effects_ui_size[2]+35),
            anchor = v2(0.5, 0),
            relativePosition = v2(0.5, 0)
        },
        content = UI.content {
            -- List
            add_effect_btn.element,
            effects_list.element,
        }
    }
end

return current_effects_ui