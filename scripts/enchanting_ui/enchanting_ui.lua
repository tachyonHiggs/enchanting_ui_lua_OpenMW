local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local auxUi = require("openmw_aux.ui")
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local async = require('openmw.async')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")

local ui_helpers = require("scripts.enchanting_ui.ui_helpers")

-- TODO: tooltips hovering

--
local enchanting_ui = {}

-- header
local header = {}

local function on_item_clicked(id, icon)

    enchanter.item.id = id
    enchanter.item.icon = icon
    print("click on item: ", id)
    enchanting_ui.item_input.content[3].props.resource = UI.texture({
        path = icon
    })
    enchanting_ui.root:update()

    auxUi.deepDestroy(enchanting_ui.item_list)

end

local function show_item_list()

    ui_helpers.set_on_item_clicked(on_item_clicked)

    enchanting_ui.item_list = UI.create{
        name = "item_list",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            size = v2(300, 500),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            templates.list("Items", v2(300, 500), ui_helpers.make_enchantable_items_list)
        }
    }
end

local function on_soul_clicked(id, value, icon)

    enchanter.soul.id = id
    enchanter.soul.value = value
    enchanter.soul.icon = icon
    print(icon)

    print("click on item: ", id)
    enchanting_ui.soul_input.content[3].props.resource = UI.texture({
        path = icon
    })
    enchanting_ui.root:update()

    auxUi.deepDestroy(enchanting_ui.soul_list)

end

local function show_soul_list()

    ui_helpers.set_on_soul_clicked(on_soul_clicked)

    enchanting_ui.soul_list = UI.create{
        name = "souls_list",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            size = v2(300, 500),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            templates.list("Souls", v2(300, 500), ui_helpers.make_souls_list)
        }
    }
end

enchanting_ui.name_input = templates.text_input("Name", 200, function(text) enchanter.name = text end)
enchanting_ui.item_input = templates.text_image("Item", v2(75,75), 10, show_item_list, nil, nil)
enchanting_ui.soul_input = templates.text_image("Soul", v2(75,75), 10, show_soul_list, nil, nil)

enchanting_ui.magic_effects = templates.list("Magic Effects", v2(200,300), ui_helpers.make_magic_effects_list)
-- local effects = templates.list("Effects", v2(350,300), function() end)

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
            -- gap = 10,
        },
        content = UI.content {
            enchanting_ui.name_input,
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
                    enchanting_ui.item_input,
                    templates.padding(10, 0),
                    enchanting_ui.soul_input,
                },
                templates.padding(10, 0),
            }
        }
    }
end

local function stats()
    return{
        name = "stats_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            -- gap = 10,
        },
        content = UI.content {
            templates.text_output("Enchantment:", 200, 10, "0", UI.ALIGNMENT.End),
            -- templates.padding(10, 0),
            templates.text_output("Cast Cost:", 200, 10, "0", UI.ALIGNMENT.End),
            -- templates.padding(10, 0),
            templates.text_output("Charge:", 200, 10, "0", UI.ALIGNMENT.End),
            -- templates.padding(10, 0),
            templates.text_output("Chance:", 200, 10, "0", UI.ALIGNMENT.End),
            -- templates.padding(10, 0),
        }
    }
end

header.element = {
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
local main_content = {}

main_content.element = {
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
            enchanting_ui.magic_effects,
            templates.padding(10, 0),
            enchanting_ui.effects,
            templates.padding(10, 0),
        }
    } }
}
-- End main_content

-- footer
local footer = {}

footer.element = {
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
            templates.button("Cast Once", (function()
                print("Clicked Type")
                ambient.playSound('menu click')
                return true
            end)),
            templates.padding(10, 0),
            templates.text_output("Price", 200, 10, "0", UI.ALIGNMENT.End),
            templates.padding(200, 0),
            templates.button("Create", (function()
                print("Clicked Create")
                ambient.playSound('menu click')
                enchanting_ui.enchant_item()
                return true
            end)),
            templates.padding(10, 0),
            templates.button("Cancel", (function()
                print("Clicked Cancel")
                ambient.playSound('menu click')
                return true
            end)),
            templates.padding(10, 0),
        }
    } }
}
-- End footer

enchanting_ui.create_ui = function() 

    print("create_ui")

    enchanting_ui.root = UI.create{
        name = "root",
        layer = "Windows",
        type = UI.TYPE.Widget,
        props = {
            size = v2(600, 500),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content { 
            templates.make_border(v2(600, 500)),

            {
            name = "root_padding",
            template = I.MWUI.templates.padding,
            content = UI.content { {
                name = "flex_V1",
                type = UI.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = UI.ALIGNMENT.Start,
                    align = UI.ALIGNMENT.Start,
                },
                content = UI.content {
                    header.element,
                    main_content.element,
                    footer.element,
                }
            } }
        } }
    }
    
    print("Created UI")
end

enchanting_ui.configure_effect_popup = function()
end

enchanting_ui.show = function()
    print("Menu Show")
    enchanting_ui.create_ui()
    enchanting_ui.root:update()
end

-- TODO: fix this
enchanting_ui.hide = function()
    print("Menu Hide")
    auxUi.deepDestroy(enchanting_ui.root)
end

enchanting_ui.set_item_to_enchant = function()
    print("set_item_to_enchant")

    print(enchanter.name)
    -- enchanter.item_id = 
end

enchanting_ui.set_soul_value = function()
    print("set_soul_value")
    -- enchanter.soul_value = 
end

enchanting_ui.set_enchantment = function()
    print("set_enchantment")
    --enchanter.enchantment = 
end

enchanting_ui.calculate_chance  = function()
    print("calculate_chance")
    -- enchanter.calculate_success_rate()
end

enchanting_ui.enchant_item = function()
    print("enchant_item")

    enchanting_ui.set_item_to_enchant()
    enchanting_ui.set_soul_value()
    enchanting_ui.set_enchantment()

    enchanter.enchant_item()
end

return enchanting_ui