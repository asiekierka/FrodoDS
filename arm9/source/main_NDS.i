/*
 * main_NDS.i
 *
 */
#include "Version.h"
#include <nds.h>
#include <sys/stat.h> 
#include <stdio.h>
#include <stdlib.h>
extern int init_graphics(void);

// Outputs a string to the dualis console 
void printdbg(char *s) { 
#ifdef DEBUG 
     //warning! will crash on hardware (i think)!  
    asm volatile ("mov r0, %0;" "swi 0xffffff;": 
                  :"r" (s):"r0"); 
#endif                  
} 
extern void InterruptHandler(void);
char Frodo::prefs_path[256] = "/rd/";
extern "C" {


// Global variables



/*
 *  Create application object and start it
 */

int main(int argc, char **argv)
{
	printdbg("main");
	Frodo *the_app;
	char *args[]={ "Frodo", NULL };

	if (!init_graphics())
		return 0;
		//init_graphics();
		
//consolePrintf("\tGRAPHICS INIT\n");		
   // printdbg("GRAPHICS INIT");

	the_app = new Frodo();
	
//consolePrintf("\tFrodo INIT\n");
		
	//the_app->ArgvReceived(argc, argv);
	the_app->ArgvReceived(1, args);
 
//consolePrintf("\tFrodo ArgvReceived\n");
	
	ThePrefs.SkipFrames=3;
	ThePrefs.SIDFilters=true;
	ThePrefs.SIDType=SIDTYPE_DIGITAL;
	ThePrefs.LimitSpeed=false;
	ThePrefs.Emul1541Proc=false;
	ThePrefs.FastReset=true;

//   consolePrintf("\tFrodo ThePrefs\n");

	the_app->ReadyToRun();
	delete the_app;

//	consolePrintf("frodo terminated\n");
	return (1);
}


/*
 *  Constructor: Initialize member variables
 */

Frodo::Frodo()
{
	TheC64 = NULL;
}


/*
 *  Process command line arguments
 */

void Frodo::ArgvReceived(int argc, char **argv)
{
	if (argc == 2)
		strncpy(prefs_path, argv[1], 255);
}


/*
 *  Arguments processed, run emulation
 */

void Frodo::ReadyToRun(void)
{
	//getcwd(AppDirPath, 256); 

	// Load preferences
	
	//if (!prefs_path[0]) {
	//	char *home = "/rd";
	//	if (home != NULL && strlen(home) < 240) {
	//		strncpy(prefs_path, home, 200);
	//		strcat(prefs_path, "/");
	//	}
	//	strcat(prefs_path, "Frodo.fpr");
	//}

	strcpy(prefs_path, "/rd/Frodo.fpr");
	ThePrefs.Load(prefs_path);

	// Create and start C64
	TheC64 = new C64;
	
//consoleClear();
//	consolePrintf("\tLoading Roms\n");	
//	consolePrintf("\tLoading Roms2\n");
//	if (load_rom_files())
    load_rom_files();	
//	consolePrintf("\tROMS LOADED\n");	 
		TheC64->Run();
	delete TheC64;
}


Prefs *Frodo::reload_prefs(void)
{
	static Prefs newprefs;
	newprefs.Load(prefs_path);
	return &newprefs;
}

}

bool IsDirectory(const char *path){
	struct stat st;
	return stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}
