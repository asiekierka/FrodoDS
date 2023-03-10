/*
 *  main.cpp - Main program
 *
 *  Frodo (C) 1994-1997,2002-2005 Christian Bauer
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "sysdeps.h"

#include "main.h"
#include "C64.h"
#include "Display.h"
#include "Prefs.h"
#include "SAM.h"
#include "openroms_basic_bin.h"
#include "openroms_chargen_bin.h"
#include "openroms_kernal_bin.h"

// Global variables
C64 *TheC64 = NULL;		// Global C64 object
char AppDirPath[1024];	// Path of application directory


// ROM file names
#ifndef DATADIR
#define DATADIR 
#endif

#ifdef __riscos__
#define BASIC_ROM_FILE	"FrodoRsrc:Basic_ROM"
#define KERNAL_ROM_FILE	"FrodoRsrc:Kernal_ROM"
#define CHAR_ROM_FILE	"FrodoRsrc:Char_ROM"
#define DRIVE_ROM_FILE	"FrodoRsrc:1541_ROM"
#else
#ifndef __NDS__
#define BASIC_ROM_FILE DATADIR "Basic ROM"
#define KERNAL_ROM_FILE DATADIR "Kernal ROM"
#define CHAR_ROM_FILE DATADIR "Char ROM"
#define DRIVE_ROM_FILE DATADIR "1541 ROM"
#else
#define BASIC_ROM_FILE "/rd/basic.rom"
#define KERNAL_ROM_FILE "/rd/kernal.rom"
#define CHAR_ROM_FILE "/rd/char.rom"
#define DRIVE_ROM_FILE "/rd/1541.rom"
#endif
#endif

/*
 *  Load C64 ROM files
 */

bool Frodo::load_rom(const char *which, const char *path, uint8 *where, size_t size, const uint8 *builtin)
{
	FILE *f = fopen(path, "rb");
	if (f) {
		size_t actual = fread(where, 1, size, f);
		fclose(f);
		if (actual == size)
			return true;
	}

	// Use builtin ROM
	if (builtin != NULL) {
		printf("%s ROM file (%s) not readable, using builtin.\n", which, path);
		memcpy(where, builtin, size);
	}
	return false;
}

void Frodo::load_rom_files()
{
	load_rom("Basic", BASIC_ROM_FILE, TheC64->Basic, BASIC_ROM_SIZE, openroms_basic_bin);
	TheC64->KernalIsBuiltin = !load_rom("Kernal", KERNAL_ROM_FILE, TheC64->Kernal, KERNAL_ROM_SIZE, openroms_kernal_bin);
	load_rom("Char", CHAR_ROM_FILE, TheC64->Char, CHAR_ROM_SIZE, openroms_chargen_bin);
	load_rom("1541", DRIVE_ROM_FILE, TheC64->ROM1541, DRIVE_ROM_SIZE, NULL);
}


#ifdef __BEOS__
#include "main_Be.h"
#endif

#ifdef AMIGA
#include "main_Amiga.h"
#endif

#ifdef __unix
#include "main_x.h"
#endif

#ifdef __mac__
#include "main_mac.h"
#endif

#ifdef WIN32
#include "main_WIN32.h"
#endif

#ifdef __riscos__
#include "main_Acorn.h"
#endif

#ifdef __NDS__
#include "main_NDS.i"
#endif 
