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
local effect_ui = require("scripts.enchanting_ui.ui.effect_ui")
local souls_ui = require("scripts.enchanting_ui.ui.souls_ui")
local items_ui = require("scripts.enchanting_ui.ui.items_ui")

-- TODO: tooltips hovering

--
local enchanting_ui = {}
local header = {element = {}}
local footer = {element = {}}
local main_content = {element = {}}

local title = {
    name = "title",
    type = UI.TYPE.Text,
    template = I.MWUI.templates.textNormal,
    props = {
        text = "Enchanting Menu",
        textSize = elements.text_size,
        size = v2(elements.root_size[1],elements.text_size),
        autoSize = false,
        textAlignH = UI.ALIGNMENT.Center,
        textAlignV = UI.ALIGNMENT.Center,
    },
}

enchanting_ui.create_ui = function() 

    print("create_ui")

    local v2_size = v2(elements.root_size[1], elements.root_size[2])

    elements.root = UI.create{
        name = "root",
        layer = "Windows",
        type = UI.TYPE.Widget,
        template = nil,
        props = {
            size = v2_size,
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content{ 
            templates.make_border(v2_size, 0.75),
            {
                name = "root_padding",
                type = UI.TYPE.Container, -- Here for disabling the UI, since works with this template
                template = I.MWUI.templates.padding,
                props = {
                    -- anchor = v2(0.5, 0.5),
                    -- relativePosition = v2(0.5, 0.5),
                    size = v2_size,
                },
                content = UI.content { 
                    {
                        name = "flex_V1",
                        type = UI.TYPE.Flex,
                        props = {
                            horizontal = false,
                            arrange = UI.ALIGNMENT.Start,
                            align = UI.ALIGNMENT.Start,
                        },
                        content = UI.content {
                            title,
                            templates.padding(0, 1),
                            header,
                            main_content,
                            footer,
                        }
                    }
                }
            }
        }
    }
    
    print("Created UI")
end

local function toggle_cast_type()
    print("toggle_cast_type")

    ambient.playSound('menu click')

    -- TODO: have this toggle update magic effects, for now just clear them
    enchanter.enchantment.base_cost = 0
    enchanter.chance = 0
    enchanter.enchantment.effective_cost = 0
    enchanter.effects_with_params = {}
    enchanter.enchantment.isAutocalc = true
    elements.effects:clear()
    
    elements.set_cast_type()
    elements.set_stats_enchantment()
    elements.set_chance()
    elements.root:update()
end

-- header

local function inputs()
    print("inputs") 
    local input_elements = templates.flex({elements.item_input:create(), elements.soul_input:create()}, "inputs_flex_2", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 0, v2(elements.header_elements_size[1], elements.header_elements_size[2]))
    
    return templates.flex({elements.name_input:create(), input_elements}, "inputs_flex", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 0, 10, v2(elements.header_elements_size[1], elements.header_elements_size[2]))
end

local function stats()
    return templates.flex({elements.stats_enchantment:create(), elements.stats_charge:create()}, "stats_flex", false, UI.ALIGNMENT.End, UI.ALIGNMENT.Start, 0, 10, v2(elements.header_elements_size[1], elements.header_elements_size[2]))
end

header = templates.flex({inputs(), stats()}, "header_flex", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 0, v2(elements.header_size[1], elements.header_size[2]))

-- End header


-- main_content

elements.magic_effects = templates.list.new("Magic Effects", v2(elements.mc_magic_effects_size[1],elements.mc_magic_effects_size[2]), nil, effect_ui.make_magic_effects_list)
elements.effects = templates.list.new("Effects", v2(elements.mc_effects_size[1],elements.mc_effects_size[2]), nil, function() end)
main_content = templates.flex({elements.magic_effects:create(), elements.effects:create()}, "content_flex", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 0, v2(elements.mc_size[1], elements.mc_size[2]))

-- End main_content


-- footer

elements.cast_type_btn = templates.button.new("Cast Once", toggle_cast_type, 140, 30)

local create_btn = templates.button.new("Create", (function() print("Clicked Create") enchanting_ui.enchant_item() return true end), 80, 30)
local cancel_btn = templates.button.new("Cancel", (function() print("Clicked Cancel") ambient.playSound('menu click') enchanting_ui.hide() end), 80, 30)

footer = templates.flex({elements.cast_type_btn:create(), elements.chance:create(), elements.price:create(), templates.padding(20, elements.footer_size[2]), create_btn:create(), cancel_btn:create()}, "footer_flex", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 0, v2(elements.footer_size[1], elements.footer_size[2]))

-- End footer

enchanting_ui.show = function(is_vendor, vendor)
    print("Menu Show")

    elements.is_vendor = is_vendor
    print("is_vendor_enchant", elements.is_vendor)
    if is_vendor then
        print("Vendor is: ", vendor)
        enchanter.vendor = vendor
    end

    if not elements.is_vendor then
        elements.price:hide()
        elements.chance:show()
    else
        elements.chance:hide()
        elements.price:show()
    end
    
    elements.set_cast_type() -- Make sure to set this to be valid type

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

enchanting_ui.update_lists = function()
    print("update_lists")
    elements.magic_effects:regenerate_items()

    elements.souls_list:regenerate_items()
    elements.items_list:regenerate_items()
end

enchanting_ui.destroy = function()
    print("enchanting_ui.destroy")
    
    enchanting_ui.hide()

    auxUi.deepDestroy(elements.root)
    if elements.effects_root.layout then
        auxUi.deepDestroy(elements.effects_root)
        elements.effects_root:update()
    end
    if elements.items_root.layout then
        auxUi.deepDestroy(elements.items_root)
        elements.items_root:update()
    end
    if elements.souls_root.layout then
        auxUi.deepDestroy(elements.souls_root)
        elements.souls_root:update()
    end
    
    elements.root:update()
end

enchanting_ui.reset = function()
    print("enchanting_ui.reset")
    
    enchanter.reset()

    elements.name_input:clear()
    elements.soul_input:reset_image()
    elements.item_input:reset_image()

    elements.set_stats_enchantment()
    elements.set_stats_charge()

    elements.set_chance()
    elements.set_price()

    elements.effects:clear()
    elements.magic_effects:clear()
    enchanting_ui.update_lists()
end

return enchanting_ui