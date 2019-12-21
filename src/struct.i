
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
cpucache_flag
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



