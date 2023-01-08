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
#include <maxmod9.h>

#include <stdio.h> 

DigitalRenderer* p;
bool paused = false;

mm_word SoundMixCallback(mm_word len, mm_addr stream, mm_stream_formats format)
{
	if(paused) {
		memset(stream, 0x0, len*2);
	} else
	{
		p->calc_buffer((int16*)stream, len*2);
	}
	return len;
}

void DigitalRenderer::init_sound(void)
{
	p = this;

	mm_ds_system sys;
	memset(&sys, 0, sizeof(sys));
	sys.fifo_channel = FIFO_MAXMOD;
	DC_FlushAll();
	mmInit(&sys);

	mm_stream mstream;
	memset(&mstream, 0, sizeof(mstream));
	mstream.sampling_rate = SAMPLE_FREQ;
	mstream.buffer_length = 0x138 * 2;
	mstream.callback = SoundMixCallback;
	mstream.format = MM_STREAM_16BIT_MONO;
	mstream.timer = MM_TIMER2;
	mstream.manual = false;
	DC_FlushAll();
	mmStreamOpen(&mstream);

	ready = true;
}

DigitalRenderer::~DigitalRenderer() 
{

}

void DigitalRenderer::EmulateLine(void)
{
	sample_buf[sample_in_ptr] = volume;
	sample_in_ptr = (sample_in_ptr + 1) % SAMPLE_BUF_SIZE;
}

void DigitalRenderer::Pause(void)
{
	paused = true;
	//mmPause();	
}

void DigitalRenderer::Resume(void)
{
	//mmResume();
	paused = false;
}
