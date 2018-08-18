scope cmain {
	addr.allocmb(gameMode, 1);
	addr.allocmb(running, 1);
	addr.allocmb(frame, 1);
	addr.allocmb(clock, 1);
	Init:
		jsl sprite.Init;
		stz >dynamo.imgCount; stz >dynamo.imgCount+1;
		//stz <joypad.buttons; stz <joypad.directions;
		
		sep #$20;
		lda #$81; sta $4200; cli;
		
		phk; plb;
	
		lda #$01; sta >gameMode;
	
	Main:
		stz >interrupt.NMI.ran;
		inc >frame;
		lda #$ff; sta >running;
		
		phb;
		
		lda #$00; xba; lda >gameMode; asl; adc >gameMode; tax;
		lda ^modeptrs,x; sta $00;
		lda ^modeptrs+1,x; sta $01;
		lda ^modeptrs+2,x; sta $02;
		
		pha; plb;
		
		addr.Jslp($0000);
		
		plb;
		
		jsl universal.Run;
		
		stz >running;
	.wait:
		wai;
		lda >interrupt.NMI.ran; bne Main; beq .wait;
		
	modeptrs:
		dl NullMode
		dl world.Init, world.Main
	
	NullMode:; rtl;
	
	variable modes(0);
	macro regmodeptr(label) {
		push origin
		addr.seek(modeptrs + modes * 3);
		cengine.modes = cengine.modes + 1;
		pull origin
	}
}
include "variables.asm"

include "video/video.asm"
include "dynamo.asm"
include "universal.asm"
include "decomp.asm"
include "area.asm"
include "sprite/sprite.asm"
include "world/world.asm"