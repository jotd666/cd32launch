Run your OS-compliant games with, added joypad controls & custom fixes

Howto:

- install "cd32launch" in C subdir of the CD/HD
- locate the executable of your game and type "cd32launch exe=game_executable"

Features:

- 
- Allow to start game without fast memory
- Allow to degrade to ECS or keep as AGA, remove caches or leave them
- Automatic patch mode (look for VBR read/writes and patches them to 0)
- Install a custom VBL handle to read joypad and issue keyboard interrupts (like CD32load & JST do)
- Can patch the executable with special mini-whdload-like slave (patchlist) to remove protections/fix stuff/perform assigns

Run it (through your favourite launcher):

example: cd32load assassin.slave CUSTOM1=1 JOY1GREEN=0x40

pressing green CD32 controller will issue rawkey 0x40 (space).

Basic options:

- SLAVE: mandatory: provide whdload slave to run
- DATA: like whdload, specify game files directory. Caution: if files aren't there, CD32Load can crash/abort
- BUTTONWAIT: if implemented in slave, will wait on title screens, loading screens...
- JOYPAD=0,1,2,3: 0: no remap, 1: remap only on port 0, 2: remap only on port 1, 3: remap both ports (2 player games)
- VK: enable virtual keyboard
- VM: enable virtual mouse
- JOYx<color/direction>: assign a raw keycode to a joypad button
- VMMODIFY,VMMODIFYBUT: see virtual mouse doc
- NOVBRMOVE: if game crashes, has strange behaviour with inputs try that (try JOYPAD=0 first!)
- IDEHD: force the use of hard drive even if there's a CD unit (CD0:)
- DISKUNIT: set unit of hard drive / cd. Useful if DH1: is the disk containing games.
- NTSC/PAL: force display either in NTSC or PAL
- CDFREEZE: blocks interrupts when accessing CD/HD. Turn it in case of problem on to see if it fixes the crash/lockup. Needed for
  some games (Pinball Dreams), crashes others (Apano Sin)
- FILECACHE: turns on file caching. Basically can be used with most 512K/1MB games. Not on 2MB games.
  A lot of games work fine and load quickly using FILECACHE on real hardware. On WinUAE it has little effect. Don't get fooled when testing
  your games on WinUAE, a lot of defects cannot be seen. If FILECACHE is accepted by the game, then use it as it almost acts like a RAM loader
  and it reduces the risk of read errors / interrupt / game conflicts.
- CPUCACHE: you might want to see if the game is faster with caches on. From my experience, a lot of games crash with caches on on this particular
  CD32 + chipmem only setup, so I turned it off by default from v0.24
- CD1X: (not supported with RNCD or IDEHD): sets CD speed to 1x instead of default 2x

The joypad read routine may conflict with existing slave/game read routine, specially if game/slave supports 2nd button/joypad.

- Default is JOYPAD=2: means port 1 has button redirection to keys.
- JOYPAD=3 turns both joyports on for redirection
- JOYPAD=1 means that only port 0 has button redirection
 (useful when conflicts with game controls. Use JOYPAD=1 JOY0BLUE=0x19 JOY0RED=0x40 to enable P on RMB & spc on LMB on a 1-player game)
- JOYPAD=0 turns it off on both ports (required when slave/game already supports joypad buttons / 2 player mode & control conflicts)

- By default, joypad port 1 mapping is enabled like this:
  * blue => space
  * green => return
  * yellow => left ALT
  * play => P
  * bwd => F1
  * fwd => F2
  * fwd+bwd => ESC
- By default, joypad port 0 mapping is enabled like this:
  * blue => 2
  * green => 1
  * yellow => backspace
  * play => P
  * bwd => F3
  * fwd => F4
  * fwd+bwd => ESC

To disable a given default remapping, just set it to 0: JOY1BLUE=0x00

Note that you can reset the console by pressing all color buttons + play button simultaneously
(avoids knocking off the beer when getting up to press CD32 reset button)

CUSTOMx options:

Hold buttons at CD32Load startup to set CUSTOMx=1 even if not set by command line. Useful on read-only media!!
ATM only value 1 can be set (it is the most useful). Of course, multiple presses enable several CUSTOMx flags

- Blue:    CUSTOM1=1
- Yellow:  CUSTOM2=1
- Green:   CUSTOM3=1
- Reverse: CUSTOM4=1
- Forward: CUSTOM5=1



Contributors:

- JOTD: main source code, bits & pieces integration of all parts & whdload emulation
- Earok & Akira: helping me get the idea :)



enjoy!
