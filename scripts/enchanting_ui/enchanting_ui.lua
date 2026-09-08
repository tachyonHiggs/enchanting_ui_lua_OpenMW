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

local Class         = require 'scripts.UIToolkit.class'
local WindowHandler = require 'scripts.UIToolkit.window_handler'
local H             = require 'scripts.UIToolkit.helpers'
local tipUtils      = require 'scripts.UIToolkit.tooltips.utils'
local T  = I.UIToolkit.Templates

local enchanter = require("scripts.enchanting_ui.enchanter")
local templates = require("scripts.enchanting_ui.templates")
-- local elements = require("scripts.enchanting_ui.ui.elements")
local items_ui = require("scripts.enchanting_ui.ui_toolkit.items_ui")
local souls_ui = require("scripts.enchanting_ui.ui_toolkit.souls_ui")

local customize_effect_ui = require("scripts.enchanting_ui.ui_toolkit.customize_effect_ui")
local magic_effects_ui = require("scripts.enchanting_ui.ui_toolkit.magic_effects_ui")
local current_effects_ui = require("scripts.enchanting_ui.ui_toolkit.current_effects_ui")

-- TODO: tooltips hovering
local enchanting_ui = {}
local windowId = 'enchanting_ui'
local statsId = 'stats_ui'

local ui_development = true

local input_image_size = {75, 75}
local current_effects_size = {525, 200}

---@class Handler: UIToolkit.WindowHandler
local Handler = Class(WindowHandler)

