DIR := ${CURDIR}

BINS := $(patsubst %.asm,%.BIN,$(wildcard *.asm))
WAVS := $(patsubst %.asm,%.WAV,$(wildcard *.asm))

all: $(WAVS)

$(BINS): %.BIN: %.asm
	z88dk-z80asm -b -d -l -m -o=$@ $<

disk: $(BINS)
	@echo "<command>set renderer SDL</command><command>diskmanipulator create JIOC.DSK 360k</command><command>virtual_drive JIOC.DSK</command><command>diskmanipulator import virtual_drive [glob *.{BIN,BAS}]</command><command>exit</command>" | openmsx -machine Philips_VG_8235-20 -control stdio


$(WAVS): %.WAV: %.BIN disk
	@./make-wav.sh $(DIR) $@ $< $(shell od -A n -j 1 -N 2 -t u2 $<) $(shell od -A n -j 3 -N 2 -t u2 $<) $(shell od -A n -j 5 -N 2 -t u2 $<) | openmsx -machine Philips_VG_8235-20 -control stdio -diska JIOC.DSK

