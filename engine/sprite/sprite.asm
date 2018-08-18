scope sprite {
	constant numSprites(32);
	constant spriteExp(6);
	constant spriteSize(1 << spriteExp);
	constant allSize(numSprites * spriteSize);
	addr.allocmb(bodies, allSize);
	
	// This defines the offsets of each sprite's variables within
	// its data body.
	// Note that the first $20 bytes of the data body are reserved
	// for the frame context.
	constant flags($20);
	constant id($22);
	constant posX($24);
	constant posXF($26);
	constant posY($27);
	constant posYF($29);
	constant posZ($2a);
	constant posZF($2c);
	constant spdX($2d);
	constant spdY($2e);
	constant spdZ($2f);
	constant width($30);
	constant height($31);
	constant depth($32);
	constant elevation($33);
	constant blocked($34);
	constant occlusion($35);
	constant misc($36);
	constant data($3c);
	
	addr.allocmb(spritesRun, 1);
	addr.allocmb(lastObj, 1);
	
	// .. -> ..
	scope Init: {
		php;
		rep #$30;
		ldx #>(allSize - spriteSize);
		do:
			lda #$8000; sta >bodies+flags,x;
			stz >bodies+id,x;
		while:
			txa; sec; sbc #>spriteSize; tax;
			bpl do;
		plp; rtl;
	}
	
	// .. -> Mx
	scope InitSingle: {
		rep #$30;
		txa; clc; adc #>bodies; tax;
		sty x: <id;
		stz x: <flags;
		sep #$20;
		rtl;
	}
	
	// Mx -> Mx
	scope Run: {
		phd; phb;
		phk; plb;
		
		ldx #$0000;
		stx >spritesRun;
		
		loop:
			rep #$20;
			// Set up the addressing conditions for the sprite.
			lda >spritesRun; tax;
			asl #spriteExp; clc; adc #>bodies; tad;
			
			lda d: flags; bmi while;
			jsr runSprite;
		while:
			inc >spritesRun;
			lda >spritesRun; cmp.w #numSprites; bne loop;
		
		plb; pld; rtl;
	}
	
	// mx -> mx
	scope runSprite: {
		lda d: id; asl #4; tay;
		bit d: flags; bvs main;
	init:
		lda spritePtrs,y; sta $0000;
		lda #$7fff; sta d: flags;
		sep #$20;
		lda spritePtrs+2,y; sta $0002;
		phb;
		pha; plb;
		addr.Jslp($0000);
		plb;
	// Restore the table pointer for the main fallthrough.
		rep #$30; lda d: id; asl #4; tay;
	main:
		lda spritePtrs+3,y; sta $0000;
		lda #$7fff; sta d: flags;
		sep #$20;
		lda spritePtrs+5,y; sta $0002;
		phb;
		pha; plb;
		addr.Jslp($0000);
		plb;
		
		rep #$20;
		rts;
	}
	
	include "shared.asm"
	
	spritePtrs:
	variable registeredSprites(0);
	macro registerSprite(name) {
		addr.seek(spritePtrs + registeredSprites * 16);
		constant id.{name}(registeredSprites);
		dl {name}.Init, {name}.Main
		dl {name}.Collide, {name}.Kill
		
		registeredSprites = registeredSprites + 1;
	}
	
	registerSprite(nullSprite);
	registerSprite(orin);
	registerSprite(dummy);
	
	include "sprites/nullSprite.asm"
	include "sprites/orin.asm"
	include "sprites/dummy.asm"
}