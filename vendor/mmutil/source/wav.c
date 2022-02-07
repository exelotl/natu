/****************************************************************************
 *                                                          __              *
 *                ____ ___  ____ __  ______ ___  ____  ____/ /              *
 *               / __ `__ \/ __ `/ |/ / __ `__ \/ __ \/ __  /               *
 *              / / / / / / /_/ />  </ / / / / / /_/ / /_/ /                *
 *             /_/ /_/ /_/\__,_/_/|_/_/ /_/ /_/\____/\__,_/                 *
 *                                                                          *
 *         Copyright (c) 2008, Mukunda Johnson (mukunda@maxmod.org)         *
 *                                                                          *
 * Permission to use, copy, modify, and/or distribute this software for any *
 * purpose with or without fee is hereby granted, provided that the above   *
 * copyright notice and this permission notice appear in all copies.        *
 *                                                                          *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES *
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF         *
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR  *
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES   *
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN    *
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF  *
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.           *
 ****************************************************************************/

// WAV file loader

#include <stdlib.h>
#include <string.h>
#include "defs.h"
#include "files.h"
#include "mas.h"
#include "wav.h"
#include "simple.h"
#include "samplefix.h"

int Load_WAV( Sample* samp, bool verbose, bool fix )
{
	unsigned int file_size;
	unsigned int bit_depth = 8;
	unsigned int hasformat = 0;
	unsigned int hasdata = 0;
	unsigned int chunk_code;
	unsigned int chunk_size;
	unsigned int num_channels = 0;
	
	if( verbose )
		printf( "Loading WAV file...\n" );
	
	// initialize data
	memset( samp, 0, sizeof( Sample ) );
	
	file_size = file_tell_size();
	
	read32();						// "RIFF"
	read32();						// filesize-8
	read32();						// "WAVE"
	
	while( 1 )
	{
		// break on end of file
		if( file_tell_read() >= file_size ) break;
		
		// read chunk code and length
		chunk_code = read32();
		chunk_size = read32();
		
		// parse chunk code
		switch( chunk_code )
		{
		//---------------------------------------------------------------------
		case ' tmf':	// format chunk
		//---------------------------------------------------------------------
			
			// check compression code (1 = PCM)
			if( read16() != 1 )
			{
				if( verbose )
					printf( "Unsupported WAV format.\n" );
				return LOADWAV_UNKNOWN_COMP;
			}
			
			// read # of channels
			num_channels = read16();
			
			// read sampling frequency
			samp->frequency = read32();
			
			// skip average something, wBlockAlign
			read32();
			read16();
			
			// get bit depth, catch unsupported values
			bit_depth = read16();
			if( bit_depth != 8 && bit_depth != 16 )
			{
				if( verbose )
					printf( "Unsupported bit-depth.\n" );
				return LOADWAV_UNSUPPORTED_BD;
			}
			
			if( bit_depth == 16 )
				samp->format |= SAMPF_16BIT;
			
			// print verbose data
			if( verbose )
			{
				printf( "Sample Rate...%i\n", samp->frequency );
				printf( "Bit Depth.....%i-bit\n", bit_depth );
			}
			
			// skip the rest of the chunk (if any)
			if( (chunk_size - 0x10) > 0 )
				skip8( (chunk_size - 0x10) );
			
			hasformat = 1;
			break;
			
		//---------------------------------------------------------------------
		case 'atad':	// data chunk
		//---------------------------------------------------------------------
		{
			int t, c, dat;
			
			if( !hasformat )
			{
				return LOADWAV_CORRUPT;
			}
			
			if( verbose )
				printf( "Loading Sample Data...\n" );
			
			// clip chunk size against end of file (for some borked wavs...)
			{
				int br = file_size - file_tell_read();
				chunk_size = chunk_size > br ? br : chunk_size;
			}
			
			samp->sample_length = chunk_size / (bit_depth/8) / num_channels;
			samp->data = malloc( chunk_size );
			
			// read sample data
			for( t = 0; t < samp->sample_length; t++ )
			{
				dat = 0;
				
				// for multi-channel samples, get average value
				for( c = 0; c < num_channels; c++ )
				{
					dat += bit_depth == 8 ? ((int)read8()) - 128 : ((short)read16());
				}
				dat /= num_channels;
				
				if( bit_depth == 8 )
				{
					((u8*)samp->data)[t] = dat + 128;
				}
				else
				{
					((u16*)samp->data)[t] = dat + 32768;
				}
			}
			
			hasdata = 1;
			
			break;
		}
		//------------------------------------------------------------------------------
		case 'lpms':	// sampler chunk
		//------------------------------------------------------------------------------
		{
			int pos;
			skip8( 	4		// manufacturer
					+4		// product
					+4		// sample period
					+4		// midi unity note
					+4		// midi pitch fraction
					+4		// smpte format
					+4		// smpte offset
					);
			int num_sample_loops = read32();
			
			read32();		// sample data
			
			pos = 36;
			
			// check for sample looping data
			if( num_sample_loops )
			{
				read32();	// cue point ID
				int loop_type = read32();
				pos += 8;
				
				if( loop_type < 2 )
				{
					// sample    | internal
					// 0=forward | 1
					// 1=bidi    | 2
					samp->loop_type = loop_type + 1;
					samp->loop_start = read32();
					samp->loop_end = read32();
					
					// clip loop start against sample length
					if( samp->loop_end > samp->sample_length ) {
						samp->loop_end = samp->sample_length;
					}
					
					// disable tiny loop
					// catch invalid loop
					if( (samp->loop_start > samp->sample_length) ||
						(samp->loop_end - samp->loop_start < 16) ) {
						
						samp->loop_type = 0;
						samp->loop_start = 0;
						samp->loop_end = 0;
					}
					
					// ignore fractional
					// ignore play count
					pos += 8;
				}
			}
			
			skip8( chunk_size - pos );
			break;
		}	
		default:
			skip8( chunk_size );
		}
	}
	
	if( hasformat && hasdata )
	{
		if( fix ) FixSample( samp );
		return LOADWAV_OK;
	}
	else
	{
		return LOADWAV_CORRUPT;
	}
}
