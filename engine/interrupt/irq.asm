scope IRQ: {
	addr.allocmb(irqDp, 40);
	phd;
	pea irqDp; pld;
	rep #$30;
	sta $00;
	stx $02;
	
	
	
	rep #$30;
	lda $00;
	ldx $02;
	pld; rti;
}