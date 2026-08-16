local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local auxUi = require("openmw_aux.ui")
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local async = require('openmw.async')
local core = require('openmw.core')
local types = require('openmw.types')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")
local elements = require("scripts.enchanting_ui.ui.elements")
local add_effect_ui = require("scripts.enchanting_ui.ui.add_effect_ui")
local items_ui = require("scripts.enchanting_ui.ui.items_ui")
local souls_ui = require("scripts.enchanting_ui.ui.souls_ui")
local tooltips_text = require("scripts.enchanting_ui.ui.tooltips_text")

-- TODO: tooltips hovering

local enchanting_ui = {}

local title = {
    name = "title",
    type = UI.TYPE.Text,
    template = I.MWUI.templates.textNormal,
    props = {
        text = "Enchanting Menu",
        textSize = elements.text_size,
        size = v2(elements.main_menu_size[1],elements.text_size),
        autoSize = false,
        textAlignH = UI.ALIGNMENT.Center,
        textAlignV = UI.ALIGNMENT.Center,
    },
}

enchanting_ui.create_ui = function() 

    print("create_ui")


    local main_menu = {
        name = "main_menu",
        type = UI.TYPE.Widget,
        props = {
            size = v2(elements.main_menu_size[1], elements.main_menu_size[2]),
        },
        content = UI.content {
            templates.make_border(v2(elements.main_menu_size[1], elements.main_menu_size[2]), 1),
            templates.flex({
                title,
                {
                    name = "inputs_menu",
                    type = UI.TYPE.Widget,
                    props = {
                        size = v2(elements.mc_effects_size[1], elements.input_image_size[2] + 20),
                        anchor = v2(0.5, 0),
                    },
                    content = UI.content {
                        elements.item_input:create(),
                        -- elements.cast_type_btn:create(),
                        templates.flex({elements.cast_once:create(), elements.cast_on_strike:create(), elements.cast_on_use:create(), elements.constant:create()}, "cast_types", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 1, 1, nil, v2(0.5, 1), v2(0.5, 1)),
                        -- templates.flex({}, "cast_2_types", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 1, 1, nil, v2(0.5, 1), v2(0.5, 1)),
                        elements.name_input:create(),
                        elements.soul_input:create(),
                    }
                },
                templates.padding(10,10),
                {
                    name = "effects_menu",
                    type = UI.TYPE.Widget,
                    props = {
                        size = v2(elements.mc_effects_size[1],elements.mc_effects_size[2]+35)
                    },
                    content = UI.content {
                        elements.effects:create(),
                        enchanting_ui.add_effect_btn:create(),
                    }
                },
                templates.flex({elements.count_input:create(), templates.padding(60,1), enchanting_ui.create_btn:create(), enchanting_ui.cancel_btn:create()}, "footer_flex", true, UI.ALIGNMENT.End, UI.ALIGNMENT.End, 10, 10, v2(elements.main_menu_size[1] - 20, 40), v2(0, 1), v2(0, 1)),
            }, "main_flex", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 10, nil, v2(0, 0), v2(0, 0)),
        }
    }

    local stats_panel = {
        name = "stats_panel",
        type = UI.TYPE.Widget,
        props = {
            size = v2(elements.stats_panel_size[1], elements.stats_panel_size[2])
        },
        content = UI.content {
            templates.make_border(v2(elements.stats_panel_size[1], elements.stats_panel_size[2]), 1),
            elements.create_stats(),
        }
    }

    local content = templates.flex({main_menu, stats_panel}, "content", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 10, nil, v2(0.5, 0.5), v2(0.5, 0.5))

    local props = {
        relativeSize = v2(1,1),
        anchor = v2(0.5, 0.5),
        relativePosition = v2(0.5, 0.5),
    }

    print("Disabling cast once")
    elements.cast_once:disable()

    elements.root = templates.window.new("root_window", UI.TYPE.Widget, 0, props, {content})
    elements.root:create()

    print("Created UI")
end

-- All Inputs
elements.name_input = templates.text_input.new("Name:", 200, function(text) enchanter.name = text end, function() elements.root:update() end, tooltips_text.name_input, elements.tooltip, {anchor = v2(0.5, 0), relativePosition = v2(0.5, 0.25)})
elements.item_input = templates.text_image.new("Item:", v2(elements.input_image_size[1],elements.input_image_size[2]), 10, items_ui.show_item_list, nil, nil, {anchor = v2(0, 0), relativePosition = v2(0,0)})
elements.soul_input = templates.text_image.new("Soul:", v2(elements.input_image_size[1],elements.input_image_size[2]), 10, souls_ui.show_soul_list, nil, nil, {anchor = v2(1, 0), relativePosition = v2(1,0)})
elements.cast_type_btn = templates.button.new("Cast Once", elements.set_cast_type, 140, 30, tooltips_text.cast_type_btn, elements.tooltip, {anchor = v2(0.5, 1), relativePosition = v2(0.5, 1)})

