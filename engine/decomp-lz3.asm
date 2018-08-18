scope decomp: {
	scope DecompPtr: {
	// Call with $0d-$0f = src address, Y = dest addr, A = dest bank, M=1, X=0
	// Returns the decompressed file in A:Y.
	// Returns the decompressed file size in 16-bit Y.
		phb;
		pha; plb;
		sty $04;
		ldx #$0000;
		.loop: {
			lda [$0d]; sta $00; cmp #$ff; beq .ret;
			jsr incsrc;
			and #<%111'00000; cmp #<%111'00000; beq .longcom;
			
		.shortcom:
			lsr #4;	sta $01 // the check to get here sets A=$00 & %111'00000
			lda #$00; xba; lda $00; and #<%000'11111; tax;
			bra .comexec;
			
		.longcom:
			lda $00; and #<%000'111'00; lsr; sta $01;
			lda $00; and #<%000'000'11; xba;
			lda [$0d]; tax;
			jsr incsrc;
			
		.comexec:
			stz $02;
			phx;
			ldx $01;
			lda commands,x; sta $01;
			lda commands+1,x; sta $02;
			plx;
			pea .loop-1; jmp ($0001);
		}
	
	.ret:
		rep #$20; tya; sec; sbc $04; tay; sep #$20; 
		plb; rtl;
		
		scope commands: {
			dw .dcopy
			dw .bfill
			dw .wfill
			dw .zfill
			dw .rep
			dw .repbr
			dw .reprev
			
		.dcopy:
			lda [$0d]; sta y: 0; iny;
			jsr incsrc;
			dex; bpl .dcopy;
			rts;
			
		.bfill:
			lda [$0d]; jsr incsrc; bra .xfill;
		.zfill:
			lda #$00;
		.xfill:
			sta y: 0; iny;
			dex; bpl .xfill;
			rts;
			
		.wfill:
			lda [$0d]; xba; jsr incsrc; lda [$0d]; jsr incsrc;
		-;	xba; sta y: 0; iny; dex; bpl -;
			rts;
			
		.rep:
			jsr .repinit;
		-;	lda [$08]; sta y: 0; iny;
			jsr .repincsrc;
			dex; bpl -;
			rts;
			
		.repbr:
			jsr .repinit;
		-;	lda [$08]; sta $07; lda #$00;
			// reverse bit order
			lsr $07; rol;
			lsr $07; rol;
			lsr $07; rol;
			lsr $07; rol;
			lsr $07; rol;
			lsr $07; rol;
			lsr $07; rol;
			lsr $07; rol;
			sta y: 0; iny;
			jsr .repincsrc;
			dex; bpl -;
			rts;
			
		.reprev:
			lda #$00; xba;
			lda [$0d]; php; jsr incsrc; plp; bmi .rshort;
		.rlong:
			xba; lda [$0d];
			jsr incsrc;
			rep #$20;
			clc; adc $04; sta $08;
			sep #$20;
			phb; pla; sta $0a;
			bra .rloop;
		.rshort:
			and #$7f;
			rep #$20;
			eor #$ffff;	// add 1 and negate
			sty $08;
			clc; adc $08; sta $08;
			sep #$20;
			phb; pla; sta $0a;
		.rloop:
		-;	lda [$08]; sta y: 0; iny;
			rep #$20; dec $08; sep #$20;
			dex; bpl -;
			rts;
			
		.repinit:
			lda #$00; xba;
			lda [$0d]; php; jsr incsrc; plp; bmi .short;
		.long:
			xba; lda [$0d];
			jsr incsrc;
			rep #$20;
			clc; adc $04; sta $08;
			sep #$20;
			phb; pla; sta $0a;
			rts;
		.short:
			and #$7f;
			rep #$20;
			eor #$ffff;	// add 1 and negate
			sty $08;
			clc; adc $08; sta $08;
			sep #$20;
			phb; pla; sta $0a;
			rts;
			
		.repincsrc:
			rep #$20; inc $08; sep #$20; rts;
		}
		
		incsrc: {
			rep #$20; inc $0d; sep #$20; rts;
		}
	}
	
	scope DecompFile: {
		// call with 16-bit X = fnum, Y = dest addr, 8-bit A = dest bank
		pha;
		rep #$20; txa; sta $00; asl; clc; adc $00; tax; sep #$20;
		lda ^cres.fileptrs,x; sta $0d;
		lda ^cres.fileptrs+1,x; sta $0e;
		lda ^cres.fileptrs+2,x; sta $0f;
		pla;
		jmp DecompPtr;
	}
}