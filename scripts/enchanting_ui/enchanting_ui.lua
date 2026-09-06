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

local enchanter = require("scripts.enchanting_ui.enchanter")
local templates = require("scripts.enchanting_ui.templates")
-- local elements = require("scripts.enchanting_ui.ui.elements")
local items_ui = require("scripts.enchanting_ui.ui_toolkit.items_ui")
local souls_ui = require("scripts.enchanting_ui.ui_toolkit.souls_ui")
-- local tooltips_text = require("scripts.enchanting_ui.ui.tooltips_text")
-- local customize_effect_ui = require("scripts.enchanting_ui.ui_toolkit.customize_effect_ui")
local magic_effects_ui = require("scripts.enchanting_ui.ui_toolkit.magic_effects_ui")

-- TODO: tooltips hovering
local enchanting_ui = {}
local windowId = 'enchanting_ui'
local statsId = 'stats_ui'

local ui_development = true

local input_image_size = {75, 75}
local current_effects_size = {525, 200}

---@class Handler: UIToolkit.WindowHandler
local Handler = Class(WindowHandler)

---@class currentEffectListData : UIToolkit.ListData.Column
---@field name string
---@field enchant_pts number
---@field type string
---@field count number
---@field item userdata
---@
function Handler:onOpened(wnd, _, saved)

    -- Inputs
    local item_input = templates.text_image.new("Item:", v2(input_image_size[1], input_image_size[2]), 10, items_ui.show_items_list, nil, nil, {anchor = v2(0, 0), relativePosition = v2(0.05,0)})
    local soul_input = templates.text_image.new("Soul:", v2(input_image_size[1], input_image_size[2]), 10, souls_ui.show_soul_list, nil, nil, {anchor = v2(1, 0), relativePosition = v2(0.95,0)})
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

    local input_content = {item_input:create(),
        templates.flex({name_input.element, type_input.element}, "inputs_vert", false, UI.ALIGNMENT.Center, UI.ALIGNMENT.Center, 10, 10, nil, v2(0.5, 0.5), v2(0.5, 0.5)), 
        soul_input:create()
    }
    local inputs = templates.flex(input_content, "inputs_horz", true, UI.ALIGNMENT.Center, UI.ALIGNMENT.Center, 10, 10, nil, v2(0.5, 0.5), v2(0.5, 0.5))

    -- Effects
    local add_effect_btn = I.UIToolkit.Components.textButton { text = "Add Effect", tooltip = 'Add a new', onClick = function()
        magic_effects_ui.show_add_effect_list()
    end}
    add_effect_btn:updateProps({anchor = v2(1,0), relativePosition = v2(1,0)})
    
    local effects = {
        name = "effects_menu",
        type = UI.TYPE.Widget,
        props = {
            size = v2(current_effects_size[1], current_effects_size[2] + 35),
            anchor = v2(0.5, 0),
            relativePosition = v2(0.5, 0)
        },
        content = UI.content {
            -- elements.effects:create(),
            add_effect_btn.element,
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
            }
        }
    })

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

    -- local main_menu = {
    --     name = "main_menu",
    --     type = UI.TYPE.Widget,
    --     props = {
    --         size = v2(elements.main_menu_size[1], elements.main_menu_size[2]),
    --     },
    --     content = UI.content {
    --         templates.make_border(v2(elements.main_menu_size[1], elements.main_menu_size[2]), 1),
    --         templates.flex({
    --             templates.flex({elements.cast_once:create(), elements.cast_on_strike:create(), elements.cast_on_use:create(), elements.constant:create()}, "cast_types", true, UI.ALIGNMENT.Center, UI.ALIGNMENT.Start, 1, 10, nil, v2(0.5, 1), v2(0.5, 1)),
    --             {
    --                 name = "effects_menu",
    --                 type = UI.TYPE.Widget,
    --                 props = {
    --                     size = v2(elements.mc_effects_size[1],elements.mc_effects_size[2]+35),
    --                     anchor = v2(0.5, 0),
    --                     relativePosition = v2(0.5, 0)
    --                 },
    --                 content = UI.content {
    --                     elements.effects:create(),
    --                     enchanting_ui.add_effect_btn:create(),
    --                 }
    --             },
    --             {
    --                 name = "footer",
    --                 type = UI.TYPE.Widget,
    --                 props = {
    --                     size = v2(elements.main_menu_size[1], 40),
    --                     anchor = v2(0.5, 0),
    --                     relativePosition = v2(0.5, 0)
    --                 },
    --                 content = UI.content {
    --                     elements.count_input:create(),
    --                     enchanting_ui.create_btn:create(),
    --                     enchanting_ui.cancel_btn:create(),
    --                 }
    --             },
    --         }, "main_flex", false, UI.ALIGNMENT.Center, UI.ALIGNMENT.Start, 10, 10, nil, v2(0.5, 0), v2(0.5, 0)),
    --     }
    -- }

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

    -- local content = templates.flex({main_menu, stats_panel}, "content", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 10, 10, nil, v2(0.5, 0.5), v2(0.5, 0.5))

    -- local props = {
    --     relativeSize = v2(1,1),
    --     anchor = v2(0.5, 0.5),
    --     relativePosition = v2(0.5, 0.5),
    -- }

    -- elements.cast_once:disable()
    -- elements.cast_on_strike:disable()
    -- elements.cast_on_use:disable()
    -- elements.constant:disable()

    -- elements.root = templates.window.new("root_window", UI.TYPE.Widget, 0, props, {content})
    -- elements.root:create()

    print("Created UI")