elements.cast_once = templates.button.new("Cast Once", elements.set_cast_type, 70, 25, tooltips_text.cast_type_btn, elements.tooltip, nil, 15)
elements.cast_on_strike = templates.button.new("Cast on Strike", elements.set_cast_type, 100, 25, tooltips_text.cast_type_btn, elements.tooltip, nil, 15)
elements.cast_on_use = templates.button.new("Cast on Use", elements.set_cast_type, 100, 25, tooltips_text.cast_type_btn, elements.tooltip, nil, 15)
elements.constant = templates.button.new("Constant", elements.set_cast_type, 70, 25, tooltips_text.cast_type_btn, elements.tooltip, nil, 15)

-- All Effects
enchanting_ui.add_effect_btn = templates.button.new("Add Effect", add_effect_ui.show_add_effect_list, 105, 30, tooltips_text.add_effect_btn, elements.tooltip, {anchor = v2(1,0), relativePosition = v2(1,0)})
elements.effects = templates.list.new("Effects", v2(elements.mc_effects_size[1],elements.mc_effects_size[2]), nil, function() end, nil, {visible = true, anchor = v2(0, 0), relativePosition = v2(0,0.05)})

elements.count_input = templates.slider.new("Count", 1, 1, 1, function() if elements.root.created then elements.root:update() end end, function(value) print("setting item count to: ", value) enchanter.item.count = value end, function() end, 55, 30, 140)

-- All Outputs
enchanting_ui.create_btn = templates.button.new("Create", (function() print("Clicked Create") enchanting_ui.enchant_item() return true end), 80, 30)
enchanting_ui.cancel_btn = templates.button.new("Cancel", (function() print("Clicked Cancel") ambient.playSound('menu click') enchanting_ui.hide() end), 80, 30)

-- Helper functions

enchanting_ui.show = function(is_vendor, vendor, used_soul_gem)
    print("Menu Show")

    elements.is_vendor = is_vendor
    print("is_vendor_enchant", elements.is_vendor)
    if is_vendor then
        enchanter.vendor = vendor
    end
    
    elements.set_cast_type() -- Make sure to set this to be valid type

    if not elements.is_vendor then
        elements.price:hide()
        elements.chance:show()

        -- set player selected soul gem
        local soul = types.Item.itemData(used_soul_gem).soul
        local soul_charge = types.Creature.records[soul].soulValue
        local icon = used_soul_gem.type.records[used_soul_gem.recordId].icon
        souls_ui.on_soul_clicked(used_soul_gem.recordId, used_soul_gem, soul_charge, icon)
    else
        elements.chance:hide()
        elements.price:show()
    end

    elements.root:update()
end

-- TODO: fix this
enchanting_ui.hide = function()
    print("Menu Hide")

    I.UI.removeMode('EnchantingDialog')
    print("is_vendor_enchant", elements.is_vendor)
    if not elements.is_vendor then
        I.UI.setMode("Interface")
    else 
        -- TODO: this to dialog
        I.UI.setMode("Dialogue")
    end

    enchanter.is_vendor_enchant = false
    enchanter.vendor = {}
    
    -- Reset
    enchanting_ui.reset()

end

enchanting_ui.enchant_item = function()
    print("enchant_item")

    ambient.playSound('menu click')

    local icons_to_reset = enchanter.enchant_item(elements.is_vendor)

    -- Now handle updating UI elements depending on enchanting success
    if icons_to_reset >= 1 then
        elements.soul_input:reset_image()
        elements.set_stats_charge()
    end
    if icons_to_reset >= 2 then
        enchanting_ui.reset()
    end

    elements.root:update()
end

enchanting_ui.destroy = function()
    print("enchanting_ui.destroy")
    
    enchanting_ui.hide()

    elements.root:destroy()
    if elements.add_effects_root.created then
        elements.add_effects_root:destroy()
    end
    if elements.effects_root.created then
        elements.effects_root:destroy()
    end
    if elements.items_root.created then
        elements.items_root:destroy()
    end
    if elements.souls_root.created then
        elements.souls_root:destroy()
    end
    if elements.tooltip.visible then
        elements.tooltip:destroy()
    end
    
    elements.root:update()
end

enchanting_ui.reset = function()
    print("enchanting_ui.reset")
    
    enchanter.reset()

    elements.count_input:hide()

    elements.name_input:clear()
    elements.soul_input:reset_image()
    elements.item_input:reset_image()

    elements.set_stats_enchantment()
    elements.set_stats_charge()

    elements.set_chance()
    elements.set_price()

    elements.effects:clear()
end

return enchanting_ui