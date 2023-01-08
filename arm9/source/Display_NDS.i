/*
 *  Display_NDS.i by Troy Davis(GPF), adapted from:
 *  Display_GP32.i by Mike Dawson - C64 graphics display, emulator window handling,
 *
 *  Frodo (C) 1994-1997,2002 Christian Bauer
 *  X11 stuff by Bernd Schmidt/Lutz Vieweg
 */

#include "SAM.h"
#include "C64.h" 
#include "VIC.h" 



void printdbg(char *s);
#include <nds.h>
#include <fat.h>
//#include <kos/fs_ramdisk.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/stat.h> 
#include <sys/dir.h> 
#include <unistd.h>
#include "file.h"
#include "NDS_spalsh512_img_bin.h"
#include "NDS_spalsh512_pal_bin.h" 

#include "keyboard.raw.h"
#include "keyboard.map.h"
#include "keyboard.pal.h"
#include "keyboard.hit.h"

#define MOVE_MAX 16

#define ABS(a) (((a) < 0) ? -(a) : (a))
#define	ROUND(f) ((u32) ((f) < 0.0 ? (f) - 0.5 : (f) + 0.5))

#define KB_NORMAL 0 
#define KB_CAPS   1
#define KB_SHIFT  2

#define F_1	0x1
#define F_2	0x2
#define F_3	0x3
#define F_4	0x4
#define F_5	0x5
#define F_6	0x6
#define F_7	0x7
#define F_8	0x18

#define LFA	0x095 //Left arrow
#define CLR 0x147
#define PND 0x92

#define RST 0x13 // Restore
#define RET	'\n' // Enter
#define BSP	0x8 // Backspace
#define	CTR	0x21 // Ctrl
#define SPC	0x20// Space
#define ATT	0x22 // At@
#define UPA 0x23 //uparrow symbol
#define RUN	0x0 // RunStop
#define SLK	0x25 // Shift Lock
#define CMD 0x26 // Commodore key
#define SHF 0x27 // Shift Key

#define CUP	0x14 // Cursor up
#define CDL	0x15 // Cursor left

static int m_Mode=KB_SHIFT;

extern u8 col, row; // console cursor position



extern uint16 *screen;
uint16 * map;
uint8 *bufmem;

uint8 *emu_screen;
uint8 *emu_buffers[2];
int emu_buf=0;

static int keystate[256];