function Handler:onOpened(wnd, _, saved)
    
    -- Inputs
    local item_icon = {
        template = I.MWUI.templates.borders,
        type = UI.TYPE.Image,
        props = {
            resource = UI.texture {path = 'black'},
            size = v2(input_image_size[1], input_image_size[2]),
        },
        userData = { colorable = true, },
    }
    local item_icon_input = I.UIToolkit.Interactive.makeInteractive({
        onClick = function() items_ui.show_items_list(item_icon.props.resource) end,
        tooltip = 'Hello World!',
    }, item_icon)
    local item_input = templates.flex({{ template = T.text(), props = { text = 'Item:' } }, item_icon_input}, "item_input", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 5, 5)
    
    local soul_icon = {
        template = I.MWUI.templates.borders,
        type = UI.TYPE.Image,
        props = {
            resource = UI.texture {path = 'black'},
            size = v2(input_image_size[1], input_image_size[2]),
        },
        userData = { colorable = true, },
    }
    local soul_icon_input = I.UIToolkit.Interactive.makeInteractive({
        onClick = function() souls_ui.show_soul_list(soul_icon.props.resource) end,
        tooltip = 'Hello World!',
    }, item_icon)
    local soul_input = templates.flex({{ template = T.text(), props = { text = 'Soul:' } }, soul_icon_input}, "soul_input", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 5, 5)
    
    local name_input = I.UIToolkit.Components.textEdit {
        placeholder = 'Enchanted Item Name',
        onValueChanged = function(value) print('Value changed:', value) enchanter.name = value end,
        showClearButton = true,
        width = 300,
    }
    
    local function on_type_clicked(new_type)

        if new_type == enchanter.enchantment.type then
            print("New type is current tyep")
            return
        end
        enchanter.enchantment.type = new_type
        -- This includes a check if the type is constant effect    
        enchanter.item.enchantment_capacity = enchanter.item.default_enchantment_capacity * enchanter.scale_enchantment_capacity_factor_from_soul_charge()

        -- Update current effects if type changes
        -- TODO: this
        -- magic_effects_ui.regen_effect_items()

        -- elements.root:update()
    end
    local type_input = I.UIToolkit.Components.dropbox {
        items = {
            { id = core.magic.ENCHANTMENT_TYPE.CastOnce,        text = "Cast Once" },
            { id = core.magic.ENCHANTMENT_TYPE.CastOnStrike,    text = "Cast on Strike" },
            { id = core.magic.ENCHANTMENT_TYPE.CastOnUse,       text = "Cast on Use" },
            { id = core.magic.ENCHANTMENT_TYPE.ConstantEffect,  text = "Constant Effect" },
        },
        onItemSelected = function(item, index)
            print('Difficulty:', item.text, 'Index:', index)
            on_type_clicked(index)
        end,
    }

    if not enchanting_ui.is_vendor then
        -- elements.price:hide()
        -- elements.chance:show()

        -- -- set player selected soul gem
        -- local soul = types.Item.itemData(used_soul_gem).soul
        -- local soul_charge = types.Creature.records[soul].soulValue
        -- local icon = used_soul_gem.type.records[used_soul_gem.recordId].icon
        -- souls_ui.on_soul_clicked(used_soul_gem.recordId, used_soul_gem, soul_charge, icon)
    else
        -- elements.chance:hide()
        -- elements.price:show()
    end

    local input_content = {item_input,
        templates.flex({name_input.element, type_input.element}, "inputs_vert", false, UI.ALIGNMENT.Center, UI.ALIGNMENT.Center, 10, 10, nil, v2(0.5, 0.5), v2(0.5, 0.5)), 
        soul_input
    }
    local inputs = templates.flex(input_content, "inputs_horz", true, UI.ALIGNMENT.Center, UI.ALIGNMENT.Center, 10, 10, nil, v2(0.5, 0.5), v2(0.5, 0.5))

    -- Effects
    
    local effects = {
        name = "effects",
        type = UI.TYPE.Widget,
        props = {
            size = v2(current_effects_size[1], current_effects_size[2] + 35),
            anchor = v2(0.5, 0),
            relativePosition = v2(0.5, 0)
        },
        content = UI.content {
            current_effects_ui.create_effect_ui()
        }
    }

    local count = I.UIToolkit.Components.scrollBar {
        horizontal = true,
        length = 250,
        handleSize = 20,
        scrollStep = 2,
        maxScroll = 198,
        onScroll = function(position)
            local value = math.floor(position / 2) + 1
            print('Value:', value)
        end,
    }
    local count_text = { template = T.text(), props = { text = 'Count' } }
    local count_input = templates.flex({count_text, count.element}, "count", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 10, nil, v2(0, 1), v2(0.05, 1))
    count_input.props.visible = false

    print("enchant_item")

    ambient.playSound('menu click')

    local function enchant_item()
        local icons_to_reset = enchanter.enchant_item(enchanting_ui.is_vendor)

        -- Now handle updating UI elements depending on enchanting success
        if icons_to_reset >= 1 then
            soul_input:reset_image()
            -- elements.set_stats_charge()
        end
        if icons_to_reset >= 2 then
            enchanting_ui.reset()
            -- TODO: clear all inputs and stuff
           item_input:reset_image()
           name_input:setValue('')
           -- clear effects
           -- clear effect to add
           enchanter.reset()
        end
    end
    local create_btn = I.UIToolkit.Components.textButton { text = "Create", onClick = enchant_item}
    create_btn:updateProps({anchor = v2(1,1), relativePosition = v2(0.80,1)})
    local cancel_btn = I.UIToolkit.Components.textButton { text = "Cancel", onClick = enchanting_ui.hide}
    cancel_btn:updateProps({anchor = v2(1,1), relativePosition = v2(0.95,1)})
    local outputs = {
        name = "outputs",
        type = UI.TYPE.Widget,
        props = {
            size = v2(current_effects_size[1], 35),
            anchor = v2(0.5, 0),
            relativePosition = v2(0.5, 0)
        },
        content = UI.content {
            count_input,
            create_btn.element,
            cancel_btn.element,
        }
    }
    
    wnd:setContent(UI.content {
        {
            name = "main_flex",
            type = UI.TYPE.Flex,
            props = {
                horizontal = false,
                arrange = UI.ALIGNMENT.Center,
                align = UI.ALIGNMENT.Center,
                autoSize = true,
                anchor = v2(0.5, 0),
                relativePosition = v2(0.5, 0),
                visible = true,
            },
            content = UI.content {
                inputs,
                effects,
                outputs,
            }
        }
    })

    type_input:setDisabled(true)

    Handler:onResized(wnd:getInnerSize())
