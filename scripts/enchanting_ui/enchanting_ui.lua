---@omw-context player

local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local storage = require('openmw.storage')


local Class         = require 'scripts.UIToolkit.class'
local WindowHandler = require 'scripts.UIToolkit.window_handler'
local T  = I.UIToolkit.Templates


local enchanter = require("scripts.enchanting_ui.enchanter")
local templates = require("scripts.enchanting_ui.templates")
local items_ui = require("scripts.enchanting_ui.ui_toolkit.items_ui")
local souls_ui = require("scripts.enchanting_ui.ui_toolkit.souls_ui")

local customize_effect_ui = require("scripts.enchanting_ui.ui_toolkit.customize_effect_ui")
local magic_effects_ui = require("scripts.enchanting_ui.ui_toolkit.magic_effects_ui")
local current_effects_ui = require("scripts.enchanting_ui.ui_toolkit.current_effects_ui")

local enchanting_ui = {}
local windowId = 'enchanting_ui'

local input_image_size = v2(50, 50)
local main_width = 575
local outputs_width = 525
local stats_width = 150
local window_height = 430

---@class EnchantingHandler: UIToolkit.WindowHandler
local Handler = Class(WindowHandler)

local function makeIconLayout()
    return {
        template = T.border { padding = 4 },
        props = { size = input_image_size },
        content = UI.content { {
            type = UI.TYPE.Image,
            props = {
                resource = nil,
                relativeSize = v2(1, 1)
            },
        } },
    }
end

local function reset_type_input(type_input)
    type_input:setItems { -- These will be overwritten once an item is selected
        { id = core.magic.ENCHANTMENT_TYPE.CastOnce,        text = "Cast Once" },
        { id = core.magic.ENCHANTMENT_TYPE.CastOnStrike,    text = "Cast on Strike" },
        { id = core.magic.ENCHANTMENT_TYPE.CastOnUse,       text = "Cast on Use" },
        { id = core.magic.ENCHANTMENT_TYPE.ConstantEffect,  text = "Constant Effect" },
    }
    type_input:setDisabled(true)
end