//int menupos = 0;
//int menuscrollptr = 0;
//
//bool oldUp = false;
//bool oldDown = false;
// 
//char* dotextmenu();
//void UpdateMenu();
//void ClearScreen();
//
//class ROM
//{
//public:
//	char filename[255];
//	bool directory;
//
//	ROM() { directory = false; }
//};
//
//vector<ROM> romlist;
//
//uint8* buffer = 0;
//unsigned int buffer_size = 0;
//
//bool oldB = false;
//int tot;
//void ReadDirIntoVector()
//{
//	romlist.clear(); // Crucial!
//
//	ROM temp_rom;
//	// Find the first file.
//	struct stat st; 
//	DIR_ITER* dir; 
//	//char filename[256];
//	if ( (dir = diropen("/rd")) == NULL ) { 
//		iprintf("Can't open directory: /rd \n");
//		return; 
//	} 
//	
//	while (dirnext(dir, temp_rom.filename, &st) == 0)
//	{ 	
//		//iprintf("%s \n",temp_rom.filename);
//		if(strstr(temp_rom.filename,".D64") != NULL || strstr(temp_rom.filename,".d64") != NULL)
//		{
//			if(st.st_mode & S_IFDIR == 0)
//				temp_rom.directory = true;
//            else
//				temp_rom.directory = false;				
//
//		romlist.push_back(temp_rom);
//		}
//	}
//
//}
char str[500];
int menufirsttime =0;
int choosingfile = 1;
char* dotextmenu()
{

    videoSetModeSub(MODE_0_2D | DISPLAY_BG0_ACTIVE); //sub bg 0 will be used to print text
 	REG_BG0CNT_SUB = BG_MAP_BASE(31);
	BG_PALETTE_SUB[255] = RGB15(31,31,31);
	consoleInit(NULL, 0, BgType_Text4bpp, BgSize_T_256x256, 31, 0, false, true);
	
	//bool loop = true;
 //   
	//ReadDirIntoVector();
	//tot=romlist.size();
	//ClearScreen();
	//UpdateMenu();
	//	
	//while(loop)
	//{
	//	scanKeys();
	//	
	//	if ((keysHeld() & (KEY_UP)) && !oldDown)
	//	{
	//		menupos--;
	//		if (menupos <= -1) menupos = tot - 1;

	//		if (menupos < menuscrollptr)
	//			menuscrollptr = menupos;

	//		if (menupos > (menuscrollptr+(tot-1)))
	//			menuscrollptr = menupos-(tot-1);

	//		if ((menuscrollptr + tot) > tot)
	//			menuscrollptr = tot - (tot-1);
	//		
	//		UpdateMenu();
	//	}

	//	if ((keysHeld() & (KEY_DOWN)) && !oldUp)
	//	{
	//		menupos++;
	//		if (menupos >= tot) menupos = 0;

	//		if (menupos < menuscrollptr)
	//			menuscrollptr = menupos;

	//		if (menupos > (menuscrollptr+(tot-1)))
	//			menuscrollptr = menupos-(tot-1);

	//		if ((menuscrollptr + tot) > tot)
	//			menuscrollptr = tot - (tot-1);
	//						
	//		UpdateMenu();
	//	}
	//	
	//	if (keysHeld() & (KEY_DOWN))
	//		oldUp = true;
	//	else
	//		oldUp = false;
	//		
	//	if (keysHeld() & (KEY_UP))
	//		oldDown = true;
	//	else
	//		oldDown = false;
	//	
	//	if (keysHeld() & (KEY_A))
	//	{
	//		ClearScreen();
	//		loop = false;
	//	}
	//}
	if(menufirsttime==1){
		loadFile();
	}
	else
		menufirsttime=1;
	strcpy(str,"/rd/");
	//strcat(str, (const char*)romlist[menupos].filename);
	strcat(str, (const char*)fileName);
	
	
	
 lcdSwap();
	videoSetModeSub(MODE_0_2D | DISPLAY_BG1_ACTIVE); //sub bg 0 will be used to display keyboard tiles
	BG_PALETTE_SUB[255] = RGB15(0,0,0);
	REG_BG1CNT_SUB = BG_COLOR_16 | BG_32x32 | BG_MAP_BASE(29) | BG_TILE_BASE(1);
	//get the map
	map = (uint16 *) SCREEN_BASE_BLOCK_SUB(29); 
    for(int i=0;i<1024;i++) map[i] = 7008; //blank tile
    
	REG_BG1VOFS_SUB = 160;//256 - (192 - 96);
    
	dmaCopy((uint16 *)keyboard_Palette, (uint16 *)BG_PALETTE_SUB, 32);
	dmaCopy((uint16 *)keyboard_Map, (uint16 *)map, 1024); // *2
	dmaCopy((uint16 *)keyboard_Tiles, (uint16 *)CHAR_BASE_BLOCK_SUB(1), 10816 );
 lcdSwap();	

	return str;
}
void WaitForVblank();
//
//
//void UpdateMenu() // TODO: Update only changed parts.
//{
//	WaitForVblank();
//	
//	ClearScreen();
//	
//  iprintf("\tFrodo DS\nPorted by Troy Davis(GPF)\n");
//  iprintf("\thttp://gpf.dcemu.co.uk\n");
//  iprintf("%d files detected.\nPlease select the d64 file\nto mount on drive 8\n", tot);
//	
//	// Draw 18 entries.
//	for (int i = menuscrollptr; i < menuscrollptr + (tot <18 ? tot : 17); i++)
//	{
//			iprintf("  %d. %s\n", i, romlist[i].filename);
//	}
//	
//	iprintf("\x1b[%d;0H>", menupos - menuscrollptr + 6); // Draw the cursor.
//
//
//}
//
//void ClearScreen() // Abstract this.
//{
//	iprintf("\x1b[2J");
//}

