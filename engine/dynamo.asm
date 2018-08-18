scope dynamo: {
	constant imgExp(3);
	constant imgSize(1<<imgExp);
	constant maxImgs(64);
	
	constant maxImgsInGame(256);
	
	constant ptrExp(0);
	constant ptrSize(1<<ptrExp);
	addr.allocmb(imgList, maxImgs * imgSize);
	addr.allocmb(imgUploadInfo, maxImgs * 8);
	addr.allocmb(imgUploadIndex, 2);
	
	addr.allocmb(imgCount, 2);
	addr.allocmb(tilesDrawn, 2);
	
	addr.allocmb(imgIndexes, maxImgs);
	
	addr.allocmb(gfxPtrs, maxImgsInGame * 2);
	
	// The layout of an image in memory.
	scope img {
		constant id(0);
		constant posZ(2);
		constant frame(3);
		constant posX(4);
		constant posY(6);
	}
	
	// The layout of an image's rom description.
	scope imgdesc {
		constant width(0);
		constant height(1);
		constant frames(2);
		constant pal(4);
		constant imgfile(6);
	}
	
	constant gfx($7f0000);
	
	scope Draw: {
		phb;
		phk; plb;
		pei ($00);
		lda >imgCount; beq end;
		sta $00;
		rep #$20;
		ldy >imgCount;
		lda #$0000; tax;
		initIndexes:
			cpy #$0000; beq +;
			sta imgIndexes,x; inx #2;
			clc; adc #$0008;
			dey; bpl initIndexes;
		+;
		
		jsr sortImgs;
		
		stz >tilesDrawn;
		sep #$20;
		ldx #$0000; txy;
		stx >imgUploadIndex;
	imgLoop:
		lda #$00; xba; lda $00; dec; asl; tay;
		ldx >imgIndexes,y;
		jsr drawImg;
		
		dec $00; bne imgLoop;
	end:
		plx; stx $00;
		plb;
		rtl;
	}	
	
	scope drawImg: {
		rep #$20;
		// y = img data table entry
		lda >imgList+img.id,x; asl #3; tay;
		
		// We're in 16-bit mode, so this reads off
		// the width and height, and multiplies them
		// by each other.
		lda imgs+imgdesc.width,y; sta $4202; sta $18;
		
		phy;
		// Read out the graphics pointer:
		// We take $7e0000 | (gfxPtrs[imgfile] << 1)
		lda imgs+imgdesc.imgfile,y; asl; tay;
		lda gfxPtrs,y; asl; sta $10;
		// 8-bit A
		sep #$20; 
		lda #$3f; rol; sta $12;
		
		ply;
		// Set up the palette as part of our properties.
		lda imgs+imgdesc.pal,y; asl; sta $13;
		lda imgList+img.frame,x; and #$c0; lsr #2; tsb $13;
		
		// Collect all the image visual data, and put it in
		// imgUploadInfo.
		ldy >imgUploadIndex;
		// Get our frame, and find the upload start address.
		// The upload start is $10 (= base ptr) + frame * width * height * 32.
		sep #$20;
		lda >imgList+img.frame,x; and #$3f; sta $4202;
		lda $4216;
		pha;
		sta $4203;
		nop #8;
		rep #$20;
		lda $4216; asl #5; clc; adc $10; sta >imgUploadInfo,y;
		
		sep #$20;
		lda $12; sta >imgUploadInfo+2,y;
		
		// Having this, we now take the size: width * height * 32, 
		// and put that in the list.
		pla;
		rep #$20;
		and #$00ff; asl #5; sta >imgUploadInfo+3,y;
		
		iny #5; sty >imgUploadIndex;
		
		sep #$20;
		// Now we lay out the tiles in OAM.
		// $10 = image X
		// $11 = image Y
		// $14 = tile X
		// $15 = tile Y
		// tilesDrawn = tile ID
		// $13 = tile properties
		lda >imgList+img.posX,x; sta $10; sta $14;
		lda >imgList+img.posY,x; sta $11; sta $15;
		
		// This is our loop counter, the height of the image.
		// ($19 is set by the earlier 16-bit write to $18)
		lda $19; sta $17; 
		
		rep #$20; lda >tilesDrawn; and #$00ff; asl #2; tay; sep #$20;
		
		drawRows:
			lda $18; sta $16;
			lda $10; sta $14;
			stz $1d;
			drawTiles:
				lda $14; sta >video.obj,y;
				lda $15; sta >video.obj+1,y;
				lda $1d; beq +; lda #$f0; sta >video.obj+1,y; +;
				lda >tilesDrawn; sta >video.obj+2,y;
				//              yxppccct
				lda $13; sta >video.obj+3,y;
				lda $14; clc; adc #$08; bcs endRow;
				sta $14;
				iny #4;
				lda >tilesDrawn; inc; sta >tilesDrawn;
				dec $16; bne drawTiles;
		endRow:
			lda $16; clc; adc >tilesDrawn; sta >tilesDrawn;
			lda $15; clc; adc #$08; sta $15;
			dec $17; bne drawRows;
			
		sep #$20;
		rts;
	}
	
	scope UploadGfx: {
		lda #$80; sta $2115;
		lda >imgCount; beq ret;
		ldx #$1801; stx $4300;
		ldx #>video.nameObj>>1; stx $2116;
		ldx #$0000;
		loop:
			lda >imgUploadInfo,x; sta $4302; inx;
			lda >imgUploadInfo,x; sta $4303; inx;
			lda >imgUploadInfo,x; sta $4304; inx;
			lda >imgUploadInfo,x; sta $4305; inx;
			lda >imgUploadInfo,x; sta $4306; inx;
			lda #$01; sta $420b;
			dec >imgCount; bne loop;
	ret:
		rtl;
	}
	
	scope sortImgs: {
		// This is an insertion sort (O(n^2) but generally performant for small n)
		// of the indices of the imgs, by the Z-order of the imgs they point to.
		// It is faster to sort indices because they (2 bytes)
		// are smaller than the imgs they point to (8 bytes), and can be moved
		// in a single instruction.
		lda >imgCount; beq end;
		// Set up our loop counter.
		asl; sta $14; stz $15;
		rep #$20;
		ldx #$0002;
		for:
			ldy >imgIndexes,x; sty $12;
			lda imgList+img.posZ,y; sta $10;
			phx;
			txy; dey #2;
			while:
				ldx >imgIndexes,y;
				sep #$20;
				lda >imgList+img.posZ,x;
				cmp $10;
				rep #$20;
				bcc endwhile; beq endwhile;
				
				lda imgIndexes,y; sta imgIndexes+2,y;
				
				dey #2; bpl while;
			endwhile:
			plx;
			lda $12; sta >imgIndexes+2,y;
		loopfor:
			inx #2; cpx $14; bcc for;
	end:
		sep #$20;
		rts;
	}
	
	variable registeredImgs(0);
	scope imgs: {
		macro regImg(name, w, h, pal, frames) {
			db {w}, {h}, {frames}, 0
			dw {pal}
			dw cres.ids.{name}
			constant {name}(registeredImgs);
			registeredImgs = registeredImgs + 1;
		}
		
		regImg(digits, 1, 1, 0, 256);
		regImg(orin_walking, 2, 4, 0, 8*4);
		regImg(yuuka_walking, 2, 5, 0, 1);
		regImg(shadow, 2, 1, 0, 1)
	}
}