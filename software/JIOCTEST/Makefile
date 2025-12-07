JIOCTEST.BIN: JIOCTEST.asm
	z80asm -b -d -l -m -o=JIOCTEST.BIN JIOCTEST.asm

disk: JIOCTEST.BIN
	@echo "<command>set renderer SDL</command><command>diskmanipulator create JIOCTEST.DSK 360k</command><command>virtual_drive JIOCTEST.DSK</command><command>diskmanipulator import virtual_drive [glob *.{BIN,BAS}]</command><command>exit</command>" | openmsx -machine Philips_VG_8235-20 -control stdio
