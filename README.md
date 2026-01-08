# MSX JIO CART

This is a simple MSX cartridge that allows software-based serial communications like MSXJIO but without using joystick port 2.

It includes:
* a flash ROM writable by either software (in-system from MSX-DOS) or hardware (using an external programmer)
* an I/O register to interface with embedded serial modules
  * address of I/O register is configurable between a set of predefined options
* one or two of these serial modules (only one active at a time):
  * a RT232RL-based USB Serial Module
  * a Bluetooth HC-05 Module
* a switch to select the active serial module
  * optional if only one module is populated

More information coming.

> [!WARNING]
> This is untested material, DO NOT BUILD yet!

## Current Status

* First prototype PCB sent for manufacturing as of Dec 2nd 2025 (couldn't wait to confirm some footprints...).
* After a long wait, bare prototype PCBs arrived as of Jan 8th 2026. Now, let's find some time to assemble them and (cross fingers) hope I grabbed all needed components.

## References

NYYRIKKI's 115200 bps routines
* https://www.msx.org/forum/msx-talk/development/software-rs-232-115200bps-on-msx

b3rendsh msxdos2s
* https://github.com/b3rendsh/msxdos2s

Louthrax MSXJIO
* https://github.com/louthrax/MSXJIO

Skoti's Spider Flash Cart
* https://github.com/konkotgit/MSX-Spider-Flash-Cart

Danjovic Soda-IDE
* https://github.com/Danjovic/Soda-IDE
