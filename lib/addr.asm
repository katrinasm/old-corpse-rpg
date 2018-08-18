// 
// Macros for use in handling the particularities of the SNES
// that bass doesn't handle on its own.
// 
scope addr: {
	
	constant stacktop($1fff)
	
	// Translates a LoROM address to a pc file offset.
	// This doesn't work quite right if anything crosses a bank boundary
	// - it overflows from $ffff to $0000 instead of $ffff to $8000,
	// which is what it should do, but bass has no way to fix that.
	macro seek(evaluate offset) {
		origin (({offset} & $7fff) | (({offset} & $7f0000) >> 1))
		base {offset} | $800000
	}
	
	// If the PC is not currently aligned to the start of a bank,
	// move to the next bank.
	// This is useful for storing large power-of-two sized data structures.
	macro alignbank() {
		addr.seek((pc() & $ff8000) + $010000)
	}
	
	// Prints a 24-bit address in hexadecimal, a feature which bass,
	// for some reason, does not have.
	macro scope print(evaluate addr) {
		variable i(0);
		variable c(0);
		print "$"
		while ( i < 6 ) {
			c = ({addr} >> (4 * (5-i))) & $0f;
			
			if c < 10 {
				putchar(c + 48);
			} else {
				putchar(c - 10 + 97);
			}
			
			i = i + 1;
		}
	}
	
	macro println(evaluate addr) {
		addr.print({addr});
		print "\n";
	}
	
	macro Jslp(ptr) {
		phk; pea .retp{#}-1;
		jmp [{ptr}];
		.retp{#}:;
	}
	
	// Static memory allocation macros.
	// 
	// The "targ" in these macros is a constant name
	// to define with an unused memory location.
	// 
	// alloczp returns an address for use as direct page memory.
	//   Its use should be sparse.
	// allocmb gives an address for use as data bank memory.
	// alloc7e gives an address for use as long memory,
	//   intended for large long-lived data structures.
	
	constant firstzp($20);
	constant firstmb($0100);
	constant first7e($7e2000);
	
	variable freezp($20);
	variable freemb($0100);
	variable free7e($7e2000);
	macro alloczp(targ, variable size) {
		constant {targ}(addr.freezp);
		addr.freezp = addr.freezp + size;
		if addr.freezp > $ff {
			print "Direct page memory overflowed (";
			print {targ} ",", addr.freezp ")\n";
			error "(memory error)";
		}
	}
	macro allocmb(targ, variable size) {
		constant {targ}(addr.freemb);
		addr.freemb = addr.freemb + size;
		if addr.freemb > $1cff {
			print "Bank-mirrored memory overflowed (";
			print {targ} ",", addr.freemb ")\n";
			error "(memory error)";
		}
	}
	macro alloc7e(targ, variable size) {
		constant {targ}(addr.free7e);
		addr.free7e = addr.free7e + size;
		if addr.free7e > $7effff {
			print "Bank 7e static memory overflowed ({targ}, "
			addr.print(addr.free7e);
			print ")\n"
			error "(memory error)";
		}
	}
}