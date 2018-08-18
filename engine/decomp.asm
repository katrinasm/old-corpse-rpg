scope decomp: {
	// Mx -> Mx
	scope DecompPtr: {
	// Call with $10-$12 = src address, Y = dest addr, A = dest bank
	// Returns the decompressed file size in 16-bit Y.
	
	// During the routine, $16-$1e are used as the Paeth-coding prediction buffer.
	// $13-14 holds the initial address.
	// $15 holds the length of a run or nonrun.
	// $16 holds the value of a run.
		phb;
		
		pha; plb;
		sty $13;
		
	read_com:
		lda [$10]; beq ret; bmi run;
	scope nonrun: {
		sta $15;
	.loop:
		ldx $10; inx; stx $10;
		lda [$10];
		sta $0000,y; iny;
		dec $15; bne .loop;
		
		ldx $10; inx; stx $10;
		bra read_com;
	}
	scope run: {
		and #$7f; sta $15;
		ldx $10; inx; stx $10;
		lda [$10];
	.loop:
		sta $0000,y; iny;
		dec $15; bne .loop;
		
		ldx $10; inx; stx $10;
		bra read_com;
	}
	ret:
		rep #$20; tya; sec; sbc $13; tay; sep #$20;
		addr.println(pc())
		plb; rtl;
	}
	
	// Mx -> Mx
	scope DecompFile: {
		addr.println(pc())
		// call with 16-bit X = fnum, Y = dest addr, 8-bit A = dest bank
		pha;
		rep #$20; txa; sta $10; asl; clc; adc $10; tax; sep #$20;
		lda ^cres.fileptrs,x; sta $10;
		lda ^cres.fileptrs+1,x; sta $11;
		lda ^cres.fileptrs+2,x; sta $12;
		pla;
		jmp DecompPtr;
	}
}