	include	"macros.i"
	include	"whdload.i"
	include	"whdmacros.i"

	include	"exec/types.i"
	include	"exec/memory.i"
	include	"exec/libraries.i"
	include	"exec/execbase.i"

	include "dos/dos.i"
	include "dos/var.i"
	include "dos/dostags.i"
	include "dos/dosextens.i"
	include "intuition/intuition.i"

	include	"graphics/gfxbase.i"
	include	"graphics/videocontrol.i"
	include	"graphics/view.i"
	include	"devices/console.i"
	include	"devices/conunit.i"
	include	"libraries/lowlevel.i"
	INCLUDE	"workbench/workbench.i"
	INCLUDE	"workbench/startup.i"
	
	include "lvo/exec.i"
	include "lvo/dos.i"
	include "lvo/lowlevel.i"
	include "lvo/graphics.i"


	
; keymap.library
_LVOSetKeyMapDefault   equ     -30     ; Functions in V36 or higher (2.0)
_LVOAskKeyMapDefault   equ     -36
_LVOMapRawKey          equ     -42
_LVOMapANSI            equ     -48


MAJOR_VERSION = 0
MINOR_VERSION = 0
SUBMINOR_VERSION = 1

	
PARSEHEXARG:MACRO
	move.l	(A0)+,D0
	beq.b	.sk\@
	move.l	D0,A1
	bsr	HexStringToNum
	;tst.b	D0
	;beq.b	.sk\@
	move.b	D0,\1_keycode
.sk\@
	ENDM
	
EntryPoint:
	move.l	A7,OriginalStack
	move.l	A0,TaskArgsPtr
	move.l	D0,TaskArgsLength
	move.l	$4.w,_SysBase		;store execbase in fastmem
	move.l	_SysBase,a6		;exec base
	JSRLIB	Forbid
	sub.l	A1,A1
	JSRLIB	FindTask		;find ourselves
	move.l	D0,TaskPointer
	move.l	D0,A0
	move.l	(TC_SPLOWER,A0),D0
	add.l	#$100,D0	; 256 bytes for safety
	move.l	D0,TaskLower	; for task check
	move.l	#TaskName,LN_NAME(a0)	; sets task name
	move.l	#-1,pr_WindowPtr(A0)	; no more system requesters (insert volume...)
	JSRLIB	Permit

	; free animation
	lea	freename(pc),a1
	moveq.l	#0,d0
	JSRLIB	OpenLibrary
	tst.l	d0
	beq.b	.nofree
	move.l	d0,a1
	JSRLIB	CloseLibrary
.nofree

	lea	dosname(pc),a1
	moveq.l	#0,d0
	JSRLIB	OpenLibrary
	move.l	d0,_DosBase

	move.l	TaskPointer(pc),A4
	tst.l	pr_CLI(A4)
	bne.b	.fromcli

	; gets wb message

	lea	pr_MsgPort(A4),A0
	JSRLIB	WaitPort
	lea	pr_MsgPort(A4),A0
	JSRLIB	GetMsg
	move.l	D0,RtnMess
	
	
.fromcli
	bsr	OpenOutput
	bsr	start
	
exit:
	move.l	launch_slave_seglist(pc),d1
	beq.b	.nofree
	move.l	_DosBase,A6
	JSRLIB	UnLoadSeg
.nofree
	move.l	executable_seglist(pc),d1
	beq.b	.nofree2
	move.l	_DosBase,A6
	JSRLIB	UnLoadSeg
.nofree2
	move.l	_DosBase(pc),D0
	beq.b	.skipcd
	move.l	rdargs_struct(pc),D1
	beq.b	.noargsfree		; already freed/not parsed
	move.l	D0,A6
	JSRLIB	FreeArgs
.noargsfree
	move.l	_SysBase,A6
	move.l	_DosBase(pc),D0
	beq.b	.skipcd
	move.l	d0,a1
	JSRLIB	CloseLibrary
.skipcd
	move.l	_SysBase,A6
	move.l	_LowlevelBase(pc),D0
	beq.b	.skipcl
	move.l	d0,a1
	JSRLIB	CloseLibrary
.skipcl

	; replies to workbench

	move.l	RtnMess(pc),d0
	tst.l	D0
	beq.b	.cliend

	JSRLIB	Forbid
	move.l	D0,A1
	JSRLIB	ReplyMsg
	; no permit here??
	JSRLIB	Permit
.cliend
	moveq.l	#0,D0
	rts

ReadArgsErr:
		PRINT_ERROR_MSG	readargs_error
		PRINT_MSG	help
		bra.b	CloseAll
		
CloseAll:
	move.l	OriginalStack,A7
	bra	exit

LoadSlave:
	; *** Open the file

	move.l	#launch_slave_name,D1
	move.l	_DosBase,A6
	JSRLIB	LoadSeg
	move.l	d1,launch_slave_seglist
	beq	.noslave	; very unlikely!


.out	
	rts
.noslave
	PRINT_MSG	error_prefix
	PRINT		"Cannot read "
	PRINT_MSG	launch_slave_name
	PRINTLN	
	bra	CloseAll

; the aim here is to see if a joystick is connected in port 1 with JOYPAD=2
; in that case, button remapping won't work, and so won't joypad detection
; if JOYPAD=2 AND joystick is connected in port 2 AND joypad is connected in port 1,
; then set JOYPAD=1 and map joypad 2 controls to joypad 1
;
; of course this only works on real hardware. On winuae, joystick/joypad detection fails

VTRANS:MACRO
	move.b	joy1_\1_keycode,D0
	move.b	D0,joy0_\1_keycode
	ENDM
	