function Handler:onOpened(wnd, _, saved)
    -- Inputs
    self.type_input = {}
    local item_icon_input = I.UIToolkit.Interactive.makeInteractive({
        onClick = function() items_ui.show_items_list(self) end,
        tooltip = function ()
            local item = enchanter.item and enchanter.item.object
            if not item then return 'Select Item' end
            return {object = item}
        end,
    }, makeIconLayout())
    self.itemInput = item_icon_input

    local item_input = templates.flex({{ template = T.text(), props = { text = 'Item:' } }, item_icon_input}, "item_input", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 5, 5)
    

    local soul_icon_input = I.UIToolkit.Interactive.makeInteractive({
        onClick = function() souls_ui.show_soul_list(self) end,
        tooltip = function ()
            local soul = enchanter.soul and enchanter.soul.object
            if not soul then return 'Select Soul Gem' end
            return {object = soul}
        end,
    }, makeIconLayout())
    self.soulInput = soul_icon_input
    local soul_input = templates.flex({{ template = T.text(), props = { text = 'Soul:' } }, soul_icon_input}, "soul_input", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 5, 5)
    
    local name_input = I.UIToolkit.Components.textEdit {
        placeholder = 'Enchanted Item Name',
        onValueChanged = function(value) enchanter.name = value end,
        showClearButton = true,
        width = 300,
    }
    
    local function on_type_clicked(new_type)

        if new_type == enchanter.enchantment.type then
            print("New type is current type")
            return
        end
        enchanter.enchantment.type = new_type
        -- This includes a check if the type is constant effect    
        enchanter.item.enchantment_capacity = enchanter.item.default_enchantment_capacity * enchanter.scale_enchantment_capacity_factor_from_soul_charge()

        self:updateUI()
    end

    self.type_input = I.UIToolkit.Components.dropbox { -- Default is this guys is disabled
        items = { -- These will be overwritten once an item is selected
            { id = core.magic.ENCHANTMENT_TYPE.CastOnce,        text = "Cast Once" },
            { id = core.magic.ENCHANTMENT_TYPE.CastOnStrike,    text = "Cast on Strike" },
            { id = core.magic.ENCHANTMENT_TYPE.CastOnUse,       text = "Cast on Use" },
            { id = core.magic.ENCHANTMENT_TYPE.ConstantEffect,  text = "Constant Effect" },
        },
        onItemSelected = function(item, index)
            print('Type:', item.text, 'Id:', item.id)
            on_type_clicked( item.id)
        end,
    }

    if not enchanter.is_vendor then
        self.price_or_chance_stat_text = "Chance: "
        self.price_or_chance_stat_value = enchanter.chance .. " %"
        self.price_or_chance_stat_tooltip = {body = 'The success rate of the Enchantment in percentage.'}

        local soul = types.Item.itemData(enchanter.used_soul_gem).soul
        local soul_charge = types.Creature.records[soul].soulValue
        local icon = enchanter.used_soul_gem.type.records[enchanter.used_soul_gem.recordId].icon

        souls_ui.on_soul_clicked(enchanter.used_soul_gem.recordId, enchanter.used_soul_gem, soul_charge, icon)
        -- self:setSoul(enchanter.used_soul_gem)
        self.soulInput.layout.content[1].props.resource = I.UIToolkit.texture(icon)

    else
        self.price_or_chance_stat_text = "Cost: "
        self.price_or_chance_stat_value = enchanter.price
        self.price_or_chance_stat_tooltip = {body = 'The Cost of the Enchantment service'}
        
    end

    self.price_or_chance_stat = I.UIToolkit.Interactive.makeInteractive({
        tooltip = self.price_or_chance_stat_tooltip,
    }, {
        template = I.MWUI.templates.textNormal,
        props = {
            text = self.price_or_chance_stat_text..self.price_or_chance_stat_value,
            textAlignH = UI.ALIGNMENT.Start,
            anchor = v2(0,1),
            relativePosition = v2(0,1),
            position = v2(0,0),
        },
        userData = { colorable = true, },
    })

    self.enchantment_pts_stat = I.UIToolkit.Interactive.makeInteractive({
        tooltip = {body = 'Determines the max enchantment an item can hold. Stronger effects require more points. Any of the "Soul Charge to Enchantment Capacity factor" settings will modify this number, as shown in the format: current points (base points)', arrange = UI.ALIGNMENT.Start},
    }, {
        template = I.MWUI.templates.textNormal,
        props = {
            text = " Max: 0",
            textAlignH = UI.ALIGNMENT.Start,
            anchor = v2(0,1),
        },
        userData = { colorable = true, },
    })
    self.enchantment_pts_used_stat = I.UIToolkit.Interactive.makeInteractive({
        tooltip = {body = "The total base cost of the enchantment, must be less than both the Item's Enchantment Capacity and the Soul's Charge in order to work"},
    }, {
        template = I.MWUI.templates.textNormal,
        props = {
            text = " Used: 0",
            textAlignH = UI.ALIGNMENT.Start,
            anchor = v2(0,1),
        },
        userData = { colorable = true, },
    })

    self.soul_charge_stat = I.UIToolkit.Interactive.makeInteractive({
        tooltip = {body = 'The Charge of the selected Soul Gem. This determines the max possible base enchantment and the number of uses a user can get out of the item.'},
    }, {
        template = I.MWUI.templates.textNormal,
        props = {
            text = " Charge: 0",
            textAlignH = UI.ALIGNMENT.Start,
            anchor = v2(0,1),
        },
        userData = { colorable = true, },
    })
    self.soul_uses_stat = I.UIToolkit.Interactive.makeInteractive({
        tooltip = {body = "The number of uses the user can get out of this item and enchantment. This is based on the soul gem's charge, the user's skill, and the enchantment's base skill."},
    }, {
        template = I.MWUI.templates.textNormal,
        props = {
            text = " Uses: 0",
            textAlignH = UI.ALIGNMENT.Start,
            anchor = v2(0,1),
        },
        userData = { colorable = true, },
    })

    -- TODO: if Skyrim like enchanting enabled
    self.enchanting_skill_stat = {}
    enchanter.skyrim_like_enchanting = storage.globalSection("options_enchanting_ui"):get("skyrim_like_enchanting")
    if enchanter.skyrim_like_enchanting then
        self.enchanting_skill_mod_stat = I.UIToolkit.Interactive.makeInteractive({
            tooltip = {body = "The percentage the magnitude, duration, and/or area the output enchantment will actually be. This is determined off user enchanting skill, and enchant skill modifiers only contribute 1/4 as much as the base skill."},
        }, {
            template = I.MWUI.templates.textNormal,
            props = {
                text = " Modifier: +0%",
                textAlignH = UI.ALIGNMENT.Start,
                anchor = v2(0,1),
            },
            userData = { colorable = true, },
        })
        table.insert(self.enchanting_skill_stat, { template = T.header(),    props = { text = 'Enchantment Skill' } })
        table.insert(self.enchanting_skill_stat, self.enchanting_skill_mod_stat)
        
    end

    local stats = {
        name = "stats_widget",
        type = UI.TYPE.Widget,
        props = {
            size = v2(stats_width+10, window_height-65),
        },
        content = UI.content {
            {
                name = "stats_flex",
                type = UI.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = UI.ALIGNMENT.Start,
                    align = UI.ALIGNMENT.Start,
                    autoSize = true,
                    anchor = v2(0, 0),
                    relativePosition = v2(0, 0),
                    visible = true,
                },
                content = UI.content {
                    { template = T.header(),    props = { text = 'Enchantment Points' } },
                    self.enchantment_pts_stat,
                    self.enchantment_pts_used_stat,
                    { template = T.text(),    props = { text = '' } },

                    { template = T.header(),    props = { text = 'Soul Charge' } },
                    self.soul_charge_stat,
                    self.soul_uses_stat,
                    { template = T.text(),    props = { text = '' } },

                    table.unpack(self.enchanting_skill_stat)
                }
            },
            self.price_or_chance_stat
        }
    }

    local input_content = {item_input,
        {
            type = UI.TYPE.Flex,
            props = {
                horizontal = false,
                arrange = UI.ALIGNMENT.Start,
                align = UI.ALIGNMENT.Start,
                autoSize = true,
                anchor = v2(0.5, 1),
                relativePosition = v2(0.5, 1),
                visible = true,
            },
            content = UI.content {
                name_input.element,
                {template = T.padding(5)},
                self.type_input.element,
                {template = T.padding(3)},
            }
        },
        soul_input
    }
    local inputs = templates.flex(input_content, "inputs_horz", true, UI.ALIGNMENT.End, UI.ALIGNMENT.Center, 10, 0, nil, v2(0.5, 0.5), v2(0.5, 0.5))

    -- Effects
    
    local effects = {
        name = "effects",
        type = UI.TYPE.Flex,
        props = {
            autoSize = true,
            anchor = v2(0.5, 0),
            relativePosition = v2(0.5, 0)
        },
        content = UI.content {
            current_effects_ui.create_effect_ui(self)
        }
   }
    
    self.count_value = I.UIToolkit.Components.textButton { text = "0", width = 35, canClick = false, style = 'thin', thickness = 0, background = 'transparent'}
    self.count = I.UIToolkit.Components.scrollBar {
        horizontal = true,
        length = 100,
        scrollStep = 1,
        maxScroll = 0,
        onScroll = function(position)
            local value = math.floor(position) + 1
            self.count_value:setText(tostring(value))
            enchanter.enchantment.count_to_enchant = value
        end,
    }
    local count_text = { template = T.text(), props = { text = 'Count: ' } }
    local count_input = {
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            anchor = v2(0, 1),
            relativePosition = v2(0, 1),
            position = v2(20, -3),
            arrange = UI.ALIGNMENT.End,
            align = UI.ALIGNMENT.End,
            autoSize = true,
            visible = true,
        },
        content = UI.content {
            count_text,
            self.count_value.element, 
            self.count.element
        }
    }

    -- Reset count slider
    self.count:setDisabled(true)
    self.count_value:setText("0")

    ambient.playSound('menu click')

    local function enchant_item()
        local icons_to_reset = enchanter.enchant_item(enchanter.is_vendor, enchanter.skyrim_like_enchanting)

        -- Now handle updating UI elements depending on enchanting success
        if icons_to_reset >= 1 then
            self.soulInput.layout.content[1].props.resource = I.UIToolkit.texture("black")
            I.UIToolkit.queueUpdate(self.soulInput)
        end
        if icons_to_reset >= 2 then
            self.itemInput.layout.content[1].props.resource = I.UIToolkit.texture("black")
            I.UIToolkit.queueUpdate(self.itemInput)
            name_input:setValue('')
           
            -- clear effects
            enchanter.reset()

            reset_type_input(self.type_input)
            
            enchanter.give_player_xp(enchanter.is_vendor, true) -- give player xp on enchant success
        elseif icons_to_reset >= 1 then
            enchanter.give_player_xp(enchanter.is_vendor, false) -- if setting, give player xp on enchant fail
        end
        
        self:updateUI()

        if icons_to_reset >= 2 then
            -- Reset count slider
            self.count:setDisabled(true)
            self.count_value:setText("0")
        end
        
    end
    local create_btn = I.UIToolkit.Components.textButton { text = "Create", onClick = enchant_item, background = 'transparent'}
    create_btn:updateProps({anchor = v2(1,1), relativePosition = v2(1,1), position = v2(-100, 1)})
    local cancel_btn = I.UIToolkit.Components.textButton { text = "Cancel", onClick = function()  I.UI.removeMode('Enchanting') end, background = 'transparent'}
    cancel_btn:updateProps({anchor = v2(1,1),  relativePosition = v2(1,1), position = v2(-25, 1)})
    local outputs = {
        name = "outputs",
        type = UI.TYPE.Widget,
        props = {
            size = v2(outputs_width, 50),
            anchor = v2(0.5, 1),
            relativePosition = v2(0.5, 1)
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
                horizontal = true,
                arrange = UI.ALIGNMENT.Start,
                align = UI.ALIGNMENT.Start,
                autoSize = true,
                visible = true,
            },
            content = UI.content {
                {
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
                        {template = T.padding(5)},
                        effects,
                        outputs,
                    }
                },
                
                {template = T.padding(3)},
                
                {
                    type = UI.TYPE.Flex,
                    props = {
                        horizontal = false,
                    },
                    content = UI.content {
                        { template = T.header(),    props = { text = 'Statistics' } },
                        {
                            template = T.box { style = 'thin', padding = 5, background = 'tranent' },
                            content = UI.content {
                                stats
                            },
                        },
                        {template = T.padding(5)},
                    }
                },
            }
        }

    })

    self.type_input:setDisabled(true)

    self:updateUI()

    Handler:onResized(wnd:getInnerSize())
