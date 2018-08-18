scope interrupt: {
	COP:
	BRK:
	ABORT:
		rti;
	include "nmi.asm";
	include "irq.asm";	
}