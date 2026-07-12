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
            alpha = 0.75,
            size = size,
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
        }
    }
end

templates.padding = function(x, y)
    return {
        template = I.MWUI.templates.padding,
        type = UI.TYPE.Container,
        props = {
            size = Util.vector2(x, y),
        }
    }
end

-- Templates
templates.button = function(name, on_click_fnc, size_x, size_y)
    return {
        name = name .. "_btn_border",
        type = UI.TYPE.Container,
        template = I.MWUI.templates.bordersThick,
        props = {
            size = v2(size_x, size_y),
        },
        content = UI.content {
            templates.padding(size_x, size_y),
            {
                name = name  .. "_btn",
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = name,
                    textSize = 20,
                    size = v2(size_x, size_y),
                    autoSize = false
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

templates.text_output = {}
templates.text_output.new = function(name, text_length, padding_length, default_text, text_align_h)

    local text_output = {}

    text_output.name = name
    text_output.text = default_text or ""
    text_output.text_length = text_length
    text_output.padding_length = padding_length
    text_output.text_align_h = text_align_h or UI.ALIGNMENT.Start

    text_output.output = {
        name = "output",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = text_output.text,
            textSize = 20,
            size = v2(text_length, 20),
            textAlignH = text_output.text_align_h,
        }
    }

    function text_output:set_text(text)
        self.text = text
        self.output.props.text = text
    end

    function text_output:show()
        self.ui.props.visible = true
    end
    function text_output:hide()
        self.ui.props.visible = false
    end

    function text_output:create()
        self.ui = {
            name = self.name .. "_text_output",
            type = UI.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = UI.ALIGNMENT.Start,
                align = UI.ALIGNMENT.Start,
                visible = true,
            },
            content = UI.content {
                {
                    name = "name",
                    type = UI.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = self.name,
                        textSize = 20,
                    }
                },
                templates.padding(self.padding_length, 0),
                self.output,
            }
        }

        return self.ui
    end

    return text_output
end

-- TODO: test and implement this
-- templates.text_image = {}
-- templates.text_image.new = function(name, image_size, padding_length, on_image_mouse_click)

--     local text_image = {}

--     text_image.name = name
--     text_image.image_size = image_size
--     text_image.padding_length = padding_length
--     text_image.default_image = "black"

--     text_image.image = {
--         name = "image",
--         type = UI.TYPE.Image,
--         template = I.MWUI.templates.borders,
--         props = {
--             resource = UI.texture({
--                 path = text_image.default_image
--             }),
--             alpha = 1,
--             size = image_size,
--         },
--         events = {
--             mouseClick = async:callback(on_image_mouse_click),
--         }
--     }

--     function text_image:set_image(path)
--         self.image.props.resource = UI.texture({
--             path = path
--         })
--     end

--     function text_image:reset_image()
--         self:set_image(self.default_image)
--     end

--     function text_image:show()
--         self.ui.props.visible = true
--     end

--     function text_image:hide()
--         self.ui.props.visible = false
--     end

--     function text_image:create()
--         self.ui = {
--             name = self.name .. "_text_image",
--             type = UI.TYPE.Flex,
--             props = {
--                 horizontal = true,
--                 arrange = UI.ALIGNMENT.Start,
--                 align = UI.ALIGNMENT.Start,
--                 visible = true,
--             },
--             content = UI.content {
--                 {
--                     name = "name",
--                     type = UI.TYPE.Text,
--                     template = I.MWUI.templates.textNormal,
--                     props = {
--                         text = self.name,
--                         textSize = 20,
--                     }
--                 },
--                 templates.padding(self.padding_length, 0),
--                 self.image,
--             }
--         }

--         return self.ui
--     end

--     return text_image
-- end

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

templates.list = {}
templates.list.new = function(name, list_size, generate_items)

    -- TODO: add sorting 

    local list = {}

    list.name = name
    list.size = list_size
    list.items = generate_items() or {}

    list.items_container = {
        name = "items",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            size = list_size,
        },
        content = UI.content(list.items)
    }

    function list:add_item(item)
        print("adding item: ", item.name)
        table.insert(self.items, item)

        -- rebuild the UI content
        self.items_container.content = UI.content(self.items)
    end

    function list:remove_item(index)
        print("removing item: ", index)
        table.remove(self.items, index)

        -- rebuild the UI content
        self.items_container.content = UI.content(self.items)
    end

    function list:update_item(index, new_item)
        if not self.items[index] then
            return false
        end

        self.items[index] = new_item
        self.items_container.content = UI.content(self.items)
        return true
    end

    function list:clear()
        self.items = {}
        self.items_container.content = UI.content({})
    end

    function list:create()
        self.ui = {
            name = self.name .. "_list",
            template = I.MWUI.templates.padding,
            content = UI.content {
                {
                    name = "flex",
                    type = UI.TYPE.Flex,
                    props = {
                        horizontal = false,
                        arrange = UI.ALIGNMENT.Start,
                        align = UI.ALIGNMENT.Start,
                        size = v2(0,20) + self.size,
                    },
                    content = UI.content {
                        {
                            name = "name",
                            type = UI.TYPE.Text,
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = self.name,
                                textSize = 20,
                            }
                        },
                        {
                            name = "border",
                            template = I.MWUI.templates.boxSolid,
                            props = {
                                size = self.size,
                            },
                            content = UI.content {
                                self.items_container
                            }
                        }
                    }
                }
            }
        }        
        return self.ui
    end

    return list
