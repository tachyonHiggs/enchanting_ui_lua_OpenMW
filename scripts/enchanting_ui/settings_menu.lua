local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'options_enchanting_ui',
    page = 'enchanting_ui_page',
    l10n = 'enchanting_ui',
    name = 'Enchanting Remastered Options',
    description = 'Options - Vanilla Plus',
    permanentStorage = true,
    settings = {
        {
            key = 'remove_compound_effect_cost',
            renderer = 'checkbox',
            name = 'Remove compounding cost of multiple effects',
            description = 'When set to yes, makes added effects past the first one have the same cost instead of the Vanilla implementation (Vanilla uses compounding effects costs after the first effect)',
            default = false,
			argument = {
                disabled = false,
            }
        },

   	},
}

I.Settings.registerGroup {
    key = 'cheats_enchanting_ui',
    page = 'enchanting_ui_page',
    l10n = 'enchanting_ui',
    name = 'Enchanting Remastered Cheats',
    description = 'Cheats',
    permanentStorage = true,
    settings = {
        {
            key = 'MaxMult',
            renderer = 'number',
            name = 'Max Multiplier',
            description = 'The maximum an items enchantment capacity can increase by, in one altar improvement.',
            default = 13,
			argument = {
                disabled = false,
                integer = false,
                min = 1,
                max = 1000,
            }
        },
        {
            key = 'remove_enchant_cap_limit',
            renderer = 'checkbox',
            name = 'Remove enchantment capacitiy limit',
            description = 'When set to yes, allows enchantments to exceed an items enchantment capacity.',
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'always_success',
            renderer = 'checkbox',
            name = 'Sets enchantment creation chance to 100%',
            description = 'When set to yes, all player created enchantments will succeed if requirements are meet',
            default = false,
			argument = {
                disabled = false,
            }
        },

   	},
}