scope video {
	constant tilemapL1($a000);
	constant tilemapL2($a800);
	constant tilemapL3($b000);
	constant tilemapL4($b800);
	
	constant nameL1($0000);
	constant nameL2($0000);
	constant nameL3($8000);
	constant nameL4($9000);
	constant nameObj($c000);
	
	constant windowLeft(8);
	constant windowRight($f7);
	
	constant vrL1T(tilemapL1>>1);
	constant vrL2T(tilemapL2>>1);
	constant vrL3T(tilemapL3>>1);
	constant vrL4T(tilemapL4>>1);

	addr.allocmb(hdmaEn, 1);
	addr.allocmb(mosaic, 1);
	addr.allocmb(brightness, 1);
	addr.allocmb(cgwsel, 1);
	addr.allocmb(cgadsub, 1);
	addr.allocmb(subscr, 1);
	addr.allocmb(mainscr, 1);
	addr.allocmb(screenmode, 1);
	addr.allocmb(obj, $220);
	
	addr.alloc7e(palette, $200);
	
	addr.allocmb(scrollColDests, 6)
	constant scrollL1ColDest(scrollColDests);
	constant scrollL2ColDest(scrollColDests+2);
	constant scrollL3ColDest(scrollColDests+4);
	addr.allocmb(scrollRowDests, 6)
	constant scrollL1RowDest(scrollRowDests);
	constant scrollL2RowDest(scrollRowDests+2);
	constant scrollL3RowDest(scrollRowDests+4);
	addr.alloc7e(scrollL1ColBuf, $0040);
	addr.alloc7e(scrollL1RowBuf, $0040);
	addr.alloc7e(scrollL2ColBuf, $0040);
	addr.alloc7e(scrollL2RowBuf, $0040);
	addr.alloc7e(scrollL3ColBuf, $0040);
	addr.alloc7e(scrollL3RowBuf, $0040);
	
	addr.alloc7e(playerGfx, $7c00);
	
	constant sprgfx($7f0000)
	
	scope camera {
		addr.alloczp(posX, 2);
		addr.alloczp(posZ, 2);
		addr.alloczp(lastPosX, 2);
		addr.alloczp(lastPosZ, 2);
		addr.allocmb(lastCol, 2);
		addr.allocmb(lastRow, 2);
	}
	
	include "boot.asm"
	
	// Copy all the PPU mirrors into the appropriate PPU registers.
	// This has the notable exception of brightness, which, if enabled, causes weird problems.
	// So brightness should be handled separately.
	Mirror: {
		lda >video.subscr; sta $212c;
		lda >video.mainscr; sta $212d;
		lda >video.cgwsel; sta $2130;
		lda >video.cgadsub; sta $2131;
		lda >video.screenmode; sta $2105;
		lda <video.camera.posX; sta $210d; lda <video.camera.posX+1; sta $210d;
		lda <video.camera.posX; sta $210f; lda <video.camera.posX+1; sta $210f;
		lda <video.camera.posX; sta $2111; lda <video.camera.posX+1; sta $2111;
		lda <video.camera.posZ; sta $210e; lda <video.camera.posZ+1; sta $210e;
		lda <video.camera.posZ; sta $2110; lda <video.camera.posZ+1; sta $2110;
		lda <video.camera.posZ; sta $2112; lda <video.camera.posZ+1; sta $2112;
		
		rtl;
	}
	
	// This modifies the color math to use the game's "universal" settings.
	scope ConfigColorMath: {
		phd;
		pea $2100; pld;
		
		lda #<(nameObj>>14)&$07; sta $2101;
		lda #<(nameL1>>9)|(nameL2>>13); sta <$210b;
		lda #<(nameL3>>9)|(nameL4>>13); sta <$210c;
		lda #<(tilemapL1>>9)&$fc; sta <$2107;
		lda #<(tilemapL2>>9)&$fc; sta <$2108;
		lda #<(tilemapL3>>9)&$fc; sta <$2109;
		lda #<(tilemapL4>>9)&$fc; sta <$210a;
		lda #$aa; sta <$2123; sta <$2124; sta <$2125;
		lda #<windowLeft; sta <$2126; sta <$2128;
		lda #<windowRight; sta <$2127; sta <$2129;
		lda #$e0; sta <$2132;
		
		pld;
		rtl;
	}
	
	scope clearObj: {
		lda #$f0;
		ldx #$01ec;
		-;	sta >obj+1,x;
			dex #4; bpl -;
		lda #$00;
		ldx #$001f;
		-;	sta >obj+$200,x;
			dex; bpl -;
		rtl;
	}
	
	// Copies the OAM mirror into the hardware OAM.
	scope CopyOam: {
		stz $2102;
		sep #$20;
		ldx #$0400; stx $4300;
		ldx #>obj; stx $4302;
		lda #<obj>>16; sta $4304;
		ldx #$0220; stx $4305;
		
		lda #$01; sta $420b;
		rtl;
	}
	
	scope UploadScrollBuffers: {
		phb; phk; plb;
		ldy #$0004;
	cols:
		ldx >scrollColDests,y; beq +;
		lda #$81; sta $2115;
		stx $2116;
		
		ldx #$1801; stx $4300;
		ldx scrollColPtrs,y; stx $4302;
		lda #<(scrollL1ColBuf>>16); sta $4304;
		ldx #$0040; stx $4305;
		lda #$01; sta $420b;
		rep #$20; lda #$0000; sta >scrollColDests,y; sep #$20;
	+
		dey #2; bpl cols;
	
		ldy #$0004;
	rows:
		ldx >scrollRowDests,y; beq +;
		lda #$80; sta $2115;
		stx $2116;
		
		ldx #$1801; stx $4300;
		ldx scrollRowPtrs,y; stx $4302;
		lda #<(scrollL1RowBuf>>16); sta $4304;
		ldx #$0040; stx $4305;
		lda #$01; sta $420b;
		rep #$20; lda #$0000; sta >scrollRowDests,y; sep #$20;
		
	+
		dey #2; bpl rows;
		plb; rtl;
	
	scrollColPtrs:
		dw scrollL1ColBuf, scrollL2ColBuf, scrollL3ColBuf
	scrollRowPtrs:
		dw scrollL1RowBuf, scrollL2RowBuf, scrollL3RowBuf
	}
}