/*
  C64 keyboard matrix:

    Bit 7   6   5   4   3   2   1   0
  0    CUD  F5  F3  F1  F7 CLR RET DEL
  1    SHL  E   S   Z   4   A   W   3
  2     X   T   F   C   6   D   R   5
  3     V   U   H   B   8   G   Y   7
  4     N   O   K   M   0   J   I   9
  5     ,   @   :   .   -   L   P   +
  6     /   ^   =  SHR HOM  ;   *   �
  7    R/S  Q   C= SPC  2  CTL  <-  1
*/

#define MATRIX(a,b) (((a) << 3) | (b))




/*
 *  Display constructor: Draw Speedometer/LEDs in window
 */

C64Display::C64Display(C64 *the_c64) : TheC64(the_c64)
{

}


/*
 *  Display destructor
 */

C64Display::~C64Display()
{
}


/*
 *  Prefs may have changed
 */

void C64Display::NewPrefs(Prefs *prefs)
{
}
int bounce=0;
void vblankhandler()
{
	//if (bounce == 1 )
	//{
	//	 REG_BG3X = (28+bounce)<<8; 
	//	 REG_BG3Y = (32+bounce)<<8; 
	//	bounce =0;
	//}
	//else if (bounce == 1 )
	//{
	//	REG_BG3X = (28+bounce)<<8; 
	//	REG_BG3Y = (32+bounce)<<8;  
	//	bounce =1;
	//}
		 
}

/*
 *  Connect to X server and open window
 */
uint8* frontBuffer;
uint8* backBuffer;


extern void InterruptHandler(void);
int init_graphics(void)
{
	// IRQ basic setup
	irqInit();
	irqSet(IRQ_VBLANK, vblankhandler);irqEnable(IRQ_VBLANK);

    //set the mode for 2 text layers and two extended background layers
	powerOn(POWER_ALL); 
	// TODO: Implement blending.
	// "BLEND_CR | BLEND_Y | BLEND_ALPHA" was set here, but these were registers...
	videoSetMode(MODE_5_2D | DISPLAY_BG3_ACTIVE | BG_MOSAIC_ON);  
	

    //set the first two banks as background memory and the third as sub background memory
    //D is not used..if you need a bigger background then you will need to map
    //more vram banks consecutivly (VRAM A-D are all 0x20000 bytes in size)
    vramSetPrimaryBanks(VRAM_A_MAIN_BG_0x06000000, VRAM_B_MAIN_BG_0x06020000, 
                     VRAM_C_SUB_BG , VRAM_D_LCD); 

	
	///////////////set up our bitmap background///////////////////////
	 
	REG_BG3CNT = BG_BMP8_256x256;
 
	
	//these are rotation backgrounds so you must set the rotation attributes:
    //these are fixed point numbers with the low 8 bits the fractional part
    //this basicaly gives it a 1:1 translation in x and y so you get a nice flat bitmap
        
        REG_BG3PA = 1<<8; 
        REG_BG3PB = 0;
        REG_BG3PC = 0;
        REG_BG3PD = 1<<8;
        REG_BG3X = 0;
        REG_BG3Y = 0; 

        frontBuffer = (uint8*)(0x06000000);
  	dmaCopy(NDS_spalsh512_img_bin, BG_GFX, 256*256);
	dmaCopy(NDS_spalsh512_pal_bin, BG_PALETTE, 256*2);      

   bufmem = (uint8*)malloc(512*512);
   backBuffer = (uint8*)malloc(512*512);
   

	if (!fatInitDefault())  
	{
		iprintf("Unable to initialize media device!");
		return -1;
	}

	WaitForVblank();
	WaitForVblank();
	chdir("/rd");
	//if (!ramdiskfsInitDefault())   
	//{
	//	iprintf("Unable to initialize ramdisk device!");
	//	return -1;
	//}

	WaitForVblank();
	WaitForVblank();

	//strcpy(ThePrefs.DrivePath[0], dotextmenu());
	dotextmenu();
	
	REG_BG3CNT = BG_BMP8_512x512;
	REG_BG3PA = DISPLAY_X-54; //((DISPLAY_X / 256) << 8) | (DISPLAY_X % 256) ;//
	REG_BG3PB = 0;
	REG_BG3PC = 0;
	REG_BG3PD = DISPLAY_X-106;//((DISPLAY_Y / 192) << 8) | ((DISPLAY_Y % 192) + (DISPLAY_Y % 192) / 3) ;//
	REG_BG3X = 28<<8;//1<<8;//
	REG_BG3Y = 32<<8;//1<<8;//
    
  return TRUE;

}
int counta,firsttime;
void WaitForVblank()
{
	// TODO: Save battery by halting
	while(REG_VCOUNT!=192);
	while(REG_VCOUNT==192);
	//swiWaitForVBlank(); 
} 
 
