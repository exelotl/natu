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

// this is
// VERSION 1.8e

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "defs.h"
#include "mas.h"
#include "mod.h"
#include "s3m.h"
#include "xm.h"
#include "it.h"
#include "gba.h"
#include "nds.h"
#include "files.h"
#include "errors.h"
#include "simple.h"
#include "msl.h"
#include "systems.h"
#include "wav.h"
#include "samplefix.h"

extern void kiwi_start(void);

int target_system;

bool ignore_sflags;
int PANNING_SEP;

int number_of_inputs;

#define USAGE "\n\
************************\n\
* Maxmod Utility "PACKAGE_VERSION" *\n\
************************\n\
\n\
Usage:\n\
  mmutil [options] input files ...\n\
\n\
 Input may be MOD, S3M, XM, IT, and/or WAV\n\
\n\
.------------.----------------------------------------------------.\n\
| Option     | Description                                        |\n\
|------------|----------------------------------------------------|\n\
| -o<output> | Set output file.                                   |\n\
| -h<header> | Set header output file.                            |\n\
| -m         | Output MAS file rather than soundbank.             |\n\
| -d         | Use for NDS projects.                              |\n\
| -b         | Create test ROM. (use -d for .nds, otherwise .gba) |\n\
| -i         | Ignore sample flags.                               |\n\
| -v         | Enable verbose output.                             |\n\
| -p         | Set initial panning separation for MOD/S3M.        |\n\
`-----------------------------------------------------------------'\n\
\n\
.-----------------------------------------------------------------.\n\
| Examples:                                                       |\n\
|-----------------------------------------------------------------|\n\
| Create DS soundbank file (soundbank.bin) from input1.xm         |\n\
| and input2.it Also output header file (soundbank.h)             |\n\
|                                                                 |\n\
| mmutil -d input1.xm input2.it -osoundbank.bin -hsoundbank.h     |\n\
|-----------------------------------------------------------------|\n\
| Create test GBA ROM from two inputs                             |\n\
|                                                                 |\n\
| mmutil -b input1.mod input2.s3m -oTEST.gba                      |\n\
|-----------------------------------------------------------------|\n\
| Create test NDS ROM from three inputs                           |\n\
|                                                                 |\n\
| mmutil -d -b input1.xm input2.s3m testsound.wav                 |\n\
`-----------------------------------------------------------------'\n\
 www.maxmod.org\n\
"

void print_usage( void )
{
	printf( USAGE );
}

void print_error( int err )
{
	switch( err )
	{
	case ERR_INVALID_MODULE:
		printf( "Invalid module!\n" );
		break;
	case ERR_MANYARGS:
		printf( "Too many arguments!\n" );
		break;
	case ERR_NOINPUT:
		printf( "No input file!\n" );
		break;
	case ERR_NOWRITE:
		printf( "Unable to write file!\n" );
		break;
	case ERR_BADINPUT:
		printf( "Cannot parse input filename!\n" );
		break;
	}
}

int GetYesNo( void )
{
	char c = 0;
	c = tolower(getchar());
	while( getchar() != '\n' );
	while( c != 'y' && c != 'n' )
	{
		printf( "Was that a yes? " );
		c = tolower(getchar());
		while( getchar() != '\n' );
	}
	return c == 'y' ? 1 : 0;
}

