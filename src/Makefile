LINK = phxlnk 
ASM = phxass


OBJDIR = /obj
EXEDIR = /bin


OBJS = $(OBJDIR)/main.o

all : $(EXEDIR)/cd32launch


clean:
	delete $(EXEDIR)/#? $(OBJDIR)/#?.o FORCE QUIET

$(EXEDIR)/cd32launch	: $(OBJS) $(MAKEFILE)
	$(LINK) FROM $(OBJS) $(LINKOPTS) TO $(EXEDIR)/cd32launch

	
$(OBJDIR)/main.o: util.asm main.asm send_key_event.asm ReadJoyPad.s util.asm virtual_keyboard.asm virtual_mouse.asm macros.i struct.i
	$(ASM) main.asm TO $(OBJDIR)/main.o
	

