# Enchanting UI

## TODO / Change Log

### Vanilla Features
- Final touches to add effect window
- Layering issues
- Ability to drag sliders and scroll bars
    - And replace yellow bar with actual texture
- Finish tool tips text to relevant elements

### Expanded Features
- Potentially add the ability use vendor's soul gems while enchanting
- Allow bartering for vendor enchanted items services
- Add cheat that makes menu show all magic effects in the game
- Allow bartering to use vendor known magic effects
- Add cast type to item list
- Add option to make fortify speechcraft, mercantile, alchemy, smithing, enchanting, etc have much higher costs for 1 second
- Potentially add functionality to rename enchanted items

### Development
- Add descriptions, params, fields etc to functions and files
- Make it so that changing item does not cause the enchanting menu to reset
- Add Support/references, etc

## Removed/Useless GMST's

## Known Issues
 - (FIXED) Opening the enchantment menu immediately upon starting causes the menus to not load all items, souls, and magic effects
 - Minimum sized magic effects cause the item to have 0 charge
 - Menus layering issue, !!IMPORTANT!!
 - Skill menu select for effect does not wrap, will fix this with new OpenMW release or will implement it myself later
 - (FIXED) Issue with canceling editing an effect
 - (FIXED) Sorting lists can get directions flipped
 - Hitting cast type will always reset effects even if the type does not change