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

-- header input list fncs

local function on_item_clicked(id, icon)

    enchanter.item.id = id
    enchanter.item.icon = icon
    print("click on item: ", id)
    print("Icon: ", icon)
    enchanting_ui.item_input.content[3].props.resource = UI.texture({
        path = icon
    })
    enchanting_ui.root:update()

    auxUi.deepDestroy(enchanting_ui.item_list)
    enchanting_ui.item_list:update()

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
    enchanter.soul.icon = icon
    enchanter.enchantment.charge = value
    enchanting_ui.stats_charge.content[3].props.text = tostring(value)
    
    print("click on soul: ", id)
    enchanting_ui.soul_input.content[3].props.resource = UI.texture({
        path = icon
    })
    enchanting_ui.root:update()

    auxUi.deepDestroy(enchanting_ui.soul_list)
    enchanting_ui.soul_list:update()

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

enchanting_ui.stats_enchantment = templates.text_output("Enchantment:", 200, 10, "0", UI.ALIGNMENT.End)
enchanting_ui.stats_cast_cost = templates.text_output("Cast Cost:", 200, 10, "0", UI.ALIGNMENT.End)
enchanting_ui.stats_charge = templates.text_output("Charge:", 200, 10, "0", UI.ALIGNMENT.End)
enchanting_ui.stats_chance = templates.text_output("Chance:", 200, 10, "0", UI.ALIGNMENT.End)

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
            enchanting_ui.stats_enchantment,
            enchanting_ui.stats_cast_cost,
            enchanting_ui.stats_charge,
            enchanting_ui.stats_chance
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


local function update_magic_effect_add()
    enchanting_ui.magic_effect_add:update()
end
local function toggle_range_type()
    print("toggle_range_type")
    enchanting_ui.range.content[1].props.text = enchanter.toggle_range_type()
    update_magic_effect_add()
end
enchanting_ui.range = templates.button("Self", toggle_range_type, v2(100, 100))
enchanting_ui.magnitude = templates.slider.create("Magnitude", 999, 1, 100, 75, 200, 0, 1, update_magic_effect_add)

local function on_magic_effect_clicked(id)

    print("On magic effect clicked: ", id)

    enchanting_ui.magic_effect_add = UI.create{
        name = "magic_effect_add",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            size = v2(400, 300),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            templates.make_border(v2(400, 300)),
            {
                name = "magic_effect_add_flex",
                type = UI.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = UI.ALIGNMENT.Center,
                    align = UI.ALIGNMENT.Center,
                },
                content = UI.content {
                    enchanting_ui.range,
                    enchanting_ui.magnitude,
                }
            }
        }
    }
    -- enchanting_ui.root.layout.template = I.MWUI.templates.disabled

    enchanting_ui.root:update()
    enchanting_ui.magic_effect_add:update()

end

ui_helpers.set_on_magic_effect_clicked(on_magic_effect_clicked)

enchanting_ui.magic_effects = templates.list("Magic Effects", v2(200,300), ui_helpers.make_magic_effects_list)
-- local effects = templates.list("Effects", v2(350,300), function() end)

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

local function toggle_cast_type()
    print("toggle_cast_type")
    enchanting_ui.cast_type_btn.content[1].props.text = enchanter.toggle_cast_type()
    enchanting_ui.root:update()
end

enchanting_ui.cast_type_btn = templates.button("Cast Once", toggle_cast_type, v2(100, 100))

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
            enchanting_ui.cast_type_btn,
            templates.padding(10, 0),
            templates.text_output("Price", 200, 10, "0", UI.ALIGNMENT.End),
            templates.padding(200, 0),
            templates.button("Create", (function()
                print("Clicked Create")
                ambient.playSound('menu click')
                enchanting_ui.enchant_item()
                return true
            end), v2(30, 20)),
            templates.padding(10, 0),
            templates.button("Cancel", (function()
                print("Clicked Cancel")
                ambient.playSound('menu click')
                return true
            end), v2(30, 20)),
            templates.padding(10, 0),
        }
    } }
}
-- End footer

enchanting_ui.create_ui = function() 

    print("create_ui")

    enchanter.reset()

    enchanting_ui.root = UI.create{
        name = "root",
        layer = "Windows",
        -- type = UI.TYPE.Widget,
        template = nil,
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