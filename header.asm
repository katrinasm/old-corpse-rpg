addr.seek($00ffb0)
// ROM header information.
db	"KT"		// Maker code.
db	"CRPG"		// Game code.
db	0, 0, 0, 0, 0, 0, 0
db	0			// Expansion RAM.
db	0			// Special Version.
db	0			// Cartridge type.
db	"Corpse RPG about Orin"	// Title string.
db	%00110000	// Map mode (LOROM)
db	$02			// ROM type (ROM+SRAM)
db	$01			// ROM size (lol)
db	$01			// SRAM size
db	0			// Sales code
db	$33			// fixed
db	0			// version number
dw	0			// ~checksum
dw	-1			// checksum	
// ROM vector information.
// Native mode vectors.
dw	0, 0	// Unused vectors.
dw	interrupt.COP
dw	interrupt.BRK
dw	interrupt.ABORT
dw	interrupt.NMI
dw	RESET
dw	interrupt.IRQ
// Emulation mode vectors.
dw	0, 0	// Unused vectors.
dw	interrupt.COP
dw	interrupt.BRK
dw	interrupt.ABORT
dw	interrupt.NMI
dw	RESET
dw	interrupt.IRQ