end

function Handler:onClosed()
    I.UI.removeMode('EnchantingDialog')
    print("is_vendor_enchant", enchanting_ui.is_vendor)
    if not enchanting_ui.is_vendor then
        I.UI.setMode("Interface")
    else 
        -- TODO: this to dialog
        I.UI.setMode("Dialogue")
    end
end

---@param inner openmw.util.Vector2
function Handler:onResized(inner)

end

I.UIToolkit.WindowManager.register(windowId, {
    title = 'Enchanting',
    handler = Handler,
    draggable = true,
    resizing = true,
    position = v2(10, 10),
    minSize = v2(575, 500),
})
I.UIToolkit.WindowManager.register(statsId, {
    title = 'Statistics',
    handler = Handler,
    draggable = true,
    resizing = true,
    position = v2(1000, 1000),
    minSize = v2(250, 100),
})
if ui_development then
    -- TODO: reset window sizes and positions
end

enchanting_ui.create = function() 

    print("create_ui")

    -- local stats_panel = {
    --     name = "stats_panel",
    --     type = UI.TYPE.Widget,
    --     props = {
    --         size = v2(elements.stats_panel_size[1], elements.stats_panel_size[2])
    --     },
    --     content = UI.content {
    --         templates.make_border(v2(elements.stats_panel_size[1], elements.stats_panel_size[2]), 1),
    --         templates.flex({
    --         {
    --             name = "title",
    --             type = UI.TYPE.Text,
    --             template = I.MWUI.templates.textNormal,
    --             props = {
    --                 text = "Statistics",
    --                 textSize = elements.title_text_size,
    --                 size = v2(elements.stats_panel_size[1],elements.title_text_size),
    --                 autoSize = false,
    --                 textAlignH = UI.ALIGNMENT.Center,
    --                 textAlignV = UI.ALIGNMENT.Start,
    --             },
    --         },
    --         elements.create_stats(),
    --         }, "stats_flex", false, UI.ALIGNMENT.Center, UI.ALIGNMENT.Start, 10, 10, nil, v2(0.5, 0), v2(0.5, 0)),
    --     }
    -- }


    print("Created UI")
end

-- -- All Effects
-- elements.count_input = templates.slider.new("Count", 1, 1, 1, function() if elements.root.created then elements.root:update() end end, function(value) print("setting item count to: ", value) enchanter.item.count = value end, function() end, 55, 30, 140, v2(0,1), v2(0.05,1))

-- Helper functions

enchanting_ui.show = function(is_vendor, vendor, used_soul_gem)
    print("Menu Show")
    enchanter.reset()

    enchanting_ui.is_vendor = is_vendor
    print("is_vendor_enchant", enchanting_ui.is_vendor)
    if is_vendor then
        enchanter.vendor = vendor
    end

    local windows = I.UIToolkit.WindowManager
    -- windows.open(statsId)
    windows.open(windowId)
end

-- TODO: fix this
enchanting_ui.hide = function()
    print("Menu Hide")

    enchanter.is_vendor_enchant = false
    enchanter.vendor = {}
    
    -- Reset
    enchanter.reset()

    enchanting_ui.destroy()
end

enchanting_ui.destroy = function()
    print("enchanting_ui.destroy")

    local windows = I.UIToolkit.WindowManager
    -- windows.close(statsId)
    windows.close(windowId)

    if magic_effects_ui.closePopup then
        magic_effects_ui.closePopup()
    end
    if customize_effect_ui.closePopup then
        customize_effect_ui.closePopup()
    end
    if items_ui.closePopup then
        items_ui.closePopup()
    end
    if souls_ui.closePopup then
        souls_ui.closePopup()
    end
    -- if elements.tooltip.visible then
    --     elements.tooltip:destroy()
    -- end
    -- if elements.skill_select_root.created then
    --     elements.skill_select_root:destroy()
    -- end
    -- if elements.attribute_select_root.created then
    --     elements.attribute_select_root:destroy()
    -- end
end

return enchanting_ui