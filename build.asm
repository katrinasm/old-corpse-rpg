arch "./snes.arch"
include "lib/addr.asm"

// Blank the ROM, making an empty 4MB file.
addr.seek($008000);
fill 1024 * 1024 * 4;

addr.seek($008000);

// Interrupts need to be included specially, because they /must/ be in bank 0.
// The rest of the game engine is in bank $01.
include "engine/interrupt/interrupt.asm"

constant ENGINE_BEGIN($018000)
constant RRES_BEGIN($208000)
constant CRES_BEGIN($608000)

RESET:
	clc; xce;	// Exit 6502 emu mode
	lda #$01; sta $420d;	// FastROM enable
	jml +; +;	// Dummy jump into FastROM mirror region
	phk; plb;	// Move data bank into FastROM mirror region
	rep #$20; lda #>addr.stacktop; tas; sep #$20;	// Update stack position
	rep #$10;	// The game uses 16-bit addresses when possible.
	
	lda #$00
	sec
	sbc #$ff
	lda #$00
	clc
	sbc #$ff
	
	jml cmain.Init;

addr.seek(ENGINE_BEGIN);
eng_begin:
include "engine/engine.asm"
eng_end:

include "cres.asm"
include "rres.asm"

include "header.asm"

if {defined MEMUSE} {
	print "\nROM usage: \n"
	print "    Engine: ", (eng_end-eng_begin), " B \n"
	print "RAM usage:\n"
	print "    ZP: "; addr.print(addr.freezp - addr.firstzp); print " B\n";
	print "    MB: "; addr.print(addr.freemb - addr.firstmb); print " B\n";
	print "    7E: "; addr.print(addr.free7e - addr.first7e); print " B\n";
}