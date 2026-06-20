local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local async = require('openmw.async')

local templates = {}

-- Helper fncs
templates.make_border = function(size)
    return {
        template = I.MWUI.templates.bordersThick,
        type = UI.TYPE.Image,
        props = {
            resource = UI.texture({
            path = "black"
            }),
            alpha = 0.5,
            size = size,
        }
    }
end

templates.padding = function(x, y)
    return {
        props = {
            size = Util.vector2(x, y)
        }
    }
end

-- Templates
templates.button = function(name, on_click_fnc)
    return {
        name = name  .. "_btn",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = 20,
        },
        events = {
            mouseClick = async:callback(on_click_fnc)
        }
        -- Border?
    }
end

templates.text_input = function(name, text_length, on_text_changed_fnc)
    print("template.text_input")
    return {
        name = name .. "_text_input",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            {
                name =  name .. "name",
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = name,
                    textSize = 20,
            }},
            templates.padding(10, 0),
            {
                name =  name .. "input",
                type = UI.TYPE.TextEdit,
                template = I.MWUI.templates.textEditBox,
                props = {
                    text = "",
                    textSize = 20,
                    size = v2(text_length,20),
                },
                events = {
                    -- textChanged = async:callback(on_text_changed_fnc)
                }
            },
        }
    }
end

templates.text_output = function(name, text_length, padding_length, default_text, text_align_h)
    return {
        name = name .. "_text_output",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            {
                name = "name",
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = name,
                    textSize = 20,
            }},
            templates.padding(padding_length, 0),
            {
                name = "output",
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = default_text,
                    textSize = 20,
                    size = v2(text_length,20),
                    textAlignH = text_align_h, -- TODO: this does not seem to work
                }
            },
        }
    }
end

templates.text_image = function(name, image_size, padding_length, on_image_mouse_click, on_image_focus_gained, on_image_focus_loss)
    return {
        name = name .. "_text_image",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            {
                name = "name",
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = name,
                    textSize = 20,
            }},
            templates.padding(padding_length, 0),
            {
                name = "image",
                type = UI.TYPE.Image,
                template = I.MWUI.templates.bordersThick,
                props = {
                    resource = UI.texture({
                    path = "black"
                    }),
                    alpha = 0.5,
                    size = image_size,
                },
                events = {
                    -- mouseClick = async:callback(on_image_mouse_click),
                    -- focusGain = async:callback(on_image_focus_gained),
                    -- focusLoss = async:callback(on_image_focus_loss),
                }
            },
        }
    }
end

templates.list = function(name, list_size)
    return {
        name = name .. "_list",
        template = I.MWUI.templates.padding,
        content = UI.content { {
            name = "flex",
            type = UI.TYPE.Flex,
            props = {
                horizontal = false,
                arrange = UI.ALIGNMENT.Start,
                align = UI.ALIGNMENT.Start,
            },
            content = UI.content {
                {
                name = "name",
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = name,
                    textSize = 20,
                }},
                templates.make_border(list_size),
                -- TODO: add list items here
                -- Events = onUpdate and items onClick
            }
        } }
    }
end

return templates