#
# Makefile for tonclib.
#

#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM)
endif
ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>devkitPro)
endif
include $(DEVKITARM)/gba_rules

BUILD		:=	build
SRCDIRS		:=	asm src src/font src/tte src/pre1.3
INCDIRS		:=	include
DATADIRS	:=	data

DATESTRING	:=	$(shell date +%Y)$(shell date +%m)$(shell date +%d)

ARCH		:=	-mthumb -mthumb-interwork
RARCH		:= -mthumb-interwork -mthumb
IARCH		:= -mthumb-interwork -marm

bTEMPS		:= 0	# Save gcc temporaries (.i and .s files)
bDEBUG2		:= 0	# Generate debug info (bDEBUG2? Not a full DEBUG flag. Yet)

#---------------------------------------------------------------------------------
# Options for code generation
#---------------------------------------------------------------------------------

CBASE   := $(INCLUDE) -Wall -fno-strict-aliasing #-fno-tree-loop-optimize
CBASE	+= -O2

RCFLAGS := $(CBASE) $(RARCH)
ICFLAGS := $(CBASE) $(IARCH) -mlong-calls #-fno-gcse
CFLAGS  := $(RCFLAGS)

ASFLAGS := $(INCLUDE) -Wa,--warn $(ARCH)

# --- Save temporary files ? ---
ifeq ($(strip $(bTEMPS)), 1)
	RCFLAGS  += -save-temps
	ICFLAGS  += -save-temps
	CFLAGS	 += -save-temps
	CXXFLAGS += -save-temps
endif

# --- Debug info ? ---

ifeq ($(strip $(bDEBUG2)), 1)
	CFLAGS	+= -g
	LDFLAGS	+= -g
endif

#---------------------------------------------------------------------------------
# Path to tools - this can be deleted if you set the path in windows
#---------------------------------------------------------------------------------

export PATH		:=	$(DEVKITARM)/bin:$(PATH)

#---------------------------------------------------------------------------------

ifneq ($(BUILD),$(notdir $(CURDIR)))

export TARGET	:=	$(CURDIR)/lib/libtonc.a

export VPATH	:=	$(foreach dir,$(DATADIRS),$(CURDIR)/$(dir)) $(foreach dir,$(SRCDIRS),$(CURDIR)/$(dir))

ICFILES		:=	$(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.iwram.c)))
RCFILES		:=	$(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.c)))
CFILES		:=  $(ICFILES) $(RCFILES)

SFILES		:=	$(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.s)))
BINFILES	:=	$(foreach dir,$(DATADIRS),$(notdir $(wildcard $(dir)/*.*)))

export OFILES	:=	$(addsuffix .o,$(BINFILES)) $(CFILES:.c=.o) $(SFILES:.s=.o)
export INCLUDE	:=	$(foreach dir,$(INCDIRS),-I$(CURDIR)/$(dir))
export DEPSDIR	:=	$(CURDIR)/build

.PHONY: $(BUILD) clean docs

$(BUILD):
	@[ -d lib ] || mkdir -p lib
	@[ -d $@ ] || mkdir -p $@
	@make --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

docs:
	doxygen libtonc.dox

clean:
	@echo clean ...
	@rm -fr $(BUILD)

#---------------------------------------------------------------------------------

else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------

%.a :

$(TARGET): $(OFILES)

%.a : $(OFILES)
	@echo Building $@
	@rm -f $@
	@$(AR) -crs $@ $^
	$(PREFIX)nm -Sn $@ > $(basename $(notdir $@)).map

%.iwram.o : %.iwram.c
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$(@:.o=.d) $(ICFLAGS) -c $< -o $@

%.o : %.c
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d $(RCFLAGS) -c $< -o $@

-include $(DEPENDS)

endif

#---------------------------------------------------------------------------------
