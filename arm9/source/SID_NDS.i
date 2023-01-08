/*
 * SID_NDS.i
 *
 * RISC OS specific parts of the sound emulation
 * Frodo (C) 1994-1997,2002 Christian Bauer
 * Acorn port by Andreas Dehmel, 1997
 *
 */

#include "VIC.h" 
#include <nds.h>
#include "../../arm7/source/soundcommon.h"

#include <stdio.h> 

u32 framecounter = 0,soundoffset = 0;

int16 *sbuffer;
DigitalRenderer* p;

int sndbufsize;
int count = 0;
bool reset = false;
bool paused = false;
void SoundMixCallback(void *stream,u32 len)
{

	if (!p->ready)
		return;

        if(paused == true) {

                memset(stream, 0x0, len*2);

        } else
        
         {

               // memcpy(stream, sbuffer, len);
			 p->calc_buffer((int16*)stream, len*2);
             
        }

}

void MixSound(void)
{
	int remain;

	// TODO
	/* if(soundsystem->format == 8)
	{
		if((soundsystem->soundcursor + soundsystem->numsamples) > soundsystem->buffersize)
		{
			SoundMixCallback(&soundsystem->mixbuffer[soundsystem->soundcursor],soundsystem->buffersize - soundsystem->soundcursor);
			remain = soundsystem->numsamples - (soundsystem->buffersize - soundsystem->soundcursor);
			SoundMixCallback(soundsystem->mixbuffer,remain);
		}
		else
		{
			SoundMixCallback(&soundsystem->mixbuffer[soundsystem->soundcursor],soundsystem->numsamples);
		}
	}
	else
	{
		if((soundsystem->soundcursor + soundsystem->numsamples) > (soundsystem->buffersize >> 1))
		{
			SoundMixCallback(&soundsystem->mixbuffer[soundsystem->soundcursor << 1],(soundsystem->buffersize >> 1) - soundsystem->soundcursor);
			remain = soundsystem->numsamples - ((soundsystem->buffersize >> 1) - soundsystem->soundcursor);
			SoundMixCallback(soundsystem->mixbuffer,remain);
		}
		else
		{
			SoundMixCallback(&soundsystem->mixbuffer[soundsystem->soundcursor << 1],soundsystem->numsamples);
		}
	} */
}

void InterruptHandler(void)
{
	framecounter++;
	if (framecounter > 1000) p->ready = true;
}
void FiFoHandler(void)
{
/*
	u32 command;
	while ( !(REG_IPC_FIFO_CR & (IPC_FIFO_RECV_EMPTY)) ) 
	{
		
		command = REG_IPC_FIFO_RX;

		switch(command)
		{
		case FIFO_NONE:
			break;
		case UPDATEON_ARM9:
			//printf("FiFoHandler\n");
			REG_IME = 0;
			MixSound();
			REG_IME = 1;
			SendCommandToArm7(MIXCOMPLETE_ONARM9);
			break;
		}
	}
*/
}


void DigitalRenderer::init_sound(void)
{
	/* p = this;
	 //Try starting up the renderer
	sndbufsize = 0x138*4;
	sound_buffer = new int16[sndbufsize];
	sbuffer=sound_buffer;

	irqSet(IRQ_VBLANK,&InterruptHandler);
	irqSet(IRQ_FIFO_NOT_EMPTY,&FiFoHandler);
	irqEnable(IRQ_FIFO_NOT_EMPTY);

	REG_IPC_FIFO_CR = IPC_FIFO_ENABLE | IPC_FIFO_SEND_CLEAR | IPC_FIFO_RECV_IRQ;
	//irqEnable(IRQ_VBLANK);	

	SoundSystemInit(SAMPLE_FREQ,sndbufsize,0,16);
	SoundStartMixer(); */
}




DigitalRenderer::~DigitalRenderer() 
{
  if (ready)
  {
    delete sbuffer;
  }
}

void DigitalRenderer::EmulateLine(void)
{
	/*REG_IME = 0;*/
	static int divisor = 0;
	static int to_output = 0;
	static int buffer_pos = 0;

	if (!ready)
		return;

	sample_buf[sample_in_ptr] = volume;
	sample_in_ptr = (sample_in_ptr + 1) % SAMPLE_BUF_SIZE;

	//// Now see how many samples have to be added for this line
	//divisor += SAMPLE_FREQ;
	//while (divisor >= 0)
	//	divisor -= TOTAL_RASTERS*SCREEN_FREQ, to_output++;

	//// Calculate the sound data only when we have enough to fill
	//// the buffer entirely
	//if ((buffer_pos + to_output) >= sndbufsize) {
	//	int datalen = sndbufsize - buffer_pos;
	//	to_output -= datalen;
	//	calc_buffer(sound_buffer + buffer_pos, datalen*2);
	//	//write(devfd, sound_buffer, sndbufsize*2);
	//	buffer_pos = 0;
	//}
	/*REG_IME = 1;*/
}





void DigitalRenderer::Pause(void)
{
    paused = true;
	
}




void DigitalRenderer::Resume(void)
{
    paused = false;
}
