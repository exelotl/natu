//
// io hooks for using printf
//
//! \file tte_iohook.c
//! \author J Vijn
//! \date 20070517 - 20070517
//
// === NOTES ===

#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <sys/iosupport.h>

#include "tonc_tte.h"
#include "tonc_nocash.h"


static int sConInitialized= 0;

uint utf8_decode_char(const char *ptr, char **endptr);

// --------------------------------------------------------------------
// CONSTANTS
// MACROS
// CLASSES
// GLOBALS
// PROTOTYPES
// FUNCTIONS

const devoptab_t tte_dotab_stdout=
{
	"ttecon",
	0,
	NULL,
	NULL,
	tte_con_write,
	NULL,
	NULL,
	NULL
};

const devoptab_t tte_dotab_nocash=
{
	"ttenocash",
	0,
	NULL,
	NULL,
	tte_con_nocash,
	NULL,
	NULL,
	NULL
};


//! Init stdio capabilities.
void tte_init_con()
{
	devoptab_list[STD_OUT] = &tte_dotab_stdout;
	devoptab_list[STD_ERR] = &tte_dotab_nocash;
	setvbuf(stdout, NULL , _IONBF, 0);
	setvbuf(stderr, NULL , _IONBF, 0);

	sConInitialized = 1;
}


//! Parse for VT100-sequences
/*!	Taken librally from libgba.<br>
	See <a href="http://local.wasp.uwa.edu.au/~pbourke/dataformats/vt100/">
	here</a> for a full overview.
	\param text	Sequence string, starting at the '['.
	\todo: check for buffer overflow.
*/
int tte_cmd_vt100(const char *text)
{
	int ch;
	const char *str= text;

	TTC *tc= tte_get_context();
	int x, y;
	int x2, y2, dx, dy;

	while( (ch=*str) != '\0')
	{
		str++;
		switch(ch)
		{
		case 'A':	// Cursor up, with clamp.
			siscanf(text,"[%dA", &dy);
			y= tc->cursorY - dy*tc->font->charH;
			tc->cursorY= (y >= tc->marginTop ? y : tc->marginTop);
			return str-text;

		case 'B':	// Cursor down, with clamp.
			siscanf(text,"[%dB", &dy);
			y = tc->cursorY + dy*tc->font->charH;
			y2= tc->marginBottom-tc->font->charH;
			tc->cursorY= (y <= y2 ? y : y2);
			return str-text;

		case 'C':	// Cursor right, with clamp.
			siscanf(text,"[%dC", &dx);
			x = tc->cursorX + dx*tc->font->cellW;
			x2= tc->marginRight- tc->font->cellW;
			tc->cursorX= (x <= x2 ? x : x2);
			return str-text;

		case 'D':	// Cursor left, with clamp.
			siscanf(text,"[%dD", &dx);
			x = tc->cursorX - dx*tc->font->cellW;
			tc->cursorX= (x >= tc->marginLeft ? x : tc->marginLeft);
			return str-text;

		case 'H':	// Set position.
		case 'f':
			siscanf(text,"[%d;%d", &x, &y);
			tc->cursorX= x;
			tc->cursorY= y;
			return str-text;

		case 'J':	// Clear screen
			if(text[1] == '2')
				tte_erase_screen();
			return str-text;

		case 'K':	// Clear rest of line
			{
				switch(text[1])
				{
				case 1:		// Line up to here
					tte_erase_rect(0, tc->cursorY, 
						tc->cursorX, tc->cursorY+tc->font->charH);
					break;
				case 2:		// Entire line
					tte_erase_line();
					break;
				default:
					tte_erase_rect(tc->cursorX, tc->cursorY, 
						tc->marginRight, tc->cursorY+tc->font->charH);
				}
				return str-text;
			}

		case 's':	// Save curson position
			tc->savedX = tc->cursorX;
			tc->savedY = tc->cursorY;
			return str-text;

		case 'u':	// Restore cursor position
			tc->cursorX = tc->savedX;
			tc->cursorX = tc->savedY;
			return str-text;
		}
	}

	// Couldn't find anything: use as normal string
	return 0;
}


ssize_t tte_con_nocash(struct _reent *r, int fd, const char *text, size_t len)
{
	if(text==NULL || len<=0)
		return -1;

	int ii, count;
	for(ii=0; ii<len; ii += 80)
	{
		count= ii+80>len ? len-ii : 80;
		strncpy(nocash_buffer, &text[ii], count);
		nocash_buffer[count]= '\0';
		nocash_message();		
	}
	return len;

}

//! Internal routine for stdio functionality.
/*!	\note	While this function 'works', I am not 100% sure I'm 
		handling everything correctly.
*/
ssize_t tte_con_write(struct _reent *r, int fd, const char *text, size_t len)
{
	if(!sConInitialized || !text || len<=0)
		return -1;

	// The buffer is not zeroed, so PLEASE use len properly.

	uint ch, gid;
	char *str= (char*)text;
	const char *end= text+len;

	TTC *tc= tte_get_context();
	TFont *font;

	while( (ch= *str) != 0 && str < end)
	{
		str++;
		switch(ch)
		{
		// --- Newline/carriage return ---
		case '\r':
			if(str[0] == '\n')	// deal with CRLF pair
				str++;
			// FALLTHRU
		case '\n':
			tc->cursorY += tc->font->charH;
			tc->cursorX  = tc->marginLeft;
			break;	
					
		// --- Tab ---
		case '\t':
			tc->cursorX= (tc->cursorX/TTE_TAB_WIDTH+1)*TTE_TAB_WIDTH;
			break;					

		// --- VT100 sequence ( ESC[foo; ) ---
		case 0x1B:
			if(str[0] == '[')
				str += tte_cmd_vt100(str);
			break;

		// --- Normal char ---
		default:
			// Command sequence
			if(ch=='#' && str[0]=='{')
			{
				str= tte_cmd_default(str+1);
				break;
			}
			// Escaped command: skip '\\' and print '#'
			else if(ch=='\\' && str[0]=='#')
				ch= *str++;
			// Check for UTF8 code
			else if(ch>=0x80)
				ch= utf8_decode_char(str-1, &str);

			// Get glyph index and call renderer
			font= tc->font;
			gid= ch - font->charOffset;
			if(tc->charLut)
				gid= tc->charLut[gid];

			// Character wrap
			int charW= font->widths ? font->widths[gid] : font->charW;
			if(tc->cursorX+charW > tc->marginRight)
			{
				tc->cursorY += font->charH;
				tc->cursorX  = tc->marginLeft;				
			}

			// Draw and update position
			tc->drawgProc(gid);
			tc->cursorX += charW;
		}
	}

	// Return characters used
	//# PONDER: This seems to 'work', but is it right?
	return str - text;
}


// EOF