//------------------------------------------------------------------------------------------------
int main(int argc, char* argv[])
//------------------------------------------------------------------------------------------------
{
	char* str_input=NULL;
	char* str_output=NULL;
	char* str_header=NULL;
	
	MAS_Module mod;

	int strl;

	int input_type=0;

	int strp;
	int strpi;

	bool g_flag=false;
	bool v_flag=false;
	bool m_flag=false;
	bool z_flag=false;
	int a;

	int output_size;

	ignore_sflags=false;

	number_of_inputs=0;

	PANNING_SEP = 128;

	//------------------------------------------------------------------------
	// parse arguments
	//------------------------------------------------------------------------
	
	for( a = 1; a < argc; a++ )
	{
		if( argv[a][0] == '-' )
		{
			if( argv[a][1] == 'b' )
				g_flag = true;
			else if( argv[a][1] == 'v' )
				v_flag = true;
			else if( argv[a][1] == 'd' )
				target_system = SYSTEM_NDS;
			else if( argv[a][1] == 'i' )
				ignore_sflags = true;
			else if( argv[a][1] == 'p' )
				PANNING_SEP = ((argv[a][2] - '0') * 256)/9;
			else if( argv[a][1] == 'o' )
				str_output = argv[a]+2;
			else if( argv[a][1] == 'h' )
				str_header = argv[a]+2;
			else if( argv[a][1] == 'm' )
				m_flag = true;
			else if( argv[a][1] == 'z' )
				z_flag = true;
		}
		else if( !str_input )
		{
			str_input = argv[a];
			number_of_inputs=1;
		}
		else
		{
			number_of_inputs++;
		}
	}
	
	if( number_of_inputs==0 )
	{
		print_usage();
		return 0;
	}
	
	if( z_flag )
	{
		kiwi_start();
		file_open_read( str_input );
		Sample s;
		
		Load_WAV( &s, false,false );
		
		s.name[0] = '%';
		s.name[1] = 'c';
		s.name[2] = 0;
		
		FixSample( &s );
		
		file_close_read();
		file_open_write( str_output );
		
		int i;
		for( i = 0; i < s.sample_length; i++ )
			write8( ((u8*)s.data)[i] );
		
		file_close_write();
		printf("okay\n");
		return 0;
	}

	if( m_flag & g_flag )
	{
		printf("-m and -g cannot be combined.\n");
		return -1;
	}
	
	if( m_flag && number_of_inputs != 1 )
	{
		printf( "-m only supports one input.\n" );
		return -1;
	}

	//---------------------------------------------------------------------------
	// m/g generate output target if not given
	//---------------------------------------------------------------------------

	if( m_flag || g_flag)
	{
		if( !str_output )
		{
			if( number_of_inputs == 1 )
			{
				if( strlen(str_input) < 4 )
				{
					print_error( ERR_BADINPUT );
					return -1;
				}
				strp = strlen(str_input);
				str_output = (char*)malloc( strp+2 );
				strcpy(str_output, str_input);
				strp=strlen(str_output)-1;
				
				for( strpi=strp; str_output[strpi] != '.' && strpi != 0; strpi-- );
				if( strpi == 0 )
				{
					print_error( ERR_BADINPUT );
					return -1;
				}
				
				str_output[strpi++] = '.';
				if( !g_flag )
				{
					str_output[strpi++] = 'm';
					str_output[strpi++] = 'a';
					str_output[strpi++] = 's';
					str_output[strpi++] = 0;
				}
				else
				{
					if( target_system == SYSTEM_GBA )
					{
						str_output[strpi++] = 'g';
						str_output[strpi++] = 'b';
						str_output[strpi++] = 'a';
						str_output[strpi++] = 0;
					}
					else if( target_system == SYSTEM_NDS )
					{
						str_output[strpi++] = 'n';
						str_output[strpi++] = 'd';
						str_output[strpi++] = 's';
						str_output[strpi++] = 0;
					}
					else
					{
						// error!
					}
				}
				str_output[strpi++] = 0;
			}
			else
			{
				printf( "No output file! (-o option)\n" );
				return -1;
			}
		}
	}
	
	// catch filename too small
	strl=strlen(str_input);
	if( strl < 4 )
	{
		print_error( ERR_BADINPUT );
		return -1;
	}

	if( m_flag )
	{
		if( file_open_read( str_input ) )
		{
			printf( "Cannot open %s for reading!\n", str_input );
			return -1;
		}
		input_type = get_ext( str_input );

		switch( input_type )
		{
		//------------------------------------------------------
		case INPUT_TYPE_MOD:
		//------------------------------------------------------
			if( Load_MOD( &mod, v_flag ) )
			{
				print_error( ERR_INVALID_MODULE );
				file_close_read();
				return -1;
			}
			break;
		//------------------------------------------------------
		case INPUT_TYPE_S3M:
		//------------------------------------------------------
			if( Load_S3M( &mod, v_flag ) )
			{
				print_error( ERR_INVALID_MODULE );
				file_close_read();
				return -1;
			}
			break;
		//------------------------------------------------------
		case INPUT_TYPE_XM:
		//------------------------------------------------------
			if( Load_XM( &mod, v_flag ) )
			{
				print_error( ERR_INVALID_MODULE );
				file_close_read();
				return -1;
			}
			break;
		//------------------------------------------------------
		case INPUT_TYPE_IT:
		//------------------------------------------------------
			if( Load_IT( &mod, v_flag ) )
			{
				// ERROR!
				print_error( ERR_INVALID_MODULE );
				file_close_read();
				return -1;
			}
			break;
		}
		
		file_close_read();

		if( file_exists( str_output ) )
		{
			printf( "Output file exists! Overwrite? (y/n) " );
			if( !GetYesNo() )
			{
				printf( "Operation Canceled!\n" );
				return -1;
			}
			
		}

		if( file_open_write( str_output ) )
		{
			print_error( ERR_NOWRITE );
			return -1;
		}

		printf( "Writing .mas............\n" );

		// output MAS
		output_size = Write_MAS( &mod, v_flag, false );

		
		file_close_write();

		Delete_Module( &mod );

		if( v_flag )
		{
#ifdef SUPER_ASCII
			printf( "Success! \x02 \n" );
#else
			printf( "Success! :) \n" );
#endif
		}
	}
	else if( g_flag )
	{
		int i;

		MSL_Create( argv, argc, "tempSH308GK.bin", 0, v_flag );

		if( file_exists( str_output ) )
		{
			printf( "Output file exists! Overwrite? (y/n) " );
			if( !GetYesNo() )
			{
				printf( "Operation Canceled!\n" );
				return -1;
			}
			
		}

		if( file_open_write( str_output ) )
		{
			print_error( ERR_NOWRITE );
			return -1;
		}

		if( target_system == SYSTEM_GBA )
		{
			if( v_flag )
				printf( "Making GBA ROM.......\n" );
			Write_GBA();
		}
		else if( target_system == SYSTEM_NDS )
		{
			if( v_flag )
				printf( "Making NDS ROM.......\n" );
			Write_NDS();
		}

		output_size = file_size( "tempSH308GK.bin" );
		file_open_read( "tempSH308GK.bin" );

		if( target_system == SYSTEM_GBA )
		{
			write32( (output_size < 248832) ? 1 : 0 );
		}

		for( i = 0; i < output_size; i++ )
		{
			write8( read8() );
		}

		file_close_read();
		file_close_write();
		
		file_delete( "tempSH308GK.bin" );

		if( g_flag && target_system == SYSTEM_NDS )
			Validate_NDS( str_output, output_size );
		
		if( v_flag )
		{
			printf( "Success! :D\n" );

			if( g_flag && target_system == SYSTEM_GBA )
			{
				if( output_size < 262144 )
				{
					printf("ROM can be multibooted!!\n" );
				}
			}
		}	
	}
	else
	{
		MSL_Create( argv, argc, str_output, str_header, v_flag );
	}
	return 0;
}
