/*
 *  C64_GP32.i by Mike Dawson, adapted from:
 *  C64_x.i - Put the pieces together, X specific stuff
 *f
 *  Frodo (C) 1994-1997,2002 Christian Bauer
 *  Unix stuff by Bernd Schmidt/Lutz Vieweg
 */

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

#define timers2ms(tlow,thigh)(tlow | (thigh<<16)) >> 5

void StartTimers(void) 
{ 
   TIMER0_DATA=0; 
   TIMER1_DATA=0; 
   TIMER0_CR=TIMER_DIV_1024|TIMER_ENABLE; 
   TIMER1_CR=TIMER_CASCADE|TIMER_ENABLE;
} 

uint32 GetTicks(void) 
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
	TheCPU->Reset();
	TheSID->Reset();
	TheCIA1->Reset();
	TheCIA2->Reset();
	TheCPU1541->Reset();

	// Patch kernal IEC routines
	orig_kernal_1d84 = Kernal[0x1d84]; 
	orig_kernal_1d85 = Kernal[0x1d85];
	PatchKernal(ThePrefs.FastReset, ThePrefs.Emul1541Proc);

	quit_thyself = false;
	thread_func();
}

char kbd_feedbuf[255];
int kbd_feedbuf_pos;

void kbd_buf_feed(const char *s) {
	strcpy(kbd_feedbuf, s);
	kbd_feedbuf_pos=0;
}

void kbd_buf_update(C64 *TheC64) {
	if((kbd_feedbuf[kbd_feedbuf_pos]!=0)
			&& TheC64->RAM[198]==0) {
		TheC64->RAM[631]=kbd_feedbuf[kbd_feedbuf_pos];
		TheC64->RAM[198]=1;

		kbd_feedbuf_pos++;
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
	double elapsed_time, speed_index;

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
		int time=GetTicks()-time_start;
		elapsed_time=(double)time*(1000000/CLOCKS_PER_SEC);
		speed_index=20000/(elapsed_time+1)*ThePrefs.SkipFrames*100;
		time_start=GetTicks();

		if((speed_index>100) && ThePrefs.LimitSpeed) {
			usleep((unsigned long)(ThePrefs.SkipFrames*20000-elapsed_time));
			speed_index=100;
		}

		TheDisplay->Speedometer((int)speed_index);

		// calculate fps
		total_frames++;
		long emu_fps=(total_frames/(((GetTicks()+1)/CLOCKS_PER_SEC)+1))*100;
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
 
//#include "BRUCELEE_bin.h" 
/*
 *  Poll joystick port, return CIA mask 
 */
int space=0;
int switchstick=0;
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
		char theDrivePath[256];
		strcpy(theDrivePath, dotextmenu());
		int len = strlen(theDrivePath);
		if (!strcasecmp(".fss",&theDrivePath[len-4]))
		{
			LoadSnapshot(theDrivePath);
			char *p=&theDrivePath[len-4];
			strcpy(p,".D64");
		}
		strcpy(prefs->DrivePath[0], theDrivePath);
		this->NewPrefs(prefs);
		ThePrefs = *prefs;
		delete prefs;	
		Resume();

		//kbd_buf_feed("\rLOAD\"$\",8\rLIST\r"); 
	   //kbd_buf_feed("\rPOKE 53281,7:POKE 53280,8:POKE 646,2\r");
	   //kbd_buf_feed("\r10 PRINT \"HELLO WORLD\"\r20 GOTO 10\rRUN\r");//20 LET A=A+1: IF A < 10 THEN GOTO 10\rRUN\r");
    } 
    if( keys & KEY_R     ) 
    {
			kbd_buf_feed("\rLOAD\"*\",8,1\rRUN\r"); 
           //kbd_buf_feed("\r10 PRINT \"HELLO WORLD\"\r20 GOTO 10\rRUN\r");//20 LET A=A+1: IF A < 10 THEN GOTO 10\rRUN\r");      
           //SaveSnapshot("/ram/gpf.fss");
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
		strcpy(kbd_feedbuf, "");
		kbd_feedbuf_pos=0;
		this->Reset();
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

