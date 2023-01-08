#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM)
endif

include $(DEVKITARM)/ds_rules

export TARGET		:=	FrodoDS
export TOPDIR		:=	$(CURDIR)


#---------------------------------------------------------------------------------
# path to tools - this can be deleted if you set the path in windows
#---------------------------------------------------------------------------------
export PATH		:=	$(DEVKITARM)/bin:$(PATH)

.PHONY: $(TARGET).arm7 $(TARGET).arm9

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
all: $(TARGET).ds.gba

$(TARGET).ds.gba	: $(TARGET).nds

#---------------------------------------------------------------------------------
$(TARGET).nds	:	$(TARGET).arm7 $(TARGET).arm9
	#ndstool -c $(TARGET).nds -b C64_icon.bmp "C64 Emu" -7 $(TARGET).arm7 -9 $(TARGET).arm9
	ndstool -c $(TARGET).nds -7 $(TARGET).arm7 -9 $(TARGET).arm9
	dsbuild $(TARGET).nds
	padbin 512 $(TARGET).ds.gba
	cat $(TARGET).ds.gba frodo.img > $(TARGET)_fs.ds.gba
	dlditool fcsr.dldi $(TARGET)_fs.ds.gba
	dlditool scsd.dldi $(TARGET).nds
#---------------------------------------------------------------------------------
$(TARGET).arm7	: arm7/$(TARGET).elf
$(TARGET).arm9	: arm9/$(TARGET).elf

#---------------------------------------------------------------------------------
arm7/$(TARGET).elf:
	$(MAKE) -C arm7
	
#---------------------------------------------------------------------------------
arm9/$(TARGET).elf:
	$(MAKE) -C arm9

#---------------------------------------------------------------------------------
clean:
	$(MAKE) -C arm9 clean
	$(MAKE) -C arm7 clean
	rm -f $(TARGET).ds.gba $(TARGET).nds $(TARGET).arm7 $(TARGET).arm9
