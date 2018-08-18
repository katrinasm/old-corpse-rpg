scope NMI: {
	addr.allocmb(ran, 1);
	
	// Dummy jump into FastROM region.
	jml +; +;
	
	// Save registers on the stack.
	phb; phd;
	rep #$30;
	phx; phy; pha;
	phk; plb;
	
	// Move direct page onto $0000.
	lda #$0000; tad;
	
	sep #$20;
	// If the main loop hasn't concluded yet, skip NMI.
	lda >cmain.running; beq +; jmp ret; +;
	// Force blank.
	lda #$80; sta $2100;
	
	jsl video.CopyOam;
	jsl video.ConfigColorMath;
	jsl video.Mirror;
	jsl video.UploadScrollBuffers;
	
	jsl dynamo.UploadGfx;
	
	-; lda $4212; and #$01; bne -;
	rep #$20;
	lda $4218; sta >joypad.data;
	sep #$20;
	
	lda <joypad.directions; and #$f0; lsr #4; pha;
	lda #$0f; trb <joypad.buttons;
	lda #$f0; trb <joypad.directions;
	pla; tsb <joypad.buttons;
	
	lda >video.brightness; sta $2100;
	
	lda #$ff; sta >ran;
ret:
	// Pull registers and return.
	rep #$30;
	pla; ply; plx;
	pld; plb;
	rti;
}