end

function Handler:onClosed()
end

---@param inner openmw.util.Vector2
function Handler:onResized(inner)

end

-- These will be overwritten by the current_effect_UI
function Handler:add_effect()
end
function Handler:modify_effect(index)
end
function Handler:remove_effect(index)
end
Handler.effects_list = {}

---@param item openmw.Object
function Handler:setItem(item)
    local record = item.type.records[item.recordId]
    self.itemInput.layout.content[1].props.resource = I.UIToolkit.texture(record.icon)

    self.count:setDisabled(false) -- only used if item type is weapon ammo
     
    self.type_input:setDisabled(false) -- Enable type input

    local types_supported = {}
    if enchanter.item_supports_cast_once() then
        table.insert(types_supported, { id = core.magic.ENCHANTMENT_TYPE.CastOnce, text = "Cast Once" })
    end
    if enchanter.item_supports_cast_on_strike() then
        table.insert(types_supported, { id = core.magic.ENCHANTMENT_TYPE.CastOnStrike,    text = "Cast on Strike" })
    end
    if enchanter.item_supports_cast_on_use() then
        table.insert(types_supported, { id = core.magic.ENCHANTMENT_TYPE.CastOnUse,       text = "Cast on Use" })
    end
    if enchanter.item_supports_constant() then
        table.insert(types_supported, { id = core.magic.ENCHANTMENT_TYPE.ConstantEffect,  text = "Constant Effect" })
    end
    self.type_input:setItems(types_supported)

    if #types_supported <= 0 then
        print("CRITICAL ERROR: no valid enchantment types for this item")
        return
    end
    enchanter.enchantment.type = types_supported[1].id

    self.effects_list:setItems({}) -- enchanter effects cleared in items_ui file

    self:updateUI()

    I.UIToolkit.queueUpdate(self.itemInput)
