FILENAME = smb1
ASMFILE = $(FILENAME).asm
OBJFILE = $(FILENAME).o
NESFILE = $(FILENAME).nes
DBGFILE = $(FILENAME).dbg
LSTFILE = $(FILENAME).lst
MAPFILE = $(FILENAME).map
CFGFILE = /.vscode/sample1.cfg
ASSEMBLER = ca65
LINKER = ld65
EMULATOR = Mesen

all : build play

build : $(NESFILE) $(OBJFILE)

play : $(NESFILE)
	$(EMULATOR) $(NESFILE)


$(OBJFILE) : $(ASMFILE)
	$(ASSEMBLER) $(ASMFILE) -t none --debug --debug-info --listing $(LSTFILE)

$(NESFILE) : $(OBJFILE)
	$(LINKER) -vm --mapfile $(MAPFILE) --dbgfile $(DBGFILE) --config $(CFGFILE) -o $(NESFILE) $(OBJFILE)