/*
 *  Redraw bitmap
 */
int swap=0;
void C64Display::Update(void)
{
//	drive8active=led_state[0];

	//dmaCopyAsynch(bufmem,frontBuffer, 512*512);
	//memcpy(frontBuffer,bufmem, 512*512);
	DC_FlushRange(bufmem, 512*512);
	dmaCopy(bufmem,frontBuffer, (512*512));
	//counta++;
	//printf("count =%d\n",counta);
	//if( (counta >200) && firsttime==0)
	//{
	//	strcpy(ThePrefs.DrivePath[0], dotextmenu());
	//	firsttime=1;
	//}
}



void C64Display::BufSwap(void)
{
	/*
	if (swap)
		swap=0;
	else
		swap=1;
	*/
}


///*
// *  Draw one drive LED
// */
//
//void C64Display::draw_led(int num, int state)
//{
//
//}
//
//
///*
// *  LED error blink 
// */
//
//void C64Display::pulse_handler(...)
//{
//
//}


/*
 *  Draw speedometer
 */

void C64Display::Speedometer(int speed)
{
//	static int delay=0;
//	if(delay>=25) {
//		emu_speed=speed;
//		emu_minutes=(clock()/CLOCKS_PER_SEC)/60;
//		emu_seconds=(clock()/CLOCKS_PER_SEC)%60;
//		delay=0;
//	} else {
//		delay++;
//	}
}


/*
 *  Return pointer to bitmap data
 */

uint8 *C64Display::BitmapBase(void)
{
 /*if (swap){
	//printdbg("bufmem");
	return (uint8 *)bufmem;
 }
 else{
	//printdbg("backBuffer");	*/
	return (uint8 *)bufmem;
	
}
	




/*
 *  Return number of bytes per row
 */

int C64Display::BitmapXMod(void)
{
	return 512;
}

void C64Display::KeyPress(int key, uint8 *key_matrix, uint8 *rev_matrix) {
	int c64_byte, c64_bit, shifted;
	if(!keystate[key]) {
		keystate[key]=1;
		c64_byte=key>>3;
		c64_bit=key&7;
		shifted=key&128;
		c64_byte&=7;
		if(shifted) {
			key_matrix[6] &= 0xef;
			rev_matrix[4] &= 0xbf;
		}
		key_matrix[c64_byte]&=~(1<<c64_bit);
		rev_matrix[c64_bit]&=~(1<<c64_byte);
	}
}

void C64Display::KeyRelease(int key, uint8 *key_matrix, uint8 *rev_matrix) {
	int c64_byte, c64_bit, shifted;
	if(keystate[key]) {
		keystate[key]=0;
		c64_byte=key>>3;
		c64_bit=key&7;
		shifted=key&128;
		c64_byte&=7;
		if(shifted) {
			key_matrix[6] |= 0x10;
			rev_matrix[4] |= 0x40;
		}
		key_matrix[c64_byte]|=(1<<c64_bit);
		rev_matrix[c64_bit]|=(1<<c64_byte);
	}
}

/*
 *  Poll the keyboard
 */
int c64_key=-1;
int lastc64key=-1;
touchPosition m_tp;

