local I = require('openmw.interfaces')

local enchanting_ui = require("scripts.enchanting_ui.enchanting_ui")

-- For the menu settings tab
I.Settings.registerPage ({
    key = 'enchanting_ui_page',
    l10n = 'enchanting_ui',
    name = 'Enchanting Remastered',
    description = 'Enchanting Remastered Description and Settings.',
})

local function onLoad(data)
    -- Register Window
    I.UI.registerWindow('EnchantingDialog', function() end, enchanting_ui.hide)
end

return {
    engineHandlers = {
        onInit = onLoad,
        onLoad = onLoad,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')

            if data.newMode == 'Enchanting' then
                -- This handles displaying the actual UI depending on which one is appropiate
                if data.oldMode == 'Dialogue' then
                    local vendor = data.arg
                    enchanting_ui.show(true, vendor, nil)
                else 
                    local soul_gem = data.arg
                    enchanting_ui.show(false, nil, soul_gem)
                end
                
            end

        end,
    }
}
