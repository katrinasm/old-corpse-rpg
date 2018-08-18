scope textbox {
	// A textbox displays a message on Layer 4.
	// The message is an uncompressed string of 8-bit bytes,
	// terminated by a $00.
	// The meaning of the bytes is dependent on the font,
	// with the exceptions of $00-$1f, which are used as control
	// codes.
	// Some of these control codes match ASCII (such as newline),
	// but others bear no relation.
	
	// The message is rendered onto layer 4 as a VWF text.
	// It appears one character at a time, its speed determined
	// by the letterDelay setting.
	// The characters are uploaded to VRAM in a continuous block,
	// located after the message box graphics.
	
	// Note that all textbox routines expect the Layer 4
	// name area to begin with 32 tiles of box decoration,
	// and afterward will use as much memory for rendered text
	// as the message being displayed demands.
	
	addr.allocmb(activeMsg, 2);
	addr.allocmb(boxpos, 2);
	addr.allocmb(status, 2);
	addr.allocmb(textIndex, 2);
	addr.allocmb(letterDelay, 1);
	addr.allocmb(msgPtr, 3);
	
	// Mx -> Mx
	scope Boot: {
		ldx #$0000;
		stx >activeMsg;
		stx >boxpos;
		stx >status;
		stx >textIndex;
		lda #$04; sta >letterDelay;
		rtl;
	}
	
	// Mx -> Mx
	// X: Message number.
	// Y: Message Y position.
	// Registers a message for display.
	// The message will not be displayed unless something later calls
	// textbox.Main. Most game modes do this at the end of every frame.
	scope RegMsg: {
		stx >activeMsg;
		sty >msgPos;
		rep #$20;
		lda #$0001; sta >status;
		stz >textIndex;
		sep #$20;
		rtl;
	}
	
	// .x -> .x
	// This function, to be run once a frame when textboxes may appear,
	// handles the 
	scope Main: {
		// If no textbox is active, return immediately.
		ldx >status; bne +; rtl; +;
		// Function proper.
		php;
		
		
		
		plp; rtl;
	}
	
	scope Upload: {
		
	}
}