end

-- -- All Effects
-- elements.effects = templates.list.new("Effects", v2(elements.mc_effects_size[1],elements.mc_effects_size[2]), nil, function() end, nil, {visible = true, anchor = v2(0, 0), relativePosition = v2(0,0.05)})

-- elements.count_input = templates.slider.new("Count", 1, 1, 1, function() if elements.root.created then elements.root:update() end end, function(value) print("setting item count to: ", value) enchanter.item.count = value end, function() end, 55, 30, 140, v2(0,1), v2(0.05,1))

-- -- All Outputs
-- enchanting_ui.create_btn = templates.button.new("Create", (function() print("Clicked Create") enchanting_ui.enchant_item() return true end), 80, 30, nil, nil, {anchor = v2(1,1), relativePosition = v2(0.80, 1)})
-- enchanting_ui.cancel_btn = templates.button.new("Cancel", (function() print("Clicked Cancel") enchanting_ui.hide() end), 80, 30, nil, nil, {anchor = v2(1,1), relativePosition = v2(0.95, 1)})

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
    enchanting_ui.reset()

    enchanting_ui.destroy()
end

-- enchanting_ui.enchant_item = function()
--     print("enchant_item")

--     ambient.playSound('menu click')

--     local icons_to_reset = enchanter.enchant_item(elements.is_vendor)

--     -- Now handle updating UI elements depending on enchanting success
--     if icons_to_reset >= 1 then
--         elements.soul_input:reset_image()
--         elements.set_stats_charge()
--     end
--     if icons_to_reset >= 2 then
--         enchanting_ui.reset()
--     end

-- end

enchanting_ui.destroy = function()
    print("enchanting_ui.destroy")

    local windows = I.UIToolkit.WindowManager
    -- windows.close(statsId)
    windows.close(windowId)

    -- elements.root:destroy()
    -- if magic_effects_ui.closePopup then
    --     magic_effects_ui.closePopup()
    -- end
    -- if customize_effect_ui.closePopup then
    --     customize_effect_ui.closePopup()
    -- end
    -- if elements.items_root.created then
    --     elements.items_root:destroy()
    -- end
    -- if elements.souls_root.created then
    --     elements.souls_root:destroy()
    -- end
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

enchanting_ui.reset = function()
    print("enchanting_ui.reset")
    
    enchanter.reset()

    -- elements.count_input:hide()

    -- elements.name_input:clear()
    -- elements.soul_input:reset_image()
    -- elements.item_input:reset_image()

    -- elements.set_stats_enchantment()
    -- elements.set_stats_charge()

    -- elements.set_chance()
    -- elements.set_price()

    -- elements.effects:clear()
end

return enchanting_ui