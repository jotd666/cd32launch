	INCDIR	"Include:"
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	joypad_flags.i
	
	IFD	BARFLY
	OUTPUT	WatchTower.lslave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
LAUNCH_SLAVE_HEADER	MACRO
		moveq	#-1,d0
		rts
		dc.b	"CDLAUNCH"
		ENDM

; those slaves aren't relocatable, no need to

_base		LAUNCH_SLAVE_HEADER			;ws_Security + ws_ID
	dc.l	_init					; 00: init routine
	dc.l	_segpatch				; 04: address of segment patch data (PatchSeg)
	dc.l	_assign_list			; 08: assign list
	dc.l	_executable_name		; 0C: executable name
	dc.l	0						; 10: executable arguments
	dc.l	0						; 14: table with keycodes to send for joypad 0
	dc.l	0						; 18: table with keycodes to send for joypad 1
_readjoypad	
	dc.l	0					; 1C: readjoypad routine to call (filled by cd32launch)
	dc.l	0					; reserved
	dc.l	0					; reserved
	dc.l	0					; reserved
	dc.l	0					; reserved
	
; < D1: BCPL seglist for manual patching
_init
	moveq.l	#0,d0	; return code, leave to 0
	rts
	
_assign_list
	dc.l	disk1
	dc.l	currentdir
	dc.l	disk2
	dc.l	currentdir
	dc.l	disk3
	dc.l	currentdir
	dc.l	0
_executable_name
	dc.b	"Watchtower",0
disk1:
	dc.b	"WT1",0
disk2:
	dc.b	"WT2",0
disk3:
	dc.b	"WT3",0
currentdir
	dc.b	0
	even
; original $1FF00: slow as hell
FADE_SPEED = $3F00


_segpatch
	PL_START

	PL_IFC5
	PL_ELSE
	; fast fade-in/fade-out
	PL_L	$8D0,FADE_SPEED
	PL_L	$8BC,FADE_SPEED
	PL_L	$F2C,FADE_SPEED
	PL_ENDIF
	; VBR access
	PL_L	$1BC92,$70004E73

	; joypad hooks
	PL_PSS	$12396,player_1_grenade,2
	PL_PSS	$1261a,player_2_grenade,2
	PL_PSS	$0d3de,pause_test,2
	PL_PSS	$0d410,quit_test,2
	
	; protection

	PL_B	$9BC,$60	; don't wait for the code
	PL_PSS	$A86,fix_protection,2
	
	PL_IFC1
	PL_B	$641E,1	; infinite lives
	PL_ENDIF
	PL_IFC2
	PL_B	$641F,1	; infinite grenades
	PL_ENDIF
	PL_IFC3
	PL_B	$6420,1	; infinite time
	PL_ENDIF
	PL_END

BUTTON_KEY_TEST:MACRO
	CMPI.B	#\1,$bfec01  ; CIAA_SDR
	beq	.by_keyboard
	movem.l	d0,-(a7)
	move.l	joy\3_buttons(pc),d0
	not.l	d0	; negative logic to match condition codes expected on return
	btst	#\2,d0
	movem.l	(a7)+,d0
.by_keyboard:
	rts
	ENDM

quit_test
	movem.l	a0/d0,-(a7)
	; read both joypads
	moveq.l	#0,d0
	move.l	_readjoypad(pc),a0
	jsr	(a0)
	move.l	d0,joy0_buttons
	moveq.l	#1,d0
	move.l	_readjoypad(pc),a0
	jsr	(a0)
	move.l	d0,joy1_buttons

	CMPI.B	#$75,$bfec01  ; CIAA_SDR
.nope
	movem.l	(a7)+,a0/d0
	rts


pause_test:
	BUTTON_KEY_TEST	$7F,JPB_BTN_PLAY,1


player_2_grenade:
	BUTTON_KEY_TEST	$35,JPB_BTN_BLU,0

player_1_grenade:
	BUTTON_KEY_TEST	$37,JPB_BTN_BLU,1
	
fix_protection
	move.l	(0,a0,d1.l),d0	; not really necessary...
	rts
joy0_buttons
	dc.l	0
joy1_buttons
	dc.l	0
	