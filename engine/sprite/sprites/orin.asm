scope orin {
	constant direction(misc);
	Init:
		stz d: direction;
		stz d: spdX;
		stz d: spdZ;
		stz d: spdY;
		lda #$08; sta d: depth;
		lda #$10; sta d: width;
		lda #$20; sta d: height;
		rtl;
		
	Main:
		
	// Set Orin's speed.
		lda #$00; xba;
		lda >joypad.directions; and #$03; tax;
		lda speedsX,x; sta d: spdX;
		lda >joypad.directions; and #$0c; lsr #2; tax;
		lda speedsZ,x; sta d: spdZ;
	// Set Orin's direction.
		lda >joypad.directions; and #$0f; beq +;
			tax; lda directionsByButton,x; bmi +;
				sta d: direction;
		+;
		
	// Move Orin.
		jsl MoveAndInteract2x1;
		
	// Move the camera to match Orin's position.
		rep #$20;
		lda d: posX; clc; adc #$0008; tax;
		ldy d: posZ;
		sep #$20;
		jsl area.AnchorCamera;
		stx >video.camera.posX;
		sty >video.camera.posZ;
		
		jsr draw;
		
	Collide:
	Kill:
		rtl;
		
		
	speedsX:
		db 0, $0c, -$0c, 0
	speedsZ:
		db 0, $0c, -$0c, 0
	directionsByButton:
		db $80, $06, $02, $80, $00, $07, $01, $80
		db $04, $05, $03, $80, $80, $80, $80, $80

		
	scope draw: {
		// Orin's graphics routine.
		jsl GetDrawInfo;
		// If she's moving, and it's the right frame, bounce 1px.
		stz $00; stz $01;
		lda d: spdX; ora d: spdZ; beq +;
			lda >cmain.clock; lsr #2; and #$01; sta $00;
		+;
		rep #$21;
		lda $10; sta >dynamo.imgList+dynamo.img.posX,y;
		lda $12; clc; adc $00; sta >dynamo.imgList+dynamo.img.posY,y;
		lda #>dynamo.imgs.orin_walking; sta >dynamo.imgList+dynamo.img.id,y;
		sep #$20;
		// If she's moving, incorporate the clock into her frame,
		// so she walks.
		stz $00;
		lda d: spdX; ora d: spdZ; beq +;
			lda >cmain.clock; lsr #2; and #$03; sta $00;
		+;
		lda d: direction; asl #2; ora $00; ora d: occlusion;
		sta >dynamo.imgList+dynamo.img.frame,y;
		lda $14; sta >dynamo.imgList+dynamo.img.posZ,y;
		
		// Draw her shadow.
		rep #$20; lda >dynamo.imgCount; and #$00ff; asl #3; tay;
		lda $10; sta >dynamo.imgList+dynamo.img.posX,y;
		// The Y position of the shadow has a lot of variables.
		lda d: posZ;
			sec; sbc #$0004;
			sec; sbc >video.camera.posZ;
		sta >dynamo.imgList+dynamo.img.posY,y;
		lda #>dynamo.imgs.shadow; sta >dynamo.imgList+dynamo.img.id,y;
		sep #$20;
		lda d: occlusion; sta >dynamo.imgList+dynamo.img.frame,y;
		lda $14; dec; sta >dynamo.imgList+dynamo.img.posZ,y;
		inc >dynamo.imgCount;
		
	ret:
		rts;
	}
}