void C64Display::PollKeyboard(uint8 *key_matrix, uint8 *rev_matrix, uint8 *joystick)
{
	//int key;

	// b=space
	//key=MATRIX(7,4);
	//if(button_state&B_PRESSED) {
	//	KeyPress(key, key_matrix, rev_matrix);
	//} else {
	//	KeyRelease(key, key_matrix, rev_matrix);
	//}

	// select=shift/run-stop
	//key=MATRIX(7,7);
	//key|=128;
	//if(button_state&SELECT_PRESSED) {
	//	KeyPress(key, key_matrix, rev_matrix);
	//} else {
	//	KeyRelease(key, key_matrix, rev_matrix);
	//}

	// check button-mapped keys
//	if(bkey_pressed) {
//		KeyPress(bkey, key_matrix, rev_matrix);
//		bkey_pressed=0;
//	}
//	if(bkey_released) {
//		KeyRelease(bkey, key_matrix, rev_matrix);
//		bkey_released=0;
//	}
//
//	// check virtual keyboard
//	if(keyboard_enabled) {
//		if(vkey_pressed) {
//			KeyPress(vkey, key_matrix, rev_matrix);
//			vkey_pressed=0;
//		}
//		if(vkey_released) {
//			KeyRelease(vkey, key_matrix, rev_matrix);
//			vkey_released=0;
//			//vkey=0;
//		}
//	}

	scanKeys();

        if (lastc64key >-1 )
          KeyRelease(lastc64key, key_matrix, rev_matrix); 
        
        if(keysHeld() & KEY_TOUCH) {
			touchRead(&m_tp);
		} else if (keysUp() & KEY_TOUCH) {
			unsigned short c;
			unsigned int tilex, tiley;

			tilex = m_tp.px/8;
			tiley = (m_tp.px - 96)/8;

			if(tilex>=1 && tilex<=31 && tiley<=12)
			{
				if(m_Mode==KB_NORMAL)
					c = keyboard_Hit[tilex+(tiley*32)];
				else
					c = keyboard_Hit_Shift[tilex+(tiley*32)];

				if(c==RET) // Return
				{
					//consolePrintChar('\n');
					//strcpy(text, "");
					c64_key = MATRIX(0,1);
					KeyPress(c64_key, key_matrix, rev_matrix);
					lastc64key=c64_key;
				} else
				if(c==BSP) // Backspace
				{
					c64_key = MATRIX(0,0);
					KeyPress(c64_key, key_matrix, rev_matrix);
					lastc64key=c64_key;
					
				} else 
				if(c==RUN)
				{
					c64_key = MATRIX(7,7); 
					KeyPress(c64_key, key_matrix, rev_matrix);
					lastc64key=c64_key;
										
				} else 				
				if(c==SLK || c==SHF)
				{
					if(m_Mode==KB_NORMAL) {
						dmaCopy((uint16 *)keyboard_Map,(uint16 *)map, 1024);
						m_Mode = KB_SHIFT;
					} else {
						dmaCopy((uint16 *)keyboard_Map+512,(uint16 *)map, 1024);
						m_Mode = KB_NORMAL;
					}
				} else 
				{
					//if(strlen(text)<MAX_TEXT-1 && c!=0x0) {
					if(c!=0x0) {
						//strcat(text, buf);
						//consolePrintChar(c);
						
						switch (c) { 
                    		case 'A': c64_key = MATRIX(1,2); break;
                    		case 'B': c64_key = MATRIX(3,4); break;
                    		case 'C': c64_key = MATRIX(2,4); break;
                    		case 'D': c64_key = MATRIX(2,2); break;
                    		case 'E': c64_key = MATRIX(1,6); break;
                    		case 'F': c64_key = MATRIX(2,5); break;
                    		case 'G': c64_key = MATRIX(3,2); break;
                    		case 'H': c64_key = MATRIX(3,5); break;
                    		case 'I': c64_key = MATRIX(4,1); break;
                    		case 'J': c64_key = MATRIX(4,2); break;
                    		case 'K': c64_key = MATRIX(4,5); break;
                    		case 'L': c64_key = MATRIX(5,2); break;
                    		case 'M': c64_key = MATRIX(4,4); break;
                    		case 'N': c64_key = MATRIX(4,7); break;
                    		case 'O': c64_key = MATRIX(4,6); break;
                    		case 'P': c64_key = MATRIX(5,1); break;
                    		case 'Q': c64_key = MATRIX(7,6); break;
                    		case 'R': c64_key = MATRIX(2,1); break;
                    		case 'S': c64_key = MATRIX(1,5); break;
                    		case 'T': c64_key = MATRIX(2,6); break;
                    		case 'U': c64_key = MATRIX(3,6); break;
                    		case 'V': c64_key = MATRIX(3,7); break;
                    		case 'W': c64_key = MATRIX(1,1); break;
                    		case 'X': c64_key = MATRIX(2,7); break;
                    		case 'Y': c64_key = MATRIX(3,1); break;
                    		case 'Z': c64_key = MATRIX(1,4); break;
                    		
                    		case ' ': c64_key = MATRIX(7,4); break; 
                    		
                        	case '0': c64_key = MATRIX(4,3); break;
                        	case '1': c64_key = MATRIX(7,0); break;
                        	case '2': c64_key = MATRIX(7,3); break;
                        	case '3': c64_key = MATRIX(1,0); break;
                        	case '4': c64_key = MATRIX(1,3); break;
                        	case '5': c64_key = MATRIX(2,0); break;
                        	case '6': c64_key = MATRIX(2,3); break;
                        	case '7': c64_key = MATRIX(3,0); break;
                        	case '8': c64_key = MATRIX(3,3); break;
                        	case '9': c64_key = MATRIX(4,0); break;   
                        	case '*': c64_key = MATRIX(6,1); break; 
                        	case ':': c64_key = MATRIX(5,5); break;
                        	case ';': c64_key = MATRIX(6,2); break;
                        	case '=': c64_key = MATRIX(6,5); break;
                        	case '/': c64_key = MATRIX(6,7); break;
                        	
                        	case ATT: c64_key = MATRIX(5,6); break;
							
                        	case ',': c64_key = MATRIX(5,7); break;
							case '.': c64_key = MATRIX(5,4); break;
							case '+': c64_key = MATRIX(5,0); break;
							case '-': c64_key = MATRIX(5,3); break;
							
							case RST: c64_key = MATRIX(7,7); break;
                        	case CLR: c64_key = MATRIX(6,3); break;
                            case LFA: c64_key = MATRIX(7,1); break;
                            case UPA: c64_key = MATRIX(6,6); break;
                            case PND: c64_key = MATRIX(6,0); break;
                            
                            case CUP: c64_key = MATRIX(0,7); break;
                            case CDL: c64_key = MATRIX(0,2); break;
                              
                    		case F_1: c64_key = MATRIX(0,4); break;
                    		case F_3: c64_key = MATRIX(0,5); break;
                    		case F_5: c64_key = MATRIX(0,6); break;
                    		case F_7: c64_key = MATRIX(0,3); break;
                            
                                		
                            default :  c64_key = -1; break;

                        }
						if (c64_key < 0)
                        		return; 
                        if(m_Mode==KB_NORMAL) 
                        {
                               c64_key= c64_key| 0x80;              
                        }                      		
						KeyPress(c64_key, key_matrix, rev_matrix);
						lastc64key=c64_key;



					}
				}
			}
		}

}


/*
 *  Check if NumLock is down (for switching the joystick keyboard emulation)
 */

bool C64Display::NumLock(void)
{
    return false;
}


/*
 *  Allocate C64 colors
 */


typedef struct {
    int r;
    int g;
    int b;
} plt;

static plt palette[256];

void C64Display::InitColors(uint8 *colors)
{
	int i; 

//	// set up 8bpp mode palette
//	palette_r=(uint8 *)RGB15(255,0,0);
//	palette_g=(uint8 *)RGB15(0,255,0);
//	palette_b=(uint8 *)RGB15(0,0,255);
//	ui_set_palette();

  for (i = 0; i < 16; i++) {
		palette[i].r = palette_red[i]>>3;
		palette[i].g = palette_green[i]>>3;
		palette[i].b = palette_blue[i]>>3;
    BG_PALETTE[i]=RGB15(palette_red[i]>>3,palette_green[i]>>3,palette_blue[i]>>3);
  }


	// frodo internal 8 bit palette
	for(i=0; i<256; i++) {
		colors[i] = i & 0x0f;
	}
}


/*
 *  Show a requester (error message)
 */

long int ShowRequester(char *a,char *b,char *)
{
	iprintf("%s: %s\n", a, b);
	return 1;
}

