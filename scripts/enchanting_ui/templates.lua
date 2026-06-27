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
templates.button = function(name, on_click_fnc, size)
    return {
        name = name .. "_btn_border",
        type = UI.TYPE.Container,
        template = I.MWUI.templates.bordersThick,
        props = {
            size = size
        },
        content = UI.content {
            {
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
            }
        }
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
                template = I.MWUI.templates.textEditLine,
                props = {
                    text = "",
                    textSize = 20,
                    size = v2(text_length,20),
                },
                events = {
                    textChanged = async:callback(on_text_changed_fnc)
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
                template = I.MWUI.templates.borders,
                props = {
                    resource = UI.texture({
                        path = "black"
                    }),
                    alpha = 1,
                    size = image_size,
                },
                events = {
                    mouseClick = async:callback(on_image_mouse_click),
                    -- focusGain = async:callback(on_image_focus_gained),
                    -- focusLoss = async:callback(on_image_focus_loss),
                }
            },
        }
    }
end

templates.list = function(name, list_size, generate_items)

    local items = generate_items() or {}

    return {
        name = name .. "_list",
        template = I.MWUI.templates.padding,
        content = UI.content { 
            {
                name = "flex",
                type = UI.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = UI.ALIGNMENT.Start,
                    align = UI.ALIGNMENT.Start,
                    -- gap = 10,
                    size = v2(0, 20) + list_size
                },
                content = UI.content {
                    {
                        name = "name",
                        type = UI.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = name,
                            textSize = 20,
                        }
                    },
                    {
                        name = "border",
                        template = I.MWUI.templates.boxSolid,
                        props = {
                            size = list_size,
                        }, 
                        content = UI.content {
                            {
                                name = "items",
                                type = UI.TYPE.Flex,
                                props = {
                                    horizontal = false,
                                    arrange = UI.ALIGNMENT.Start,
                                    align = UI.ALIGNMENT.Start,
                                    -- gap = 20,
                                    size = list_size
                                },
                                content = UI.content(items)
                            }
                        }
                    }
                } 
            }
        }
    }
end

templates.slider = {}

templates.slider.bar = {
    name = "bar",
    template = I.MWUI.templates.borders,
    type = UI.TYPE.Image,
    props = {
        resource = UI.texture({
            path = "Textures/menu_bar_yellow.dds" -- TODO: this withthe actual bar image
        }),
        alpha = 1,
        size = v2(20, 20),
    },
    events = {
        
    }
}


templates.slider.value = 0
templates.slider.value_text = "0"
templates.slider.value_element = {
    name = "value",
    type = UI.TYPE.Text,
    template = I.MWUI.templates.textNormal,
    props = {
        text = templates.slider.value_text,
        textSize = 20,
        size = v2(100, 20) -- tbd size
    }
}

templates.slider.move_left = function(interval, max, min) 
    print("Moving slider left")
    local relativeInterval = interval/(max-min)
    templates.slider.bar.props.relativePosition = templates.slider.bar.props.relativePosition - v2(relativeInterval, 0)
    templates.slider.value = templates.slider.value - interval

    print("moving left interval: ", interval)

    if templates.slider.value < min or templates.slider.bar.props.relativePosition < v2(0,0) then
        print("LESS THAN ", templates.slider.bar.props.relativePosition)
        print("Slider value: ", templates.slider.value)
        templates.slider.value = min
        templates.slider.bar.props.relativePosition = v2(0,0)
    end
    print("Current value: ", templates.slider.value)
    templates.slider.value_text = tostring(templates.slider.value)
    templates.slider.value_element.props.text = templates.slider.value_text
    templates.slider.update_target()
end

templates.slider.move_right = function(interval, max, min) 
    print("Moving slider right")
    local relativeInterval = interval/(max-min)
    templates.slider.bar.props.relativePosition = templates.slider.bar.props.relativePosition + v2(relativeInterval, 0)
    templates.slider.value = interval + templates.slider.value

    if templates.slider.value > max or templates.slider.bar.props.relativePosition > v2(1,0) then
        templates.slider.value = max
        templates.slider.bar.props.relativePosition = v2(1,0)
    end
    print("Current value: ", templates.slider.value_text)
    templates.slider.value_text = tostring(templates.slider.value)
    templates.slider.value_element.props.text = templates.slider.value_text
    templates.slider.update_target()
end

templates.slider.create = function(name, max, min, text_size, padding_size, bar_size, bar_start_pos, interval, update_target)

    templates.slider.bar.props.relativePosition = v2(bar_start_pos, 0)
    templates.slider.update_target = update_target

    templates.slider.value = min
    templates.slider.value_text = tostring(templates.slider.value)
    templates.slider.value_element.props.text = templates.slider.value_text

    return {
        name = name .. "_slider",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            {
                name = name  .. "_name",
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = name .. ":   ",
                    textSize = 20,
                    size = v2(text_size, 20)
                },
                content = UI.content {}
            }, 
            templates.slider.value_element,
            templates.padding(padding_size, 20),
            {
                name = "left",
                template = I.MWUI.templates.borders,
                type = UI.TYPE.Image,
                props = {
                    resource = UI.texture({
                        path = "Textures/menu_scroll_left.dds"
                    }),
                    alpha = 1,
                    size = v2(20, 20),
                },
                events = {
                    mouseClick = async:callback(function() templates.slider.move_left(interval, max, min) end)
                }
            },
            {
                name = name  .. "_background_bar",
                template = I.MWUI.templates.borders,
                type = UI.TYPE.Image,
                props = {
                    resource = UI.texture({
                        path = "black"
                    }),
                    alpha = 1,
                    size = v2(bar_size, 20),
                },
                content = UI.content {
                    templates.slider.bar
                }
            },
            {
                name = "right",
                template = I.MWUI.templates.borders,
                type = UI.TYPE.Image,
                props = {
                    resource = UI.texture({
                        path = "Textures/menu_scroll_right.dds"
                    }),
                    alpha = 1,
                    size = v2(20, 20),
                },
                events = {
                    mouseClick = async:callback(function() templates.slider.move_right(interval, max, min) end)
                }
            },
        }
    }
end

return templates