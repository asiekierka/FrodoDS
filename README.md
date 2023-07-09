This is the source code to Frodo, by Christian Bauer, with modifications for
the nds by Troy Davis(GPF) and additional modifications by asie. The original
source code is obtainable from http://www.uni-mainz.de/~bauec002/FRMain.html. 
The original home page of the NDS port is http://console-news.dcemu.co.uk/Frodoc64.shtml .
The current source code should be available from https://github.com/asiekierka/FrodoDS .

## Instructions

1. Install as follows:
  * C64 BASIC .ROM -> /rd/basic.rom
  * C64 KERNAL .ROM -> /rd/kernal.rom
  * (Optionally) C64 character generator .ROM -> /rd/chargen.rom
2. Copy your .D64 c64 disk images to a folder called /rd on the root of your cf/sd card
3. Start the emulator; press L to select the d64 disk to mount on drive 8
4. You can press the right trigger to have it automatically type LOAD"*",8,1 and then RUN .

Note: You might want to test the .d64 file on another version of Frodo to verify that the d64 is compatible with Frodo.

## Controls

  * Left Trigger - Load Frodo Memory Snapshot or mount .D64 c64 disk image
  * Right Trigger - automatically type `LOAD"*",8,1` and then `RUN`.
  * START - reset
  * SELECT - switch between port1 and port2 that the joystick is in
  * B - space key
  * A - fire
  * D-Pad - Joystick directions

## Acknowledgements

  * Troy Davis(GPF) http://gpf.dcemu.co.uk - FrodoDS initial porter
  * Christian Bauer - Original Frodo author
  * headspin for the keyboard and code
  * thechuckster for the fat library d64 browser from his stellads port
  * maintainers of devkitpro and libnds
  * to all those in #mellowdsdev and #dsdev on efnet for there help and support
