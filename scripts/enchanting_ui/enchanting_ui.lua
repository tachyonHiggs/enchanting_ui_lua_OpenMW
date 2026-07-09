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
local add_effect_ui = require("scripts.enchanting_ui.add_effect_ui")
local elements = require("scripts.enchanting_ui.enchanting_ui_elements")

local ui_helpers = require("scripts.enchanting_ui.ui_helpers")

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
                            header.element,
                            main_content.element,
                            footer.element,
                        }
                    }
                }
           }
        }
    }
    enchanting_ui.root = elements.root
    
    print("Created UI")
end

local function toggle_cast_type()
    print("toggle_cast_type")

    -- TODO: have this toggle update magic effects, for now just clear them
    enchanter.soul.charge = 0
    enchanter.enchantment.cost = 0
    enchanter.effects_with_params = {}
    enchanter.enchantment.isAutocalc = 0
    add_effect_ui.effects:clear()
    enchanting_ui.root:update()
    
    enchanting_ui.cast_type_btn.content[2].props.text = enchanter.toggle_cast_type()
end

-- header

-- header input list fncs
enchanting_ui.souls_list = templates.list.new("Souls", v2(600, 500), ui_helpers.make_souls_list)
enchanting_ui.items_list = templates.list.new("Items", v2(600, 500), ui_helpers.make_enchantable_items_list)

local function on_item_clicked(id, icon, enchant_pts, type_text)

    enchanter.item.id = id
    enchanter.item.icon = icon
    enchanter.item.type = type_text
    enchanter.item.enchantment_capacity = enchant_pts
    print("click on item: ", id)
    print("Icon: ", icon)
    print("Type: ", type_text)
    print("enchant_pts: ", tostring(enchant_pts))
    enchanting_ui.item_input.content[3].props.resource = UI.texture({
        path = icon
    })

    -- TODO: reset stuff here
    
    enchanter.enchantment.type = 0
    enchanting_ui.cast_type_btn.content[2].props.text = "Cast Once"
    elements.stats_enchantment:set_text(tostring(enchanter.enchantment.cost).."/"..tostring(enchanter.item.enchantment_capacity))
    toggle_cast_type()
    enchanting_ui.root:update()

    auxUi.deepDestroy(enchanting_ui.item_list)
    enchanting_ui.item_list:update()
end

local function show_item_list()

    ui_helpers.set_on_item_clicked(on_item_clicked)
    print("CREATING ITEM UI")

    enchanting_ui.item_list = UI.create{
        name = "item_list",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            enchanting_ui.items_list:create()
        }
    }
end

local function on_soul_clicked(id, value, icon)

    enchanter.soul.id = id
    enchanter.soul.icon = icon
    enchanter.soul.charge = value
    elements.stats_charge:set_text(tostring(enchanter.enchantment.cost).. "/".. tostring(enchanter.soul.charge ))
    
    print("click on soul: ", id)
    print("at icon: ", icon)
    print("with a soul value of: ", value)
    enchanting_ui.soul_input.content[3].props.resource = UI.texture({
        path = icon
    })
    enchanting_ui.root:update()

    auxUi.deepDestroy(enchanting_ui.soul_list)
    enchanting_ui.soul_list:update()

end

local function show_soul_list()

    ui_helpers.set_on_soul_clicked(on_soul_clicked)
    print("CREATING SOUL UI")

    enchanting_ui.soul_list = UI.create{
        name = "souls_list",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            enchanting_ui.souls_list:create()
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
            elements.stats_enchantment:create(),
            elements.stats_charge:create(),
            elements.stats_chance:create()
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
            add_effect_ui.magic_effects:create(),
            templates.padding(10, 0),
            add_effect_ui.effects:create(),
            templates.padding(10, 0),
        }
    } }
}
-- End main_content



-- footer

enchanting_ui.cast_type_btn = templates.button("Cast Once", toggle_cast_type, 140, 30)
enchanting_ui.price = templates.text_output.new("Price:", 100, 10, "0", UI.ALIGNMENT.End)

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
            enchanting_ui.price:create(),
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
    enchanting_ui.root:update()
end

-- TODO: fix this
enchanting_ui.hide = function()
    print("Menu Hide")
    auxUi.deepDestroy(enchanting_ui.root)
    enchanting_ui.root:update()
    I.UI.removeMode('EnchantingDialog')
end

enchanting_ui.enchant_item = function()
    print("enchant_item")
    enchanter.enchant_item()
end

return enchanting_ui