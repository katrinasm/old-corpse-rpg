scope area: {
	addr.alloczp(screens, 3);
	addr.alloczp(sprites, 3);
	addr.alloczp(width, 1);
	addr.alloczp(height, 1);
	addr.allocmb(screenRows, 16);
	// Call with A = area #, X = initial X pos, Y = initial Z pos
	
	// Definitions of header bytes.
	// The header overall is 32 bytes, ~1/4 of which is unused.
	scope header {
		constant screensptr(0); // Three byte ptr to screen data.
		constant spritesptr(3); // Three byte ptr to sprite data.
		constant imagesptr(6); // Three byte ptr to images table for this area.
		constant dimensions(9); // One byte, 4 bits width / 4 bits height.
		constant pal(10);        // One byte, palette number.
		constant cgwsel(11);     // One byte, CGWSEL setting.
		constant cgadsub(12);    // One byte, CGADSUB setting.
		constant subscr(13);    // One byte, subscreen setting.
		constant mainscr(14);   // One byte, mainscreen setting.
		constant fggfx1(15);    // One byte, graphics file for FG
		constant fggfx2(16);    // One byte, graphics file for FG
		constant auxgfx(17);    // One byte, graphics file for layer 3
		constant unused(18);	// Remainder of structure unused.
	}
	
	// Mx -> Mx
	// Call with A8 = area number,
	// X16 = Player X position within area,
	// Y16 = Player Z position within area
	scope Load: {
		constant headers(rres.areas.headers);
		pei ($00); pei ($02); pei ($04);
		
		// Set up the player as the guaranteed first sprite.
		pha; phx; phy;
		ldy #>sprite.id.orin; ldx #$0000;
		jsl sprite.InitSingle;
		ply; plx;
		
		stx >sprite.bodies+sprite.posX;
		sty >sprite.bodies+sprite.posZ;
		
		rep #$20;
		stz >sprite.bodies+sprite.posY;
		sep #$20;
		stz >sprite.bodies+sprite.posXF;
		stz >sprite.bodies+sprite.posYF;
		stz >sprite.bodies+sprite.posZF;
		
		pla;
		rep #$20;
		and #$00ff; asl #5; tax;
		// set screen + sprite data pointers
		lda ^headers+header.screensptr,x; sta <screens;
		lda ^headers+header.spritesptr,x; clc; adc <screens; sta <sprites;
		sep #$20;
		lda ^headers+header.screensptr+2,x; sta <screens+2;
		lda ^headers+header.spritesptr+2,x; sta <sprites+2;
		
		// initialize dimensions
		lda ^headers+header.dimensions,x; and #$0f; sta >height;
		sta $00;
		lda ^headers+header.dimensions,x; and #$f0; lsr #4; sta >width;
		
		phx;
		
		// Initalize the row table.
		ldx #$0000; txa;
		-; sta >screenRows,x;
		clc; adc >width;
		inx; dec $00; bne -; 
		
		// Correctly anchor the camera to the screen.
		rep #$20;
		lda >sprite.bodies+sprite.posX; clc; adc #$0008; tax;
		sep #$20;
		ldy >sprite.bodies+sprite.posZ;
		jsl AnchorCamera;
		stx <video.camera.posX; stx <video.camera.lastPosX;
		sty <video.camera.posZ; sty <video.camera.lastPosZ;
		
		plx;
		
		// turn off screen so we can do uploads
		lda #$80; sta $2100;
		
		// upload palette to cgram
		rep #$20;
		lda ^headers+header.pal,x; and #$00ff; xba; asl;
		clc; adc #>rres.areas.palettes;
		sta $4302;
		sep #$20;
		
		lda #<rres.areas.palettes>>16; sta $4304;
		
		lda #$00; sta $2121;
		
		ldy #$2200; sty $4300;
		ldy #$0200; sty $4305;
		
		lda #$01; sta $420b;
		
		// set up video mirrors
		lda ^headers+header.cgwsel,x; sta >video.cgwsel;
		lda ^headers+header.cgadsub,x; sta >video.cgadsub;
		lda ^headers+header.subscr,x; sta >video.subscr;
		lda ^headers+header.mainscr,x; sta >video.mainscr;
		
		// load graphics
		lda #$80; sta $2115;
		ldy #$0000; sty $2116;
		
		ldy #$1801; sty $4300;
		
		// fg1 -> vram
		phx;
		lda #$00; xba; lda ^headers+header.fggfx1,x; tax;
		ldy #>video.sprgfx; lda #<video.sprgfx>>16;
		sty $4302; sta $4304;
		jsl decomp.DecompFile;
		sty $4305;
		lda #$01; sta $420b;
		plx;
		
		// fg2 -> vram
		phx;
		ldy #$2000; sty $2116;
		lda #$00; xba; lda ^headers+header.fggfx2,x; tax;
		ldy #>video.sprgfx; lda #<video.sprgfx>>16;
		sty $4302; sta $4304;
		jsl decomp.DecompFile;
		sty $4305;
		lda #$01; sta $420b;
		plx;
		
		// aux -> vram
		ldy #$4000; sty $2116;
		lda #$00; xba; lda ^headers+header.auxgfx,x; tax;
		ldy #>video.sprgfx; lda #<video.sprgfx>>16;
		sty $4302; sta $4304;
		jsl decomp.DecompFile;
		sty $4305;
		lda #$01; sta $420b;
		
		// update the screen to its initial position
		pei (<video.camera.posX);
		
		rep #$20;
		lda #$001f; sta $18;
		-;	jsr Scroll.col;
			lda <video.camera.posX; clc; adc #$0008; sta <video.camera.posX;
			sep #$20;
			jsl video.UploadScrollBuffers;
			rep #$20;
		dec $18; bpl -;
		
		sep #$20;
		
		plx; stx <video.camera.posX;
		plx; stx $04; plx; stx $02; plx; stx $00;
		
		lda #$81; sta $4200;
		rtl;
	}
	
	// .x -> Mx
	// Call with X16 = desired center X pos,
	// Y16 = desired center Z pos.
	// Returns X16 = upper left X pos,
	// Y16 = upper left Z pos.
	// Requires that width and height be set.
	scope AnchorCamera: {
		rep #$20;
		
		
	horizontal:
		txa; sec; sbc #$0080; bpl leftValid;
		ldx #$0000;
		bra vertical;
	leftValid:
		tax;
	vertical:
		tya; sec; sbc #$0070; bpl topValid;
		ldy #$0000;
		bra end;
	topValid:
		tay;
	end:
		sep #$20;
		rtl;
	}
	
	// .x -> mx
	// X = X pos,
	// Y = Z pos of tile
	// Returns with A = 16-bit tileN
	scope GetMetatileId: {
		// A screen is 256 bytes, and the level is w wide and h high.
		// To get our position, we take the high byte of the x & z pos,
		// and calculate 256 * (x + wz)
		rep #$20;
		tya; xba;
		sep #$20;
		sta $4202;
		lda >width; sta $4203;
		
		stx $1e;
		txa; and #$e0; lsr #3; sta $1e;
		tya; and #$e0; tsb $1e;
		rep #$20;
		lda $4216; xba;
		ora $1e;
		
		phy;
		phb;
		ldy >(screens+1); phy; plb; plb;
		clc; adc screens; tay; lda $0000,y;
		//tay; lda [screens],y;
		plb;
		ply;
		rtl;
	}
	
	// m. -> m.
	// Call with A16 = tile ID
	scope GetMetatileGfxPtr: {
		php; asl #7; clc; adc #>(rres.metatiles); sta $10;
		sep #$20;
		lda #<(rres.metatiles>>16); sta $12;
		plp; rtl;
	}
	
	// .x -> mx
	// Call with X = subtile x position,
	// Y = subtile z position
	// Clobbers X and Y.
	scope GetMetatileBehavior: {
		jsl GetMetatileId; jsl GetMetatileGfxPtr;
		txa; and #$0018; lsr #2; sta $13;
		tya; and #$0018; ora $13;
		ora #$0060;
		
		tay;
		lda [$10],y;
		rtl;
	}
	
	// .x -> .x
	scope Scroll: {
		php; phb;
		pei ($00); pei ($02); pei ($04);
		phk; plb;
		rep #$20;
	cols:
		lda <video.camera.posX; and #$fff8; cmp >video.camera.lastCol;
		beq rows;
		sta >video.camera.lastCol;
		bcs .right;
	.left:
		jsr col;
		bra rows;
	.right:
		lda <video.camera.posX; pha;
		clc; adc #$00f8; sta <video.camera.posX;
		jsr col;
		pla; sta <video.camera.posX; 
		
	rows:
		lda <video.camera.posZ; and #$fff8; cmp >video.camera.lastRow;
		beq return;
		sta >video.camera.lastRow;
		bcs .bottom;
	.top:
		jsr row;
		bra return;
	.bottom:
		lda <video.camera.posZ; pha;
		clc; adc #$00e0; sta <video.camera.posZ;
		jsr row;
		pla; sta <video.camera.posZ; 
	
	return:
		pla; sta $04; pla; sta $02; pla; sta $00;
		plb; plp; rtl;
	
		scope row: {
			lda <video.camera.posZ; and #$0018; sta $00;
			lda <video.camera.posX; sta $02;
			lda #$0007; sta $04;
			lda <video.camera.posX;
			and #$00e0; lsr #2; tax;
		loop:
			phx;
			ldx $02; ldy <video.camera.posZ;
			jsl GetMetatileId; jsl GetMetatileGfxPtr;
			plx;
			
			ldy $00;
			lda [$10],y; sta video.scrollL1RowBuf,x;
			iny #2;
			lda [$10],y; sta video.scrollL1RowBuf+2,x;
			iny #2;
			lda [$10],y; sta video.scrollL1RowBuf+4,x;
			iny #2;
			lda [$10],y; sta video.scrollL1RowBuf+6,x;
			
			lda $00; clc; adc #$0020; tay;
			lda [$10],y; sta video.scrollL2RowBuf,x;
			iny #2;
			lda [$10],y; sta video.scrollL2RowBuf+2,x;
			iny #2;
			lda [$10],y; sta video.scrollL2RowBuf+4,x;
			iny #2;
			lda [$10],y; sta video.scrollL2RowBuf+6,x;
			
		.while:
			lda $02; clc; adc #$0020; sta $02;
			txa; clc; adc #$0008; and #$0038; tax;
			dec $04; bpl loop;
			
		// We need to do some correction on the last tile if the screen isn't
		// aligned to a 32-pixel boundary.
			lda <video.camera.posX; and #$0018; beq end;
			lsr #2; tay;
			lda lastTilePtrs,y; sta $04;
			
			phx;
			lda <video.camera.posX; clc; adc #$0100; tax; ldy <video.camera.posZ;
			jsl GetMetatileId; jsl GetMetatileGfxPtr;
			plx;
			
			lda $10; clc; adc #$0020; sta $13;
			lda $12; sta $15;
			ldy $00;
			jmp ($0004);
		last3:
			lda [$10],y; sta video.scrollL1RowBuf,x;
			lda [$13],y; sta video.scrollL2RowBuf,x;
			iny #2; inx #2;
		last2:
			lda [$10],y; sta video.scrollL1RowBuf,x;
			lda [$13],y; sta video.scrollL2RowBuf,x;
			iny #2; inx #2;
		last1:
			lda [$10],y; sta video.scrollL1RowBuf,x;
			lda [$13],y; sta video.scrollL2RowBuf,x;
		end:
			lda <video.camera.posZ; and #$00f8; asl #2; sta $00;
			
			lda $00; clc; adc #>video.vrL1T; sta >video.scrollL1RowDest;
			lda $00; clc; adc #>video.vrL2T; sta >video.scrollL2RowDest;
			rts;
			
		lastTilePtrs:
			dw end, last1, last2, last3
		}
		
		scope col: {
			lda <video.camera.posX; and #$0018; lsr #2; sta $00;
			lda <video.camera.posZ; sta $02;
			lda #$0007; sta $04;
			lda <video.camera.posZ;
			and #$00e0; lsr #2; tax;
		loop:
			phx;
			ldx <video.camera.posX; ldy $02;
			jsl GetMetatileId; jsl GetMetatileGfxPtr;
			plx;
			
			lda $10; clc; adc $00; sta $10;
			
			lda [$10]; sta video.scrollL1ColBuf,x;
			ldy #$0008;
			lda [$10],y; sta video.scrollL1ColBuf+2,x;
			ldy #$0010;
			lda [$10],y; sta video.scrollL1ColBuf+4,x;
			ldy #$0018;
			lda [$10],y; sta video.scrollL1ColBuf+6,x;
			
			ldy #$0020;
			lda [$10],y; sta video.scrollL2ColBuf,x;
			ldy #$0028;
			lda [$10],y; sta video.scrollL2ColBuf+2,x;
			ldy #$0030;
			lda [$10],y; sta video.scrollL2ColBuf+4,x;
			ldy #$0038;
			lda [$10],y; sta video.scrollL2ColBuf+6,x;
			
		.while:
			lda $02; clc; adc #$0020; sta $02;
			txa; clc; adc #$0008; and #$0038; tax;
			dec $04; bpl loop;
			
			lda <video.camera.posX; and #$00f8; lsr #3; sta $00;
			
			lda $00; clc; adc #>video.vrL1T; sta >video.scrollL1ColDest;
			lda $00; clc; adc #>video.vrL2T; sta >video.scrollL2ColDest;
			rts;
		}
	}
	
	scope UpdateSprites: {
		
		rtl;
	}
}