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
            key = 'constant_effect_threshold',
            renderer = 'number',
            name = 'Constant Effect Threshold',
            description = 'Sets the threshold a Soul needs to have to allow constant effects.',
            default = 400,
			argument = {
                disabled = false,
                integer = false,
                min = 1,
                max = 1000,
            }
        },
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
            key = 'remove_enchant_cap_limit',
            renderer = 'checkbox',
            name = 'Remove Enchantment Capacitiy limit',
            description = 'When set to yes, allows enchantments to ignore an items enchantment capacity.',
            default = false,
			argument = {
                disabled = false,
            }
        },
        {
            key = 'remove_soul_charge_limit',
            renderer = 'checkbox',
            name = 'Remove Soul Charge limit',
            description = 'When set to yes, allows enchantments to ignore a Souls charge.',
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
        {
            key = 'dont_consume_item_and_soul',
            renderer = 'checkbox',
            name = 'Do not consume Soul Gem and Item on Enchant',
            description = 'When set to yes, attempts and successfull enchantments no longer consume soul gems and items',
            default = false,
			argument = {
                disabled = false,
            }
        },

   	},
}