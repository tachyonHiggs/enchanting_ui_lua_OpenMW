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

local function on_effect_clicked() end

enchanting_ui.create_ui = function() 

    print("create_ui")

    enchanter.reset()

    elements.root = UI.create{
        name = "root",
        layer = "Windows",
        type = UI.TYPE.Widget,
        template = nil,
        props = {
            size = v2(700, 500),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content { 
            templates.make_border(v2(700, 500)),
            {
                name = "root_padding",
                template = I.MWUI.templates.padding,
                props = {
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                    size = v2(700, 500),
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
    enchanter.enchantment.cost = 0
    enchanter.effects_with_params = {}
    enchanter.enchantment.isAutocalc = 0
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
            elements.name_input,
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
                    items_ui.item_input,
                    templates.padding(10, 0),
                    souls_ui.soul_input,
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
            elements.stats_chance:create()
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
            templates.padding(10, 0),
            elements.price:create(),
            templates.padding(200, 0),
            templates.button("Create", (function()
                print("Clicked Create")
                ambient.playSound('menu click')
                enchanting_ui.enchant_item()
                return true
            end), 80, 30),
            templates.padding(10, 0),
            templates.button("Cancel", (function()
                print("Clicked Cancel")
                ambient.playSound('menu click')
                enchanter.reset()   -- Clean up enchanter
                enchanting_ui.hide()
            end), 80, 30),
            templates.padding(10, 0),
        }
    } }
}
-- End footer

enchanting_ui.show = function()
    print("Menu Show")
    enchanting_ui.create_ui()
    elements.root:update()
end

-- TODO: fix this
enchanting_ui.hide = function()
    print("Menu Hide")
    auxUi.deepDestroy(elements.root)
    elements.root:update()
    I.UI.removeMode('EnchantingDialog')
end

enchanting_ui.enchant_item = function()
    print("enchant_item")
    enchanter.enchant_item()
end

return enchanting_ui