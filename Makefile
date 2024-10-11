# macOS makefile for CH559 USB Host Board
# vim: set noet ts=8 sw=8
# CH559 USB Host Board:                   https://www.tindie.com/products/matzelectronics/ch559-usb-host-to-uart-bridge-module/
# Forked from:                            https://github.com/MatzElectronics/CH559sdccUSBHost
# Uses isp55e0 to flash:                  https://github.com/frank-zago/isp55e0

# Makefile "best practices" from https://tech.davis-hansson.com/p/make/ (but not forcing gmake)
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# brew install sdcc
SDCC=sdcc
PACKIHX=packihx
# objcopy is not normally on macOS, using rosco version (or brew install binutils [and set path])
OBJCOPY=m68k-elf-rosco-objcopy
ISP55E0=../isp55e0/isp55e0

# CH559  - 8-bit Enhanced USB MCU https://bitsavers.org/components/wch/_dataSheets/CH559DS1.PDF
XRAM_SIZE=0x0800
XRAM_LOC=0x0600
CODE_SIZE=0xEFFF
DFREQ_SYS=48000000

SDCC_FLAGS=-V -mmcs51 --model-large --xram-size $(XRAM_SIZE) --xram-loc $(XRAM_LOC) --code-size $(CODE_SIZE) -I. -DFREQ_SYS=$(DFREQ_SYS)

PROJECT_NAME=CH559USB
CSOURCES=$(wildcard *.c)
CINCLUDES=$(wildcard *.h) config.h
OBJECTS=$(addsuffix .rel,$(basename $(CSOURCES)))

all: $(PROJECT_NAME).bin

flash: $(PROJECT_NAME).bin
	@echo Connect CH559 with BOOT shorted to enter boot-loader.
	@echo press ENTER when ready to flash CH559.
	@read
	$(ISP55E0) --code-flash $(PROJECT_NAME).bin

$(PROJECT_NAME).ihx: $(OBJECTS)
	$(SDCC) $(SDCC_FLAGS) $^ -o $@

# make empty config.h if none present
config.h:
	touch config.h

$(OBJECTS): $(CINCLUDES)

clean:
	rm -f $(PROJECT_NAME).bin $(PROJECT_NAME).hex $(PROJECT_NAME).map $(PROJECT_NAME).mem $(PROJECT_NAME).ihx $(PROJECT_NAME).lk $(OBJECTS) $(addsuffix .asm,$(basename $(CSOURCES))) $(addsuffix .lst,$(basename $(CSOURCES))) $(addsuffix .sym,$(basename $(CSOURCES))) $(addsuffix .rst,$(basename $(CSOURCES)))

# rules for SDCC compile
# make bin from packed hex
%.bin : %.hex
	$(OBJCOPY) -Iihex -Obinary $< $@

%.hex : %.ihx
	$(PACKIHX) $< >$@

# make rel from c
%.rel : %.c
	$(SDCC) -c $(SDCC_FLAGS) -o $@ $<

.PHONY: all flash clean
