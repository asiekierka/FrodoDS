/*
 *  C64_GP32.i by Mike Dawson, adapted from:
 *  C64_x.i - Put the pieces together, X specific stuff
 *f
 *  Frodo (C) 1994-1997,2002 Christian Bauer
 *  Unix stuff by Bernd Schmidt/Lutz Vieweg
 */

#include "Prefs.h"
#include "main.h"
extern "C" {

//#include "menu.h"
//#include "ui.h"
//#include "input.h"
//#include "gpmisc.h"
}

#include <nds.h>
#include "nds/arm9/console.h" 
#include <stdio.h>

#define MATRIX(a,b) (((a) << 3) | (b))

#define timers2ms(tlow,thigh) (tlow | (thigh<<16))
#define TICKS_PER_SEC (BUS_CLOCK >> 6)

void StartTimers(void) 
{ 
   TIMER0_DATA=0; 
   TIMER1_DATA=0; 
   TIMER0_CR=TIMER_DIV_64|TIMER_ENABLE; 
   TIMER1_CR=TIMER_CASCADE|TIMER_ENABLE;
} 

inline uint32 GetTicks(void) 
{ 
   return timers2ms(TIMER0_DATA, TIMER1_DATA); 
} 

void Pause(uint32 ms) 
{ 
   uint32 now; 
   now=timers2ms(TIMER0_DATA, TIMER1_DATA); 
   while((uint32)timers2ms(TIMER0_DATA, TIMER1_DATA)<now+ms); 
} 


extern void print(char *s);

static int time_start=0;
int total_frames=0;

int current_joystick=0;

#ifndef HAVE_USLEEP

int usleep(unsigned long int microSeconds)
{
	Pause(microSeconds); 
	return 0;
}
#endif


/*
 *  Constructor, system-dependent things
 */

void C64::c64_ctor1(void)
{
    StartTimers();
    
}

void C64::c64_ctor2(void)
{
}


/*
 *  Destructor, system-dependent things
 */

void C64::c64_dtor(void)
{
}


/*
 *  Start main emulation thread
 */

void C64::Run(void)
{
	// Reset chips
	this->Reset();

	// Patch kernal IEC routines
	orig_kernal_1d84 = Kernal[0x1d84]; 
	orig_kernal_1d85 = Kernal[0x1d85];
	PatchKernal(ThePrefs.FastReset, ThePrefs.Emul1541Proc);

	quit_thyself = false;
	thread_func();
}

char kbd_feedbuf[256];
int kbd_feedbuf_pos;

void kbd_buf_feed(const char *s) {
	strncat(kbd_feedbuf, s, 255);
}

void kbd_buf_reset(void) {
	kbd_feedbuf[0] = 0;
	kbd_feedbuf[255] = 0;
	kbd_feedbuf_pos=0;
}

void kbd_buf_update(C64 *TheC64) {
	if((kbd_feedbuf[kbd_feedbuf_pos]!=0)
			&& TheC64->RAM[198]==0) {
		TheC64->RAM[631]=kbd_feedbuf[kbd_feedbuf_pos];
		TheC64->RAM[198]=1;

		kbd_feedbuf_pos++;
	} else {
		kbd_feedbuf_pos = 0;
		kbd_feedbuf[0] = 0;
	}
}

void load_prg(C64 *TheC64, uint8 *prg, int prg_size) {
	uint8 start_hi, start_lo;
	uint16 start;
	int i;

	start_lo=*prg++;
	start_hi=*prg++;
	start=(start_hi<<8)+start_lo;

	for(i=0; i<(prg_size-2); i++) {
		TheC64->RAM[start+i]=prg[i];
	}
} 

/*
 *  Vertical blank: Poll keyboard and joysticks, update window
 */

void C64::VBlank(bool draw_frame)
{
	int speed_index;

	scanKeys();
	kbd_buf_update(this);

	TheDisplay->PollKeyboard(TheCIA1->KeyMatrix, TheCIA1->RevMatrix, &joykey);

	TheCIA1->Joystick1 = poll_joystick(0);
	TheCIA1->Joystick2 = poll_joystick(1);


	if(draw_frame) { 
		TheDisplay->Update();
//		if(keyboard_enabled||options_enabled||status_enabled)
//			draw_ui(this);
		TheDisplay->BufSwap();

		 //calculate time between vblanks
		int timeExpected=TICKS_PER_SEC*ThePrefs.SkipFrames/50;
		uint32 timeTo=time_start+timeExpected;
		int time_end=GetTicks();
		int time=time_end-time_start;
		time_start=time_end;

		speed_index=timeExpected*100/time;

		if(ThePrefs.LimitSpeed && speed_index >= 100) {
			while(true) {
				uint32 timeNow=GetTicks();
				if((timeTo-timeNow)>=0x80000000) break;
			} 
			if(speed_index>100) speed_index=100;
		}

		TheDisplay->Speedometer((int)speed_index);

		// calculate fps
		total_frames++;
		long emu_fps=(total_frames/(((GetTicks()+1)/TICKS_PER_SEC)+1))*100;
		//char a[100];
		//sprintf(a,"fps %d\n",emu_fps);
  //      consolePrintf(a);
	}

}


/*
 *  Open/close joystick drivers given old and new state of
 *  joystick preferences
 */ 
extern char* dotextmenu();
void C64::open_close_joysticks(int oldjoy1, int oldjoy2, int newjoy1, int newjoy2)
{
}
  
/*
 *  Poll joystick port, return CIA mask 
 */
