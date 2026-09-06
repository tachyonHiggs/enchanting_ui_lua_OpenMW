---@omw-context player

local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local ui = require("openmw.ui")
local ambient = require('openmw.ambient')
local core = require('openmw.core')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")
local elements = require("scripts.enchanting_ui.ui.elements")

local customize_effect_ui = {}
local rowHeight = 25

function customize_effect_ui.show_customize_effect_ui(modify_effect, index_to_modify)
    print("customize_effect_ui.show_customize_effect_ui")

    local titleHeight = math.floor(1.5 * rowHeight)
    local theme = I.UIToolkit.getTheme()

    ambient.playSound('menu click')

    local layout = {
        name = "customize_effect_ui",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = UI.content {
            {
                props = {
                    size = v2(elements.magic_effects_window_size[1], titleHeight),
                },
                content = ui.content {
                    {
                        template = I.UIToolkit.Templates.header(),
                        props = {
                            text = 'Customize Effect:',
                            textSize = theme.Sizes.textNormal + 2,
                            position = v2(5, 5),
                        },
                    },
                },
            },
        }
    }

    customize_effect_ui._closeListPopup = I.UIToolkit.Popups.show {
        body = layout,
    }
end

function customize_effect_ui.closePopup()
    if not customize_effect_ui._closeListPopup then return end
    customize_effect_ui._closeListPopup()
    customize_effect_ui._closeListPopup = nil
end

return customize_effect_ui