CheckJoypads:
	
	
	lea	lowname(pc),a1
	moveq.l	#0,d0
	move.l	$4.W,A6
	JSRLIB	OpenLibrary
	move.l	D0,_LowlevelBase
	beq.b	.nolowl	; A1200/A600: maybe not present: who cares?
	move.l	D0,A6
	moveq	#1,D0
	JSRLIB	ReadJoyPort
	move.l	d0,d1
	and.l	#JP_TYPE_MASK,D0
	cmp.l	#JP_TYPE_JOYSTK,D0
	bne.b	.exit		; no joystick in port 1: forget it
	moveq	#0,D0
	JSRLIB	ReadJoyPort
	move.l	d0,d1
	and.l	#JP_TYPE_MASK,D0
	cmp.l	#JP_TYPE_GAMECTLR,D0
	bne.b	.exit		; no joypad in port 0: forget it

	move.l	joypad_flag,D0
	cmp.l	#2,D0		; port 1 and only port 1
	bne	.exit
	; we are in the target configuration, swap ports (doesn't seem to work)
	move.l	#1,joypad_flag		; port 1 remap only
	move.l	#1,swapjoy

	; set values for joypad 0 from values from joypad 1
	VTRANS	play
	VTRANS	red
	VTRANS	fwd
	VTRANS	bwd
	VTRANS	fwdbwd
	VTRANS	green
	VTRANS	blue
	VTRANS	yellow

.exit
	; D1 has joypad state
	; if some button is pressed, enable CUSTOMx
	; don't consider RED button since it could be used to run the game on startup menus
;	btst	#JPB_BUTTON_RED,D1
;	beq.b	.nored	
;.nored
	btst	#JPB_BUTTON_BLUE,D1
	beq.b	.noblue
	move.l	#1,custom1_flag
.noblue
	btst	#JPB_BUTTON_YELLOW,D1
	beq.b	.noyellow
	move.l	#1,custom2_flag
.noyellow
	btst	#JPB_BUTTON_FORWARD,D1
	beq.b	.noforward
	move.l	#1,custom5_flag
	
.noforward
	btst	#JPB_BUTTON_REVERSE,D1
	beq.b	.noreverse
	move.l	#1,custom4_flag
	
.noreverse
	btst	#JPB_BUTTON_GREEN,D1
	beq.b	.nogreen
	move.l	#1,custom3_flag

.nogreen
.nolowl
	rts

LinkSlaveInfo:
	
	; first check CD slave if any

	move.l	launch_slave_seglist,d1
	beq.b	.no_cd_slave
	add.l	d1,d1
	add.l	d1,d1
	addq.l	#4,d1
	move.l	d1,a1
	move.l	$4(A1),D0
	cmp.l	#"CDLA",D0
	beq.b	.cdslok
	PRINT_MSG	error_prefix
	PRINTLN	"CD launcher slave is illegal (no CDLAUNCH prefix)"
	bra	CloseAll
.cdslok
	lea	12(a1),a2	; points to base structure
	move.l	a2,slave_base
	move.l	$C(a2),d0	; executable name
	move.l	#executable_name,d1
	bsr	StrcpyAsm
	move.l	$8(a2),a3	; assign list
.prnt
	move.l	(a3)+,d0
	beq.b	.out
	move.l	d0,a0
	move.l	(a3)+,a1
	bsr	_dos_assign
	bra	.prnt
	
.out
.no_cd_slave
	rts

	

ReadArgsString:
	dc.b	"EXECUTABLE/K,LAUNCHSLAVE/K,CUSTOM/K,CUSTOM1/K/N,CUSTOM2/K/N,"
	dc.b	"CUSTOM3/K/N,CUSTOM4/K/N,CUSTOM5/K/N,"
	dc.b	"NTSC/S,PAL/S,BUTTONWAIT/S,PRETEND=TEST/S,NOCACHE/S,ECS/S,"
	dc.b	"JOYPAD/K/N,"
	dc.b	"JOY1RED/K,JOY1GREEN/K,JOY1YELLOW/K,JOY1BLUE/K,JOY1FWD/K,JOY1BWD/K,JOY1PLAY/K,JOY1FWDBWD/K,"
	dc.b	"JOY1RIGHT/K,JOY1LEFT/K,JOY1UP/K,JOY1DOWN/K,"
	dc.b	"JOY0RED/K,JOY0GREEN/K,JOY0YELLOW/K,JOY0BLUE/K,JOY0FWD/K,JOY0BWD/K,JOY0PLAY/K,JOY0FWDBWD/K,"
	dc.b	"JOY0RIGHT/K,JOY0LEFT/K,JOY0UP/K,JOY0DOWN/K,"
	dc.b	"VK/K,VM/K,VMDELAY/K/N,VMMODDELAY/K/N,VMMODBUT/K"
	dc.b	0
	even
	
; 1: offset, 2: register containing new VBR
REDIRECT_VECTOR:MACRO
	lea	.redirect_\1(pc),a0
	move.l	a0,\1(\2)
	bra.b	.out_\1
.redirect_\1:
	move.l	\1,-(A7)
	RTS
.out_\1:
	ENDM
	
start:
	tst.l	RtnMess
	bne	.wbunsup
	

	; default values for joypad 1
	move.b	#$19,joy1_play_keycode	; P
	move.b	#$50,joy1_bwd_keycode	; F1
	move.b	#$51,joy1_fwd_keycode	; F2
	
	move.b	#$44,joy1_green_keycode	; RETURN
	move.b	#$40,joy1_blue_keycode	; SPACE
	move.b	#$64,joy1_yellow_keycode	; left-ALT
	move.b	#$45,joy1_fwdbwd_keycode	; ESC
	
	; default values for joypad 0
	move.b	#$19,joy0_play_keycode	; P	;(same as player 1)
	move.b	#$52,joy0_bwd_keycode	; F3
	move.b	#$53,joy0_fwd_keycode	; F4
	
	move.b	#$01,joy0_green_keycode	; 1
	move.b	#$02,joy0_blue_keycode	; 2
	move.b	#$41,joy0_yellow_keycode	; backspace
	move.b	#$45,joy0_fwdbwd_keycode	; ESC

	bsr	ComputeAttnFlags
	
	move.l	#ReadArgsString,d1
	move.l	#ProgArgs,d2
	moveq.l	#0,d3
	move.l	_DosBase,A6

	JSRLIB	ReadArgs

	move.l	d0,rdargs_struct		;NULL is OK
	beq	ReadArgsErr
	
	
	
	lea	ProgArgs(pc),A0
	move.l	(A0)+,D0
	beq.b	.skn
	move.l	#executable_name,D1	; 1st
	bsr	StrcpyAsm
.skn
	move.l	(A0)+,D0
	beq.b	.skcds
	LEA	launch_slave_name(pc),A1	; 2nd
	move.l	A1,D1
	bsr	StrcpyAsm
.skcds

	move.l	(A0)+,D0
	beq.b	.sku
	lea	custom_str,A1	; 3rd
	move.l	A1,D1
	bsr	StrcpyAsm
.sku
	move.l	#2,joypad_flag	; default: mapping on port 2 only

	; *** users flags
	
	move.l	(A0)+,D0
	beq.b	.skc1
	move.l	D0,A1
	move.l	(a1),custom1_flag	; 4th
.skc1
	move.l	(A0)+,D0
	beq.b	.skc2
	move.l	D0,A1
	move.l	(a1),custom2_flag	; 5th
.skc2
	move.l	(A0)+,D0
	beq.b	.skc3
	move.l	D0,A1
	move.l	(a1),custom3_flag	; 6th
.skc3
	move.l	(A0)+,D0
	beq.b	.skc4
	move.l	D0,A1
	move.l	(a1),custom4_flag	; 7th
.skc4
	move.l	(A0)+,D0
	beq.b	.skc5
	move.l	D0,A1
	move.l	(a1),custom5_flag	; 8th
.skc5

	move.l	(A0)+,ntsc_flag		; Force NTSC 9th
	bne.b	.skippal
	move.l	(A0),pal_flag		; Force PAL 10th
.skippal
	add.l	#4,a0
	move.l	(A0)+,buttonwait_flag	; 11th
	move.l	(A0)+,pretend_flag		; 12th
	move.l	(A0)+,nocache_flag		; 13th
	move.l	(A0)+,ecs_flag			; 14th

	move.l	(A0)+,D0
	beq.b	.skjoy
	move.l	D0,A1
	; 0: no joypad remapping
	; 1: joyport 0 remapping only
	; 2: joyport 1 remapping only (default)
	; 3: both joyports remapping
	move.l	(a1),joypad_flag	
	beq.b	.skjoy
	st.b	explicit_joypad_option
.skjoy
	
	
	PARSEHEXARG	joy1_red
	PARSEHEXARG	joy1_green
	PARSEHEXARG	joy1_yellow
	PARSEHEXARG	joy1_blue
	PARSEHEXARG	joy1_fwd
	PARSEHEXARG	joy1_bwd
	PARSEHEXARG	joy1_play
	PARSEHEXARG	joy1_fwdbwd
	
	PARSEHEXARG joy1_right
	PARSEHEXARG joy1_left
	PARSEHEXARG joy1_up
	PARSEHEXARG joy1_down
	
	PARSEHEXARG	joy0_red
	PARSEHEXARG	joy0_green
	PARSEHEXARG	joy0_yellow
	PARSEHEXARG	joy0_blue
	PARSEHEXARG	joy0_fwd
	PARSEHEXARG	joy0_bwd
	PARSEHEXARG	joy0_play
	PARSEHEXARG	joy0_fwdbwd
	
	PARSEHEXARG joy0_right
	PARSEHEXARG joy0_left
	PARSEHEXARG joy0_up
	PARSEHEXARG joy0_down
	
	move.l  (A0)+,D0	; VK
	tst.b	D0
	beq.b	.skipvk
	move.l	D0,A1
	bsr	HexStringToNum
	tst.b	D0
	beq.b	.skipvk
	move.b	D0,vk_button
	
.skipvk
	move.l  (A0)+,D0	; VM
	tst.b	D0
	beq.b	.skipvm
	move.l	D0,A1
	bsr	HexStringToNum
	tst.b	D0
	beq.b	.skipvm
	move.b	D0,vm_button
.skipvm

	move.l		(A0)+,D0	; VMDELAY
	beq.b		.skipvmdelay
	move.l		D0,A1
	move.l	(a1),vm_delay
	move.b	#1,vm_enabled
	
.skipvmdelay
	move.l		(A0)+,D0	; VMMODDELAY
	beq.b		.skipvmoddelay
	move.l		D0,A1
	move.l	(a1),vm_modifierdelay
	move.b	#1,vm_enabled
	
.skipvmoddelay
	move.l  (A0)+,D0		; VMMODBUT
	tst.b	D0
	beq.b	.skipvmodifybutton
	move.l	D0,A1
	bsr	HexStringToNum
	tst.b	D0
	beq.b	.skipvmodifybutton
	move.b	D0,vm_modifierbutton
	
.skipvmodifybutton


	; swap joypad 1=>0 if joypad in port 0
	; also check if buttons pressed to enable CUSTOMx tooltypes
	bsr	CheckJoypads
	
	; load slave from disk
	bsr	LoadSlave
	
	; display info about slave & fill structures
	bsr	LinkSlaveInfo
	
	
	move.l	attnflags,D0	; save attnflags in fastmem
	btst	#AFB_68010,D0
	bne.b	.vbrok
	; 68000: force NOVBRMOVE
	move.l	#1,novbrmove_flag
.vbrok

	move.l	#executable_name,d1
	move.l	_DosBase,A6
	JSRLIB	LoadSeg
	move.l	d1,executable_seglist
	bne	.exeok
	PRINT	"Cannot load "
	lea	executable_name(pc),a1
	bsr	Display
	bra	CloseAll
.exeok
	; now init the slave with exec seglist
	; now patch the executable if required
	tst.l	slave_base
	beq.b	.noslave
	
	move.l	slave_base,a3
	lea	_read_joystick,a0
	move.l	a0,$1C(A3)		; pointer to joypad read routine
	move.l	(A3),a0
	cmp.l	#0,a0
	beq.b	.skip_init
	move.l	executable_seglist,d1
	STORE_REGS
	jsr	(a0)		; call init
	RESTORE_REGS
.skip_init
	move.l	4(A3),a0	; user patchlist
	cmp.l	#0,a0
	beq.b	.skip_patch
	move.l	executable_seglist,a1
	bsr	jst_resload_PatchSeg
.skip_patch
	bsr	flush_caches
.noslave
; PRETEND mode: display all parameters
	tst.l	pretend_flag
	beq		.nodisplayparams

	; display parameters
	PRINT	"Executable to run: "
	PRINT_MSG	executable_name
	PRINTLN
	tst.b	launch_slave_name
	beq.b	.nocdslave1
	PRINT	"Launch slave file: "
	PRINT_MSG	launch_slave_name	
	PRINTLN
.nocdslave1

	
	moveq.l	#0,d0
	PRINTLN
	PRINT	"JOY1BLUE: "
	move.b	joy1_blue_keycode,D0
	PRINTH	D0
	PRINTLN
	PRINT	"JOY1YELLOW: "
	move.b	joy1_yellow_keycode,D0
	PRINTH	D0
	PRINTLN
	PRINT	"JOY1GREEN: "
	move.b	joy1_green_keycode,D0
	PRINTH	D0
	PRINTLN
	PRINT	"JOY1RED: "
	move.b	joy1_red_keycode,D0
	PRINTH	D0
	PRINTLN
	PRINT	"JOY1PLAY: "
	move.b	joy1_play_keycode,D0
	PRINTH	D0
	PRINTLN
	PRINT	"VIRTUAL MOUSE: "
	move.l	vm_delay,D0
	PRINTH	D0
	PRINTLN

	
	tst.l	swapjoy
	
	beq.b	.noswap
	PRINTLN	"*** Joystick <-> Joypad mapping swap ***"
.noswap
	PRINT	"Custom arg: "
	lea	custom_str,A1
	bsr	Display
	PRINTLN
	PRINT	"Custom1: "
	move.l	custom1_flag,D0
	PRINTH	D0
	PRINTLN
	PRINT	"Custom2: "
	move.l	custom2_flag,D0
	PRINTH	D0
	PRINTLN
	PRINT	"Custom3: "
	move.l	custom3_flag,D0
	PRINTH	D0
	PRINTLN
	PRINT	"Custom4: "
	move.l	custom4_flag,D0
	PRINTH	D0
	PRINTLN
	PRINT	"Custom5: "
	move.l	custom5_flag,D0
	PRINTH	D0
	PRINTLN
	PRINT	"Joypad: "
	move.l	joypad_flag,D0
	PRINTH	D0
	PRINTLN
	PRINT	"Forced display mode: "
	tst.l	pal_flag

	beq.b	.skp
	PRINT	"PAL"
	bra	.noforce
.skp
	tst.l	ntsc_flag
	beq	.sknf
	PRINT	"NTSC"
	bra	.noforce
.sknf
	PRINT	"none"
.noforce
	PRINTLN
	PRINT	"Novbrmove: "
	move.l	novbrmove_flag,D0
	PRINTH	D0
	PRINTLN

	PRINT	"Buttonwait: "
	move.l	buttonwait_flag,D0
	PRINTH	D0
	PRINTLN
	bra	CloseAll
.nodisplayparams

	; sprites to normal size (useful?)
	
	; degrade display
	lea	gfxname(pc),a1
	moveq.l	#0,d0
	move.l	_SysBase,A6
	JSRLIB	OpenLibrary
	move.l	D0,_GfxBase
	
	
	move.l	_GfxBase,A6
	; save bplcon & chiprev bits so resload_Control can recall them
	;;move.W	(gb_system_bplcon0,A6),system_bplcon0
	move.b	(gb_ChipRevBits0,A6),system_chiprev_bits

	;move.l	gb_ActiView(A6),my_actiview
	;move.l	gb_copinit(A6),my_copinit
	sub.l	A1,A1
	JSRLIB	LoadView
	JSRLIB	WaitTOF
	JSRLIB	WaitTOF

.wav
	tst.l	(gb_ActiView,a6)
	bne.b	.wav
	JSRLIB	WaitTOF

	tst.l	ecs_flag
	beq.b	.noecs
	bsr	DegradeBandWidth
.noecs

	tst.l	nocache_flag
	beq	.5		; Disable ALL caches unless "cpucache" flag is set

	moveq.l	#0,D0
	moveq.l	#-1,D1
	move.l	_SysBase,A6
	JSRLIB	CacheControl
.5
	move.l	_SysBase,A6
	JSRLIB	Disable

	bsr	_detect_controller_types
	bsr	_detect_controller_types

	; zero the VBR: copy 64 vectors
	bsr	get_system_vbr
	cmp.l	#0,a0
	beq.b	.already_zero
	sub.l	a1,a1
	move.w	#63,d0
.vcl
	move.l	(a0)+,(a1)+
	dbf	d0,.vcl
.already_zero
	sub.l	a0,a0
	tst.l	novbrmove_flag
	beq.b	.zero
	; default: redirect all vectors
	bsr	redirect_vectors
	lea	relocated_vbr(pc),a0
.zero
	bsr	set_system_vbr
	move.l	_SysBase,A6
	JSRLIB	Enable
	; now start the executable
	move.l	executable_seglist(pc),d1
	add.l	d1,d1
	add.l	d1,d1
	move.l	d1,a1
	move.l	slave_base,a3
	move.l	$10(a3),a0
	cmp.l	#0,a0
	beq.b	.is_default_args
	move.l	a0,d0
	bsr	StrlenAsm
	bra.b	.run
.is_default_args
	lea	default_args(pc),a0
	moveq.l	#1,d0
.run
	; run the program
	jsr	(a1)
	; don't return!
	blitz
	; TODO: clean exit, just in case
	bra	CloseAll
.wbunsup
	moveq.l	#1,d0	 ; error
	rts
default_args
	dc.b	10,0
	
redirect_vectors:
	lea	relocated_vbr(pc),a1
	REDIRECT_VECTOR	$08,a1
	REDIRECT_VECTOR	$0c,a1
	REDIRECT_VECTOR	$10,a1
	REDIRECT_VECTOR	$14,a1
	REDIRECT_VECTOR	$18,a1
	REDIRECT_VECTOR	$1c,a1
	REDIRECT_VECTOR	$20,a1
	REDIRECT_VECTOR	$24,a1
	REDIRECT_VECTOR	$28,a1
	REDIRECT_VECTOR	$2c,a1
	REDIRECT_VECTOR	$30,a1
	REDIRECT_VECTOR	$34,a1
	REDIRECT_VECTOR	$38,a1
	REDIRECT_VECTOR	$3c,a1
	REDIRECT_VECTOR	$40,a1
	REDIRECT_VECTOR	$44,a1
	REDIRECT_VECTOR	$48,a1
	REDIRECT_VECTOR	$4c,a1
	REDIRECT_VECTOR	$50,a1
	REDIRECT_VECTOR	$54,a1
	REDIRECT_VECTOR	$58,a1
	REDIRECT_VECTOR	$5c,a1
	REDIRECT_VECTOR	$60,a1
	REDIRECT_VECTOR	$64,a1
	REDIRECT_VECTOR	$68,a1
	REDIRECT_VECTOR	$6c,a1
	REDIRECT_VECTOR	$70,a1
	REDIRECT_VECTOR	$74,a1
	REDIRECT_VECTOR	$78,a1
	REDIRECT_VECTOR	$7c,a1
	REDIRECT_VECTOR	$80,a1
	REDIRECT_VECTOR	$84,a1
	REDIRECT_VECTOR	$88,a1
	REDIRECT_VECTOR	$8c,a1
	REDIRECT_VECTOR	$90,a1
	REDIRECT_VECTOR	$94,a1
	REDIRECT_VECTOR	$98,a1
	REDIRECT_VECTOR	$9c,a1
	REDIRECT_VECTOR	$a0,a1
	REDIRECT_VECTOR	$a4,a1
	REDIRECT_VECTOR	$a8,a1
	REDIRECT_VECTOR	$ac,a1
	REDIRECT_VECTOR	$b0,a1
	REDIRECT_VECTOR	$b4,a1
	REDIRECT_VECTOR	$b8,a1
	REDIRECT_VECTOR	$bc,a1
	REDIRECT_VECTOR	$c0,a1
	REDIRECT_VECTOR	$c4,a1
	REDIRECT_VECTOR	$c8,a1
	REDIRECT_VECTOR	$cc,a1
	REDIRECT_VECTOR	$d0,a1
	REDIRECT_VECTOR	$d4,a1
	REDIRECT_VECTOR	$d8,a1
	REDIRECT_VECTOR	$dc,a1
	REDIRECT_VECTOR	$e0,a1
	REDIRECT_VECTOR	$e4,a1
	REDIRECT_VECTOR	$e8,a1
	REDIRECT_VECTOR	$ec,a1
	REDIRECT_VECTOR	$f0,a1
	REDIRECT_VECTOR	$f4,a1
	REDIRECT_VECTOR	$f8,a1
	REDIRECT_VECTOR	$fc,a1
	rts
	
		
DegradeBandWidth:
	STORE_REGS
	
	move.l	(_GfxBase),a6
	cmp.l	#39,(LIB_VERSION,a6)
	blo	.noaga
	btst	#GFXB_AA_ALICE,(gb_ChipRevBits0,a6)
	beq	.noaga
	;move.b	(gb_MemType,a6),oldbandwidth
	move.b	#BANDWIDTH_1X,(gb_MemType,a6)	;auf ECS Wert setzen
	move.l	#SETCHIPREV_A,D0
	JSRLIB	SetChipRev
	;move.l	D0,oldchiprev

.noaga
	move.w	#50,d0		; todo: compute native screen freq
	
	lea	$DFF000,A5
	tst.l	pal_flag

	beq.b	.skp
	move.w	#$0020,beamcon0(A5)	; go PAL
	move.w	#50,d0
	move.l	#709379,eclock_freq	; PAL forced

	bra	.sknf
.skp
	tst.l	ntsc_flag
	beq	.sknf
	move.w	#$0000,beamcon0(A5)	; go NTSC
	move.w	#60,d0
	move.l	#715909,eclock_freq	; NTSC forced
.sknf
	MOVE.W	#$0,fmode(A5)		; disable AGA-fetch rate

	RESTORE_REGS
	rts
	
; in: D0: filename
; out: D0: 0 if OK, -1 if error
ObjectExists:
	STORE_REGS	D2/A6
	moveq.l	#-1,D2

	move.l	D0,D1
	move.l	#ACCESS_READ,D2
	move.l	_DosBase,A6
	JSRLIB	Lock
	move.l	D0,D1		; D5=File Lock
	beq.b	.end

	JSRLIB	UnLock		; unlock subdirectory
	moveq.l	#0,d2
.end
	move.l	D2,D0
	RESTORE_REGS	D2/A6
	rts

; < A0: new VBR

set_system_vbr:
	STORE_REGS	D0-D7/A1-A6
	lea	.set_vbr_sup(pc),A5			; supervisor function
	move.l	$4.W,A6
	move.b	AttnFlags+1(A6),D1
	btst	#AFB_68010,D1		; At least 68010
	beq	.error

	JSRLIB	Supervisor
.exit
	RESTORE_REGS	D0-D7/A1-A6
	rts
.error
	bra	.exit
.set_vbr_sup:
	MC68010
	movec	a0,VBR
	MC68000
	RTE

; > A0: system VBR

get_system_vbr:
	STORE_REGS	D0-D7/A1-A6
	lea	.get_vbr_sup(pc),A5			; supervisor function
	move.l	$4.W,A6
	move.b	AttnFlags+1(A6),D1
	btst	#AFB_68010,D1		; At least 68010
	beq	.error

	JSRLIB	Supervisor
.exit
	RESTORE_REGS	D0-D7/A1-A6
	rts
.error
	sub.l	a0,a0
	bra	.exit
.get_vbr_sup:
	MC68010
	movec	VBR,a0
	MC68000
	RTE
	
; *** Gets the length (bytes) of a file on the hard drive
; in: D0: filename
; out: D0: length in bytes (-1 if not found!)

GetFileLength
	STORE_REGS	D1-A6
	moveq.l	#-1,D6

	move.l	D0,D1
	move.l	#ACCESS_READ,D2
	move.l	_DosBase,A6
	JSRLIB	Lock
	move.l	D0,D5		; D5=File Lock
	beq.b	.end

	
	bsr	AllocInfoBlock
	move.l	D0,D7

	move.l	D5,D1
	move.l	D7,D2	; infoblock
	bsr	examine

	move.l	D7,A0
	move.l	fib_Size(A0),D6	; file size

	move.l	D5,D1
	move.l	_DosBase,A6
	JSRLIB	UnLock		; unlock subdirectory
	move.l	D7,D0
	bsr	FreeInfoBlock
.end
	move.l	D6,D0
	RESTORE_REGS	D1-A6
	rts

AllocInfoBlock:
	STORE_REGS	D1/D2/A0/A1/A6
	move.l	#DOS_FIB,D1
	moveq.l	#0,D2
	move.l	_DosBase,A6
	JSRLIB	AllocDosObject
	tst.l	D0
	beq	.error
	RESTORE_REGS	D1/D2/A0/A1/A6
	rts

.error:
	PRINT_MSG	error_prefix
	PRINTLN	"Cannot allocate infoblock"
	bra	CloseAll


FreeInfoBlock
	STORE_REGS
	tst.l	D0
	beq.b	.exit	; safety
	move.l	D0,D2
	move.l	#DOS_FIB,D1
	move.l	_DosBase,A6
	JSRLIB	FreeDosObject
.exit
	RESTORE_REGS
	rts


examine:
	STORE_REGS	D1-A6
	move.l	_DosBase,A6
	JSRLIB	Examine
	RESTORE_REGS	D1-A6
	rts
	

; *** open window/get console output handle

OpenOutput:
	STORE_REGS
	tst.l	ConHandle
	bne.b	.go			; already open

	move.l	_DosBase(pc),a6
	JSRLIB	Output
	move.l	D0,ConHandle
	bne	.go		; Output? Ok.

	move.l	_DosBase(pc),A6
	lea	ConName(pc),A0
	tst.b	(A0)		; Maybe we don't want to open a console
	beq	.nowin
	move.l	a0,D1
	move.l	#MODE_NEWFILE,D2
	JSRLIB	Open
.exit
	move.l	D0,ConHandle
.go
	RESTORE_REGS
	rts

.nowin
	moveq.l	#0,D0
	bra	.exit

ComputeAttnFlags:
	STORE_REGS
	move.l	_SysBase,A6
	moveq.l	#0,D0
	move.b	AttnFlags+1(A6),D0
	btst	#AFB_68040,D0
	beq.b	.noclr6888x

	; remove 6888x coprocessors declaration if 68040+ is set

	bclr	#AFB_68881,D0
	bclr	#AFB_68882,D0
.noclr6888x
	
	move.l	D0,attnflags	; save attnflags in fastmem
	RESTORE_REGS
	rts
	
	
jst_resload_PatchSeg
	;LOG_WHD_CALL	"PatchSeg"
	STORE_REGS
	move.l	A0,A2		; store patchlist
	move.l	A1,A6		; store seglist
	add.l	A6,A6
	add.l	A6,A6	; CPTR
	lea	patch_jumptable(pc),A5
	moveq.l	#0,D5		; condition mask: all bits must be at 0 or patch won't apply
	moveq.l	#0,D6		; nest counter

.loop:
	move.l	A6,A1	; reset segment pointers
	
	move.w	(a0)+,D0	; command
	cmp.w	#PLCMD_END,D0
	beq.w	.exit

	
	bclr	#14,D0
	bne.b	.noaddr		; command: no address argument
	bclr	#15,D0
	beq.b	.bit32
	moveq.l	#0,D1
	move.w	(a0)+,D1	; D1.W: offset
	bra.b	.bit16
.bit32
	move.l	(a0)+,D1	; D1.L: address
	; compute the correct A1 (not fixed like in resload_Patch)
	; depending on D1
.bit16
	moveq.l	#0,D3	; segment absolute offset
	
.find_a1:
	move.l	(A1)+,D2
	add.l	D2,D2
	add.l	D2,D2	; D2=next segment address
	move.l	d3,D7	; save previous accumulated segment size
	add.l	-8(a1),D3	; accumulate segment size
	subq.l	#8,d3	; minus size+next segment info
	cmp.l	D3,D1
	bcs.b	.a1_found
	; D1 is above D3: look in next segment

	tst.l	d2
	beq.b	.notfound	; end of seglist found, and offset still too high

	move.l	D2,A1
	bra.b	.find_a1
.a1_found
	sub.l	D7,D1	; make D1 offset relative to current segment
.noaddr:
	cmp.w	#45,D0
	bcc		unsupported_patch_instruction
	add.w	D0,D0
	move.w	(A5,D0.W),D0
	jsr	(A5,D0.W)
	bra.b	.loop
.notfound
	move.l	d1,d0
	lea	.whd_code(pc),a1
	bsr	HexToString
	pea	$0
	lea	.whd_abort_msg(pc),a1
	bsr	Display
	bra	CloseAll
.whd_abort_msg:
	dc.b	"PatchSeg: offset not found: "
.whd_code:
	blk.b	10,0
.exit
	bsr	flush_caches
	RESTORE_REGS
	;END_WHD_CALL

	RTS
unsupported_patch_instruction
	PRINTLN	"Unsupported patch instruction"
	bra	CloseAll
	
flush_caches:
	STORE_REGS
	;JSRABS	Kick37Test
	;tst.l	D0
	;bne	.2		; Don't touch if KS 1.x
	moveq.l	#0,D0
	moveq.l	#0,D1
	move.l	_SysBase,A6
	JSRLIB	CacheControl
.2
	RESTORE_REGS
	rts
	
SKIPIFFALSE	MACRO
		tst.l	d5
		beq.b	.cont\@
		rts
.cont\@
	ENDM


	
jst_resload_Patch:
	;LOG_WHD_CALL	"Patch"
		; apply patchlist
		; IN :	a0 = APTR   patchlist
		;	a1 = APTR   destination address
		; OUT :	-
	STORE_REGS
	move.l	A0,A2		; store patchlist
	lea	patch_jumptable(pc),A5
	moveq.l	#0,D5		; condition mask: all bits must be at 0 or patch won't apply
	moveq.l	#0,D6		; nest counter
	
.loop:
	move.w	(a0)+,D0	; command
	cmp.w	#PLCMD_END,D0
	bne.w	.cont

	; exit
	bsr	flush_caches
	RESTORE_REGS
	;END_WHD_CALL
	RTS
.cont
	
	bclr	#14,D0
	bne.b	.noaddr		; command: no address argument
	bclr	#15,D0
	beq.b	.bit32
	moveq.l	#0,D1
	move.w	(a0)+,D1	; D1.W: offset
	bra.b	.noaddr
.bit32
	move.l	(a0)+,D1	; D1.L: address
.noaddr:
	cmp.w	#46,D0
	bcs.b	.instok
	bra	unsupported_patch_instruction
.instok
	add.w	D0,D0
	move.w	(A5,D0.W),D2
	jsr	(A5,D2.W)
	bra	.loop
	
patch_jumptable:
	dc.w	.exit-patch_jumptable	; not reached??	0
	dc.w	.R-patch_jumptable		; 1
	dc.w	.P-patch_jumptable			; 2 set JMP
	dc.w	.PS-patch_jumptable		; 3 set JSR
	dc.w	.S-patch_jumptable			; 4 set BRA (skip)
	dc.w	.I-patch_jumptable			; 5 set ILLEGAL
	dc.w	.B-patch_jumptable			; 6 write byte to specified address
	dc.w	.W-patch_jumptable			; 7 write word to specified address
	dc.w	.L-patch_jumptable			; 8 write long to specified address
; version 11
	dc.w	.UNSUP-patch_jumptable			; 9 (A) write address which is calculated as
					;base + arg to specified address
; version 14
	dc.w	.PA-patch_jumptable		; $A write address given by argument to
					;specified address
	dc.w	.NOP-patch_jumptable		; $B fill given area with NOP instructions
; version 15
	dc.w	.CZ-patch_jumptable			; $C (C) clear n bytes
	dc.w	.CB-patch_jumptable		; $D clear one byte
	dc.w	.CW-patch_jumptable		; $E clear one word
	dc.w	.CL-patch_jumptable		; $F clear one long
; version 16
	dc.w	.PSS-patch_jumptable		; $11 set JSR + NOP..
	dc.w	.NEXT-patch_jumptable		;continue with another patch list
	dc.w	.AB-patch_jumptable		;add byte to specified address
	dc.w	.AW-patch_jumptable		;add word to specified address
	dc.w	.AL-patch_jumptable		;add long to specified address
	dc.w	.DATA-patch_jumptable		;write n data bytes to specified address
; version 16.5
	dc.w	.ORB-patch_jumptable		;or byte to specified address
	dc.w	.ORW-patch_jumptable		;or word to specified address
	dc.w	.ORL-patch_jumptable		;or long to specified address
; version 16.6
	dc.w	.GA-patch_jumptable		; (GA) get specified address and store it in the slave
; version 16.9
	dc.w	.UNSUP-patch_jumptable		;call freezer
	dc.w	.UNSUP-patch_jumptable		;show visual bell
; version 17.2
	dc.w	.IFBW-patch_jumptable		;condition if ButtonWait/S
	dc.w	.IFC1-patch_jumptable		;condition if Custom1/N
	dc.w	.IFC2-patch_jumptable		;condition if Custom2/N
	dc.w	.IFC3-patch_jumptable		;condition if Custom3/N
	dc.w	.IFC4-patch_jumptable		;condition if Custom4/N
	dc.w	.IFC5-patch_jumptable		;condition if Custom5/N
	dc.w	.IFC1X-patch_jumptable		;condition if bit of Custom1/N
	dc.w	.IFC2X-patch_jumptable		;condition if bit of Custom2/N
	dc.w	.IFC3X-patch_jumptable		;condition if bit of Custom3/N
	dc.w	.IFC4X-patch_jumptable		;condition if bit of Custom4/N
	dc.w	.IFC5X-patch_jumptable		;condition if bit of Custom5/N
	dc.w	.ELSE-patch_jumptable		;condition alternative
	dc.w	.ENDIF-patch_jumptable		;end of condition block


.IFBW:
	move.L	buttonwait_flag,D0
	bra	.IFXXX
.IFC1:
	move.L	custom1_flag,D0
	bra	.IFXXX
.IFC2:
	move.L	custom2_flag,D0
	bra	.IFXXX
.IFC3:
	move.L	custom3_flag,D0
	bra	.IFXXX
.IFC4:
	move.L	custom4_flag,D0
	bra	.IFXXX
.IFC5:
	move.L	custom5_flag,D0
	bra	.IFXXX
.ELSE:
		bchg	D6,D5	; invert condition
		rts
		
.ENDIF:
		bclr	D6,D5
		subq.l	#1,D6
		rts	
.IFC1X:
	move.L	custom1_flag,D0
	bra	.IFBITXXX
.IFC2X:
	move.L	custom2_flag,D0
	bra	.IFBITXXX
.IFC3X:
	move.L	custom3_flag,D0
	bra	.IFBITXXX
.IFC4X:
	move.L	custom4_flag,D0
	bra	.IFBITXXX
.IFC5X:
	move.L	custom5_flag,D0


.IFBITXXX
	move.w	(a0)+,d2	; get argument: bit number
	; must be between 0 and 31
	btst	d2,d0
	sne	d0
	ext.w	d0
	ext.l	d0
.IFXXX
	addq.w	#1,d6	; increase nest
	tst.l	d0
	bne	.skif
	bset	d6,d5	; failed condition: set D5 so nothing is patched anymore until ELSE/ENDIF
.skif
	rts
	
.R
	SKIPIFFALSE
	move.w	#$4E75,(A1,D1.L)
	rts
.P
	bsr	.get_slave_address
	SKIPIFFALSE
	move.w	#$4EF9,(A1,D1.L)
	move.l	A3,2(A1,D1.L)
	rts
.PA
	bsr	.get_slave_address
	SKIPIFFALSE
	move.l	A3,(A1,D1.L)
	rts
.PS
	bsr	.get_slave_address
	SKIPIFFALSE
	move.w	#$4EB9,(A1,D1.L)
	move.l	A3,2(A1,D1.L)
	rts
.GA

	bsr	.get_slave_address
	SKIPIFFALSE
	; copy program address (A1+D1) into location
	move.l	A1,(A3)
	add.l	D1,(A3)
	rts
	
.PSS
	bsr	.get_slave_address
	move.w	(a0)+,d2
	SKIPIFFALSE
	move.w	#$4EB9,(A1,D1.L)
	move.l	A3,2(A1,D1.L)
	addq.l	#6,D1
	bra	.NOP_from_PSS
.ORB
	clr.w	d0
	move.w	(A0)+,D0
	SKIPIFFALSE
	or.b	D0,(A1,D1.L)
	rts
.ORW
	move.w	(A0)+,D0
	SKIPIFFALSE
	or.w	D0,(A1,D1.L)
	rts
.ORL
	move.l	(A0)+,D0
	SKIPIFFALSE
	or.l	D0,(A1,D1.L)
	rts
.AB
	clr.w	d0
	move.w	(A0)+,D0
	SKIPIFFALSE
	add.b	D0,(A1,D1.L)
	rts
.AW
	move.w	(A0)+,D0
	SKIPIFFALSE
	add.w	D0,(A1,D1.L)
	rts
.AL
	move.l	(A0)+,D0
	SKIPIFFALSE
	add.l	D0,(A1,D1.L)
	rts
.CZ
	move.w	(A0)+,D2
	SKIPIFFALSE
	subq.l	#1,D2
.czl
	clr.b	(A1,D1.L)
	addq.l	#1,D1
	dbf	D2,.czl
	rts
.CL
	SKIPIFFALSE
	clr.l	(A1,D1.L)
	rts
.CW
	SKIPIFFALSE
	clr.w	(A1,D1.L)
	rts
.CB
	SKIPIFFALSE
	clr.b	(A1,D1.L)
	rts
.S
	move.w	(A0)+,D2
	SKIPIFFALSE
	move.w	#$6000,(A1,D1.L)
	move.w	D2,2(A1,D1.L)
	rts
.NOP
	move.w	(A0)+,D2
	SKIPIFFALSE
.NOP_from_PSS
	lsr.w	#1,d2
	bne	.ncont
	rts	; safety
.ncont
	subq.w	#1,d2
.noploop
	move.w	#$4E71,(A1,D1.L)
	addq.l	#2,d1
	dbf		d2,.noploop
	rts
.I
	SKIPIFFALSE
	move.w	#$4AFC,(A1,D1.L)
	rts
.B
	move.w	(A0)+,D2
	SKIPIFFALSE
	move.b	D2,(A1,D1.L)
	rts

.W
	move.w	(A0)+,D2
	SKIPIFFALSE
	move.w	D2,(A1,D1.L)
	rts
.L
	move.l	(A0)+,D2
	SKIPIFFALSE
	move.l	D2,(A1,D1.L)
	rts
.DATA
	move.w	(A0)+,D0	; size
	beq.b	.exit
	move.w	d0,d2	
	subq.l	#1,D0
.dataloop
	tst.l	d5		; cannot use SKIPIFFALSE here
	beq.b	.writedata
	addq.l	#1,A0		; don't write, just zap
	bra.b	.contdata
.writedata
	move.b	(A0)+,(A1,D1.L)
	addq.l	#1,D1
.contdata
	dbf		D0,.dataloop
	btst	#0,d2	; odd?
	beq.b	.exit
	addq.l	#1,a0
	rts
.NEXT	; V16 patchlist support
	bsr	.get_slave_address
	move.l	a3,a0		; next patchlist
	move.l	a3,a2		; store patchlist start
	rts
.UNSUP
	lsr.w	#1,D0
	bra	unsupported_patch_instruction
.exit
	rts

; <> A0: patch buffer (+=2 on exit)
; < A2: patch start
; > A3: real address of the routine in the slave
; D2 trashed

.get_slave_address:
	move.w	(A0)+,D2
	lea	(A2,D2.W),A3
	rts

; this was ripped from kick13.s (kickstart emulation)
; how to use:
; A0 <= assign name (with colon)
; A1 <= directory (empty string = current dir)

_dos_assign
		movem.l	d2/a3-a6,-(a7)
		move.l	a0,a3			;A3 = name
		move.l	a1,a4			;A4 = directory
		move.l	(4),a6

	;backward compatibilty (given BSTR instead CPTR)
		cmp.b	#" ",(a0)
		bls	.skipname

	;get length of name
		moveq	#-1,d2
.len		addq.l	#1,d2
		tst.b	(a0)+
		bne	.len

	;get memory for name
		move.l	d2,d0
		addq.l	#2,d0			;+ length and terminator
		move.l	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq	_debug3
		move.l	d0,a0
		move.b	d2,(a0)+
.cpy		move.b	(a3)+,(a0)+
		bne	.cpy
		move.l	d0,a3
.skipname
	;get memory for node
		move.l	#DosList_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq	_debug3
		move.l	d0,a5			;A5 = DosList

		move.l	_DosBase,a6

	;lock directory
		move.l	a4,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
		beq	_debug3
		lsl.l	#2,d1
		move.l	d1,a0
		move.l	(fl_Task,a0),(dol_Task,a5)
		move.l	d0,(dol_Lock,a5)

	;init structure
		move.l	#DLT_DIRECTORY,(dol_Type,a5)
		move.l	a3,d0
		lsr.l	#2,d0
		move.l	d0,(dol_Name,a5)

	;add to the system
		move.l	(dl_Root,a6),a6
		move.l	(rn_Info,a6),a6
		add.l	a6,a6
		add.l	a6,a6
		move.l	(di_DevInfo,a6),(dol_Next,a5)
		move.l	a5,d0
		lsr.l	#2,d0
		move.l	d0,(di_DevInfo,a6)

		movem.l	(a7)+,d2/a3-a6
		rts

_debug3
	PRINT_ERROR_MSG	assign_error
	bra	CloseAll
	
; < A1: message to display (null terminated)
Display:
	STORE_REGS
	clr.l	d3

.aff_count:
	tst.b	(A1,D3)		
	beq.b	.aff_ok
	addq	#1,D3
	bra.b	.aff_count
.aff_ok
	move.l	A1,D2
	move.l	ConHandle(PC),D1
	beq	.1		; If no console, write nothing
	move.l	_DosBase(pc),a6
	JSRLIB	Write
.1
	RESTORE_REGS
	rts

linefeed:
	dc.b	10,13,0
error_prefix:
	dc.b	"** Error: ",0

assign_error:
	dc.b	"Cannot perform assign",0

readargs_error:
	dc.b	"ReadArgs error",0
version:
	dc.b	"$VER "
help:
	dc.b	"CD32Launch version ",MAJOR_VERSION+'0',"."
	dc.b	MINOR_VERSION+'0',SUBMINOR_VERSION+'0',10,13,0
	
ConName:
	dc.b	"CON:20/20/350/200/CD32Launch - JOTD 2019/CLOSE",0
TaskName:
	dc.b	"CD32Launch",0
dosname:
	dc.b	"dos.library",0
lowname:
	dc.b	"lowlevel.library",0
freename:
	dc.b	"freeanim.library",0
gfxname:
	dc.b	"graphics.library",0

launch_slave_name:
	blk.b	255,0
executable_name:
	blk.b	255,0


ProgArgs:
	blk.l	120,0
ProgArgsEnd:

TaskArgsPtr:
	dc.l	0
TaskArgsLength:
	dc.l	0
TaskPointer:
	dc.l	0
TaskLower:
	dc.l	0
OriginalStack:
	dc.l	0
ConHandle:
	dc.l	0

	
RtnMess:
	dc.l	0

rdargs_struct:
	dc.l	0

_SysBase:
	dc.l	0
_DosBase:
	dc.l	0
_GfxBase:
	dc.l	0
_LowlevelBase:
	dc.l	0

swapjoy:
	dc.l	0
pretend_flag
	dc.l	0


relocated_vbr:
	ds.l	64
custom_str:
	ds.b	$80
custom1_flag
	dc.l	0
custom2_flag
	dc.l	0
custom3_flag
	dc.l	0
custom4_flag
	dc.l	0
custom5_flag
	dc.l	0
pal_flag
	dc.l	0
ntsc_flag
	dc.l	0	
buttonwait_flag
	dc.l	0
nocache_flag
	dc.l	0
ecs_flag
	dc.l	0
joypad_flag
	dc.l	0
previous_joy0_state
	dc.l	0
previous_joy1_state
	dc.l	0
last_joy0_state
	dc.l	0
last_joy1_state
	dc.l	0
attnflags
	dc.l	0
novbrmove_flag
	dc.l	0
eclock_freq
	dc.l	0
vm_delay
	dc.l	0
vm_modifierdelay
	dc.l	0
vm_currentdelay
	dc.l	0

game_vbl_interrupt
	dc.l	0

launch_slave_seglist
	dc.l	0
	
executable_seglist:
	dc.l	0
slave_base
	dc.l	0
	; misc

joy1_play_keycode
	dc.b	0
joy1_fwd_keycode
	dc.b	0
joy1_bwd_keycode
	dc.b	0
joy1_green_keycode
	dc.b	0
joy1_blue_keycode
	dc.b	0
joy1_yellow_keycode
	dc.b	0
joy1_fwdbwd_keycode
	dc.b	0
joy1_fwdbwd_active
	dc.b	0
joy1_red_keycode
	dc.b	0
joy1_right_keycode
	dc.b	0
joy1_left_keycode
	dc.b	0
joy1_up_keycode
	dc.b	0
joy1_down_keycode
	dc.b	0
joy0_play_keycode
	dc.b	0
joy0_fwd_keycode
	dc.b	0
joy0_bwd_keycode
	dc.b	0
joy0_green_keycode
	dc.b	0
joy0_blue_keycode
	dc.b	0
joy0_yellow_keycode
	dc.b	0
joy0_fwdbwd_keycode
	dc.b	0
joy0_fwdbwd_active
	dc.b	0
joy0_red_keycode
	dc.b	0
joy0_right_keycode
	dc.b	0
joy0_left_keycode
	dc.b	0
joy0_up_keycode
	dc.b	0
joy0_down_keycode
	dc.b	0
vk_on
	dc.b	0
vk_wason
	dc.b	0
vk_selected_character
	dc.b	0
vk_queued
	dc.b	0
vk_key_delay
	dc.b	0
vk_button
	dc.b	0
vk_keyup
	dc.b	0
vm_button
	dc.b	0
vm_enabled
	dc.b	0
vm_modifierbutton
	dc.b	0
system_chiprev_bits
	dc.b	0


explicit_joypad_option:
	dc.b	0
	even
; labels
	
	include util.asm
	include ReadJoypad.s