end

templates.slider = {}
templates.slider.new = function(text, max, min, start, interval, update_target)
    local slider = {}

    slider.ui = {}
    slider.text = text -- sets the slider name and starting text value

    slider.value = start
    slider.value_text = tostring(slider.value)
    
    slider.min = min
    slider.max = max
    slider.interval = interval

    slider.update_target = update_target

    slider.bar = {
        name = "bar",
        template = I.MWUI.templates.borders,
        type = UI.TYPE.Image,
        props = {
            resource = UI.texture({
                path = "Textures/menu_bar_yellow.dds"
            }),
            alpha = 1,
            size = v2(20,20),
            relativePosition = v2((start+min)/(max-min), 0)
        }
    }

    slider.value_element = {
        name = "value",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = slider.value_text,
            textSize = 20,
            size = v2(60,20),
            autoSize = false
        }
    }

    function slider:set_initial_value(value)
        print("set_value")

        self.value = value
        
        if self.value < self.min then
            self.value = self.min
            self.bar.props.relativePosition = v2(0,0)
        end

        if self.value > self.max then
            self.value = self.max
            self.bar.props.relativePosition = v2(1,0)
        end

        self.value_text = tostring(self.value)
        self.value_element.props.text = self.value_text

    end

    function slider:set_value(value)
        print("set_value")

        self.value = value
        
        if self.value < self.min then
            self.value = self.min
            self.bar.props.relativePosition = v2(0,0)
        end

        if self.value > self.max then
            self.value = self.max
            self.bar.props.relativePosition = v2(1,0)
        end

        self.value_text = tostring(self.value)
        self.value_element.props.text = self.value_text

        if self.update_target then
            self.update_target(self.value)
        end
    end

    function slider:move_left()
        print("Moving slider left")

        local relativeInterval = self.interval / (self.max - self.min)

        self.bar.props.relativePosition =
            self.bar.props.relativePosition - v2(relativeInterval, 0)

        self.value = self.value - self.interval
        
        if self.value < self.min then
            self.value = self.min
            self.bar.props.relativePosition = v2(0,0)
        end

        self.value_text = tostring(self.value)
        self.value_element.props.text = self.value_text

        if self.update_target then
            self.update_target(self.value)
        end
    end

    function slider:move_right()
        print("Moving slider right")

        local relativeInterval = self.interval / (self.max - self.min)

        self.bar.props.relativePosition =
            self.bar.props.relativePosition + v2(relativeInterval, 0)

        self.value = self.value + self.interval

        if self.value > self.max  then
            self.value = self.max
            self.bar.props.relativePosition = v2(1,0)
        end

        self.value_text = tostring(self.value)
        self.value_element.props.text = self.value_text

        if self.update_target then
            self.update_target(self.value)
        end
    end

    function slider:create()
        self.ui = {
            name = self.text .. "_slider",
            type = UI.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = UI.ALIGNMENT.Start,
                align = UI.ALIGNMENT.Start,
            },
            content = UI.content {
                {
                    name = self.text  .. "_name",
                    type = UI.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = self.text .. ":   ",
                        textSize = 20,
                        size = v2(140, 20),
                        visible = true,
                        autoSize = false,
                    },
                    content = UI.content {}
                }, 
                self.value_element,
                templates.padding(20, 20),
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
                        mouseClick = async:callback(function() self:move_left() end)
                    }
                },
                {
                    name = self.text  .. "_background_bar",
                    template = I.MWUI.templates.borders,
                    type = UI.TYPE.Image,
                    props = {
                        resource = UI.texture({
                            path = "black"
                        }),
                        alpha = 1,
                        size = v2(200, 20),
                    },
                    content = UI.content {
                        self.bar
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
                        mouseClick = async:callback(function() self:move_right() end)
                    }
                },
            }
        }
        return self.ui
    end

    function slider:hide() 
        print("hiding: ", self.text)
        self.ui.props.visible = false
    end

    function slider:show() 
        print("show: ", self.text)
        self.ui.props.visible = true
        -- if self.update_target then
        --     self.update_target(self.value)
        -- end
    end

    return slider
end

return templates