end

---@param item openmw.Object
function Handler:setSoul(item)
    local record = item.type.records[item.recordId]
    self.soulInput.layout.content[1].props.resource = I.UIToolkit.texture(record.icon)
    
    self:updateUI()

    I.UIToolkit.queueUpdate(self.soulInput)
end

function Handler:updateUI()

    -- first get and regen effects
    self.effects_list:setItems(self.effects_list:getItems())
    current_effects_ui.regen_effects(self) -- To update effect cost by index or any other changes
    
    -- Then Base/effective cost
    enchanter.enchantment.base_cost = enchanter.get_effects_total_base_cost()
    enchanter.enchantment.effective_cost = enchanter.get_effective_cost()

    -- Then Item count
    local max = enchanter.get_count_max()
    self.count:setMaxScroll((max-1))
    enchanter.enchantment.count_to_enchant = math.min(max, enchanter.enchantment.count_to_enchant)
    self.count:setPosition((enchanter.enchantment.count_to_enchant-1), true) -- Seems that setPosition does not call on scroll?
    self.count_value:setText(tostring(enchanter.enchantment.count_to_enchant))
    
    -- Now update UI
    -- Update price or Chance
    if enchanter.is_vendor then
        enchanter.price = enchanter.calculate_price()
        self.price_or_chance_stat.layout.props.text = self.price_or_chance_stat_text..string.format("%.1f", enchanter.price)
        I.UIToolkit.queueUpdate(self.price_or_chance_stat)
    else
        if enchanter.skyrim_like_enchanting then
            enchanter.chance = 100
        else
            enchanter.chance = enchanter.get_success_rate()
        end
        
        self.price_or_chance_stat.layout.props.text = self.price_or_chance_stat_text..string.format("%.1f", enchanter.chance).." %"
        I.UIToolkit.queueUpdate(self.price_or_chance_stat)
    end

    local enchantment_pts_value = (string.format("%.1f", enchanter.item.enchantment_capacity))
    if enchanter.item.enchantment_capacity ~= enchanter.item.default_enchantment_capacity then
        enchantment_pts_value = (string.format("%.1f", enchanter.item.enchantment_capacity) .. " (" .. string.format("%.1f", enchanter.item.default_enchantment_capacity)..")")
    end
    self.enchantment_pts_stat.layout.props.text = " Max: ".. enchantment_pts_value
    I.UIToolkit.queueUpdate(self.enchantment_pts_stat)
    self.enchantment_pts_used_stat.layout.props.text = " Used: "..(string.format("%.1f", enchanter.enchantment.base_cost))
    I.UIToolkit.queueUpdate(self.enchantment_pts_used_stat)

    -- Soul gem stats
    self.soul_charge_stat.layout.props.text = " Charge: "..(string.format("%.1f", enchanter.soul.charge))
    I.UIToolkit.queueUpdate(self.soul_charge_stat)

    local uses = 0
    if enchanter.enchantment.effective_cost ~= 0 then -- Some effects are in. To avoid infinite
        uses = enchanter.soul.charge/enchanter.enchantment.effective_cost
        uses = (string.format("%.0f", uses))
    end
    if enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
        uses = "1"
    elseif enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        uses = "Constant"
    end
    self.soul_uses_stat.layout.props.text = " Uses: "..uses
    I.UIToolkit.queueUpdate(self.soul_uses_stat)

    if enchanter.skyrim_like_enchanting then
        self.enchanting_skill_mod_stat.layout.props.text = " Modifier: +"..(string.format("%.0f", enchanter.get_enchant_skill_modifier())).."%"
        I.UIToolkit.queueUpdate(self.enchanting_skill_mod_stat)
    end
end

I.UIToolkit.WindowManager.register(windowId, {
    title = 'Enchanting',
    handler = Handler,
    draggable = true,
    resizing = true,
    position = v2(600, 600), -- TODO: this value
    minSize = v2(main_width+stats_width, window_height),
})

enchanting_ui.show = function(is_vendor, vendor, used_soul_gem)
    print("Menu Show")
    enchanter.reset()

    enchanter.is_vendor = is_vendor
    print("is_vendor_enchant", enchanter.is_vendor)
    if is_vendor then
        enchanter.vendor = vendor
    else
        enchanter.used_soul_gem = used_soul_gem
    end

    local windows = I.UIToolkit.WindowManager
    windows.open(windowId)
end

enchanting_ui.hide = function()
    print("Menu Hide")

    enchanter.is_vendor_enchant = false
    enchanter.vendor = {}
    
    -- Reset
    enchanter.reset()

    enchanting_ui.destroy()
end

enchanting_ui.destroy = function()

    local windows = I.UIToolkit.WindowManager
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
end

return enchanting_ui