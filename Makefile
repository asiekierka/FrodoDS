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

.PHONY: checkarm7 checkarm9 clean

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
all: checkarm7 checkarm9 $(TARGET).nds

# $(TARGET).ds.gba	: $(TARGET).nds

#---------------------------------------------------------------------------------
$(TARGET).nds	:	checkarm7 checkarm9
	#ndstool -c $(TARGET).nds -b C64_icon.bmp "C64 Emu" -7 $(TARGET).arm7 -9 $(TARGET).arm9
	ndstool -c $(TARGET).nds -7 arm7/$(TARGET).arm7.elf -9 arm9/$(TARGET).arm9.elf \
		-b C64_icon.bmp "FrodoDS"
	#dsbuild $(TARGET).nds
	#padbin 512 $(TARGET).ds.gba
	#cat $(TARGET).ds.gba frodo.img > $(TARGET)_fs.ds.gba
	#dlditool fcsr.dldi $(TARGET)_fs.ds.gba
	#dlditool scsd.dldi $(TARGET).nds
#---------------------------------------------------------------------------------
checkarm7:
	$(MAKE) -C arm7
	
#---------------------------------------------------------------------------------
checkarm9:
	$(MAKE) -C arm9

#---------------------------------------------------------------------------------
clean:
	$(MAKE) -C arm9 clean
	$(MAKE) -C arm7 clean
	rm -f $(TARGET).nds
	#rm -f $(TARGET).ds.gba $(TARGET).arm7 $(TARGET).arm9
