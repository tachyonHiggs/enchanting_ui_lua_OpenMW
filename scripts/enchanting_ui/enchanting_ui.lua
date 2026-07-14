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

local is_vendor_enchant = false

local function on_effect_clicked() end

enchanting_ui.create_ui = function(is_vendor_enchant_bool) 

    print("create_ui")
    is_vendor_enchant = is_vendor_enchant_bool

    elements.root = UI.create{
        name = "root",
        layer = "Windows",
        type = UI.TYPE.Widget,
        template = nil,
        props = {
            size = v2(800, 600),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content{ 
            templates.make_border(v2(800, 600)),
            {
                name = "root_padding",
                template = I.MWUI.templates.padding,
                props = {
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                    size = v2(800, 600),
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

    -- TODO: have this toggle update magic effects, for now just clear them
    enchanter.soul.charge = 0
    enchanter.enchantment.base_cost = 0
    enchanter.enchantment.effective_cost = 0
    enchanter.effects_with_params = {}
    enchanter.enchantment.isAutocalc = true
    elements.effects:clear()
    elements.root:update()
    
    elements.cast_type_btn.content[2].props.text = enchanter.toggle_cast_type()
end

-- header

local function inputs()
    print("inputs")

                    
    return {
        name = "inputs_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            size = v2(300,50),
        },
        content = UI.content {
            elements.name_input:create(),
            templates.padding(10, 0),
            {
                name = "item_soul_flex",
                type = UI.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = UI.ALIGNMENT.Start,
                    align = UI.ALIGNMENT.Start,
                },
                content = UI.content {
                    elements.item_input:create(),
                    templates.padding(10, 0),
                    elements.soul_input:create(),
                }
            },
            templates.padding(10, 0),
        }
    }
end


local function stats()
    return {
        name = "stats_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            -- gap = 10,
        },
        content = UI.content {
            elements.stats_enchantment:create(),
            elements.stats_charge:create(),
        }
    }
end

header = {
    name = "header",
    template = I.MWUI.templates.padding,
    content = UI.content { {
        name = "header_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            -- gap = 20,
        },
        content = UI.content {
            templates.padding(20, 0),
            inputs(),
            stats(),
            templates.padding(20, 0),
        }
    } }
}

-- End header



-- main_content

main_content = {
    name = "content",
    template = I.MWUI.templates.padding,
    content = UI.content { {
        name = "content_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            -- gap = 20,
        },
        content = UI.content {
            templates.padding(10, 0),
            elements.magic_effects:create(),
            templates.padding(10, 0),
            elements.effects:create(),
            templates.padding(10, 0),
        }
    } }
}
-- End main_content



-- footer

elements.cast_type_btn = templates.button("Cast Once", toggle_cast_type, 140, 30)

footer = {
    name = "footer",
    template = I.MWUI.templates.padding,
    content = UI.content { {
        name = "footer_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            templates.padding(10, 0),
            elements.cast_type_btn,
            templates.padding(50, 0),
            elements.chance:create(),
            templates.padding(10, 0),
            elements.price:create(),
            templates.padding(200, 0),
            templates.button("Create", (function()
                print("Clicked Create")
                enchanting_ui.enchant_item()
                return true
            end), 80, 30),
            templates.padding(10, 0),
            templates.button("Cancel", (function()
                print("Clicked Cancel")
                ambient.playSound('menu click')
                enchanting_ui.hide()
            end), 80, 30),
            templates.padding(10, 0),
        }
    } }
}

if not is_vendor_enchant then
    elements.price:hide()
else
    elements.chance:hide()
end
-- End footer

enchanting_ui.show = function()
    print("Menu Show")
    enchanting_ui.create_ui()
    elements.root:update()
end

-- TODO: fix this
enchanting_ui.hide = function()
    print("Menu Hide")

    I.UI.removeMode('EnchantingDialog')
    if not is_vendor_enchant then
        I.UI.setMode("Interface")
    else 
        -- TODO: this to dialog
        I.UI.setMode("Interface")
    end
    
    -- Reset
    enchanting_ui.reset()

end

enchanting_ui.enchant_item = function()
    print("enchant_item")

    ambient.playSound('menu click')

    local icons_to_reset = enchanter.enchant_item()

    -- Now handle updating UI elements depending on enchanting success
    if icons_to_reset >= 1 then
        elements.soul_input:reset_image()
        elements.stats_charge:set_text("0")
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

    elements.stats_enchantment:set_text("0/0")
    elements.stats_charge:set_text("0/0")

    elements.chance:set_text("0")
    elements.price:set_text("0")

    elements.effects:clear()
    elements.magic_effects:clear()
end

return enchanting_ui