int space=0;
int switchstick=0;
bool last_load_drive = false;
uint8 C64::poll_joystick(int port)
{
	uint8 j = 0xff;
	
	if (space ==1){
    	TheDisplay->KeyRelease(MATRIX(7,4), TheCIA1->KeyMatrix, TheCIA1->RevMatrix); 
	 space=0;
    }
	u32 keys= keysHeld();
    u32 rkeys = keysUp();

	if(port!=current_joystick) return j;

	//if(options_enabled||keyboard_enabled) return j; 

	if( keys & KEY_LEFT  ) j&=0xfb;
	if( keys & KEY_RIGHT ) j&=0xf7;
	if( keys & KEY_UP    ) j&=0xfe;
	if( keys & KEY_DOWN  ) j&=0xfd;
	if( keys & KEY_A     ) j&=0xef; 
    
    if( keys & KEY_B     ) {
		uint8 *key_matrix;
		uint8 *rev_matrix;
		TheDisplay->KeyPress(MATRIX(7,4), TheCIA1->KeyMatrix, TheCIA1->RevMatrix);
		space=1;
    }    
        
	if( keys & KEY_X     )
    {
		Pause();
		char theDrivePath[256];
		strcpy(theDrivePath,ThePrefs.DrivePath[0]);
		int len = strlen(theDrivePath);
		char *p=&theDrivePath[len-4];
		strcpy(p,".FSS");
		SaveSnapshot(theDrivePath);
		Resume();
    }          
    
	if( keys & KEY_L     ) 
    {
		Pause();
		Prefs *prefs = new Prefs(ThePrefs);
		char filePath[256];
		bool isDrive = false;
		strcpy(filePath, dotextmenu());
		int len = strlen(filePath);
		if (len>=4)
		{
			if (!strcasecmp(".fss",&filePath[len-4]))
			{
				LoadSnapshot(filePath);
				char *p=&filePath[len-4];
				strcpy(p,".D64");
			}
			else if (!strcasecmp(".prg", &filePath[len-4]) && this->KernalIsBuiltin)
			{
				// NDS: Hack to load .PRG files without functioning 1541 emulation.
				isDrive = false;

				FILE *file = fopen(filePath, "rb");
				if (file != NULL) {
					fseek(file, 0, SEEK_END);
					int32_t flen = ftell(file) - 2;
					fseek(file, 0, SEEK_SET);
					uint8_t pos_low = fgetc(file);
					uint8_t pos_high = fgetc(file);
					uint16_t pos = (pos_high << 8) | pos_low;
					if (flen > 65536-pos) flen = 65536-pos;
					fread(this->RAM + pos, flen, 1, file);
					fclose(file);
				}
			}
		}
		last_load_drive = isDrive;
		if (isDrive) {
			strcpy(prefs->DrivePath[0], filePath);
		}
		this->NewPrefs(prefs);
		ThePrefs = *prefs;
		delete prefs;	
		Resume();
    } 
    if( keys & KEY_R     ) 
    {
		if (last_load_drive) kbd_buf_feed("\rLOAD\"*\",8,1\rRUN\r"); 
		else kbd_buf_feed("\rRUN\r");
    }               
    
    if( (keys & KEY_SELECT) && (switchstick==0))
    {
		if (current_joystick == 0) current_joystick=1;
		else if (current_joystick == 1) current_joystick=0;
		switchstick=1;
	}	
	else if( (keys & KEY_SELECT) && (switchstick==1))
		switchstick=0;

    if( keys & KEY_START)
    {
		this->PatchKernal(ThePrefs.FastReset, ThePrefs.Emul1541Proc);
		this->Reset();
		kbd_buf_reset();
	}

	return j;
}


/*
 * The emulation's main loop
 */

void C64::thread_func(void)
{
//consolePrintf("\tthread_func\n");
	int linecnt = 0;

#ifdef FRODO_SC
	while (!quit_thyself) {

		// The order of calls is important here
		if (TheVIC->EmulateCycle())
			TheSID->EmulateLine();
		TheCIA1->CheckIRQs();
		TheCIA2->CheckIRQs();
		TheCIA1->EmulateCycle();
		TheCIA2->EmulateCycle();
		TheCPU->EmulateCycle();

		if (ThePrefs.Emul1541Proc) {
			TheCPU1541->CountVIATimers(1);
			if (!TheCPU1541->Idle)
				TheCPU1541->EmulateCycle();
		}
		CycleCounter++;
#else
	while (!quit_thyself) {
	
		if(have_a_break)
        {
			scanKeys();
//			consolePrintf("&");
			TheDisplay->BufSwap();
			continue; 
		}

		// The order of calls is important here
		int cycles = TheVIC->EmulateLine();
		TheSID->EmulateLine();
#if !PRECISE_CIA_CYCLES
		TheCIA1->EmulateLine(ThePrefs.CIACycles);
		TheCIA2->EmulateLine(ThePrefs.CIACycles);
#endif 

		if (ThePrefs.Emul1541Proc) {
			int cycles_1541 = ThePrefs.FloppyCycles;
			TheCPU1541->CountVIATimers(cycles_1541);

			if (!TheCPU1541->Idle) {
				// 1541 processor active, alternately execute
				//  6502 and 6510 instructions until both have
				//  used up their cycles
				while (cycles >= 0 || cycles_1541 >= 0)
					if (cycles > cycles_1541)
						cycles -= TheCPU->EmulateLine(1);
					else
						cycles_1541 -= TheCPU1541->EmulateLine(1);
			} else
				TheCPU->EmulateLine(cycles);
		} else
			// 1541 processor disabled, only emulate 6510
			TheCPU->EmulateLine(cycles);
#endif
//consolePrintf("\tthread_func\n");
		linecnt++;
	}
}

void C64::Pause() {
	have_a_break=true;
	TheSID->PauseSound();
}

void C64::Resume() {
	have_a_break=false;
	TheSID->ResumeSound();
}

