
// .x -> .x
scope MoveAndInteract2x1: {
	php;
	sep #$20;
	lda #$c0; sta d: occlusion;
	rep #$20;
	lda $00; pha; lda $02; pha;
	lda d: posX; sta $00;
	lda d: posZ; sta $02;
	
	jsl Move;
	
	ldx d: posX;
	ldy d: posZ;
	jsl area.GetMetatileBehavior;
	sta $10;
	and #$3f00; beq +; // if our behavior is 0, we have guaranteed passage
		lda $00; sta d: posX; tax;
		lda $02; sta d: posZ; tay;
		jsl area.GetMetatileBehavior;
		sta $10;
	+;
	sep #$20; lda $10; bpl +;
		lda #$80; sta d: occlusion;
	+;
	rep #$20;
	
	lda d: posX; clc; adc #$000f; tax;
	ldy d: posZ;
	jsl area.GetMetatileBehavior;
	sta $10;
	and #$3f00; beq +;
		lda $00; sta d: posX; tax;
		lda $02; sta d: posZ; tay;
		jsl area.GetMetatileBehavior;
		sta $10;
	+;
	sep #$20; lda $10; bpl +;
		lda #$80; sta d: occlusion;
	+;
	rep #$20;
end:
	pla; sta $02; pla; sta $00;
	plp; rtl;
}

// .. -> ..
scope Move: {
	php;
	sep #$20;
	lda d: spdX; sta $10;
	lda d: spdY; sta $13;
	lda d: spdZ; sta $16;
	rep #$20;
	stz $11; stz $14; stz $17;
	lda d: spdX-1; bpl +; dec $11; +
	lda d: spdY-1; bpl +; dec $14; +
	lda d: spdZ-1; bpl +; dec $17; +
	
	lda $10; asl #4; sta $10;
	lda $13; asl #4; sta $13;
	lda $16; asl #4; sta $16;
	
	sep #$20;
	lda d: posXF; clc; adc $10; sta d: posXF;
	rep #$20;
	lda d: posX; adc $11; sta d: posX;
	
	sep #$20;
	lda d: posYF; clc; adc $13; sta d: posYF;
	rep #$20;
	lda d: posY; adc $14; sta d: posY;
	
	sep #$20;
	lda d: posZF; clc; adc $16; sta d: posZF;
	rep #$20;
	lda d: posZ; adc $17; sta d: posZ;
	
	plp;
	rtl;
}

// .. -> Mx
scope GetDrawInfo: {
// Outputs draw X pos into $0010, Y pos into $0012, Z pos $0014
// Returns carry set if offscreen
	rep #$30;
	lda d: height; and #$00ff; sta $12;
	lda d: depth; and #$00ff; sta $14;
	lda >dynamo.imgCount; and #$00ff; asl #3; tay;
	sep #$20; inc >dynamo.imgCount; rep #$20;
	lda d: posX; sec; sbc >video.camera.posX; sta $10;
	lda d: posZ; sec; sbc d: posY; sec; sbc >video.camera.posZ;
	sec; sbc $12; sta $12;
	lda d: posZ; sta $14;
	lda $10; cmp #$0100; bcs offScreen;
	lda $12; cmp #$00f0; bcs offScreen;
	sep #$20; clc; rtl;
	
offScreen:
	sep #$21;
	dec >dynamo.imgCount;
	rtl;
}


scope CallCollides: {
	rep #$20;
	pei ($00);
	tda; sta $00; tax;
	sec; sbc.w #spriteSize;
do:
	jsl CheckCollision;
	bcc while;
	// call collision a
	tda; tax;
	
while:
	tda; sec; sbc.w #spriteSize; cmp.w #bodies; beq end;
	tad;
	txa; clc; adc.w #spriteSize; tax;
	bra do;
	
end:
	pla; sta $00;
	rtl;
}

scope CheckCollision: {
	
	rtl;
}
