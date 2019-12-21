TARGET_DIR = C:\DATA\jff\AmigaHD\PROJETS\CD32GAMES\CDTEST\Watchtower

WHDLOADER = $(TARGET_DIR)/$(PROGNAME).lslave
SOURCE = $(PROGNAME)CDL.s
WHDBASE = K:\jff\AmigaHD\PROJETS\WHDLoad
all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
