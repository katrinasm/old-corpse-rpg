scope areas {
	addr.alignbank()
	headers:
		fill 256*32;
	
	data:
	
	variable areaCount(0);
	
	// Imports an area, incrementing the areaCount,
	// This defines areas.{name}, the area's numeric ID,
	// and inserts data for areas.headers.{name} and
	// areas.data.{name}.
	macro importarea(define name) {
		constant {name}(areaCount);
		
		push origin;
		addr.seek(headers + 32 * areaCount);
		insert headers.{name}, "areas/{name}.bin", 0, 32;
		pull origin;
		
		// data.{name}.size is forward-declared, and so we can use it before
		// we actually invoke the insertion of data.name.
		// However, "if" breaks for unknown reasons if data.{name}.size is
		// is used directly, hence the workaround.
		evaluate e(data.{name}.size);
		
		// First verify that it can be inserted at all...
		if {e} > $8000 {
			print "Area {name} too large for insertion."
			error "(data error)"
		}
		
		// If including it would currently cause a bank overrun,
		// move into the next bank.
		// The current naive implementation results in some sizable gaps,
		// that could be filled in by more data, but currently remain empty.
		// This is currently non-urgent and basically entails implementing
		// a linker, and so is not likely to be pursued.
		if (pc() & $ffff) + {e} >= $10000 {
			addr.alignbank();
		}

		insert data.{name}, "areas/{name}.bin", 32;
		
		// Finally, update the header pointers to their correct values.
		addr.seek(headers + 32 * areaCount + area.header.screensptr);
		dl data.{name}
		
		if pc() & $ffff == 0 {
			addr.seek(pc()|$008000)
		}
		
		areaCount = areaCount + 1;
	}
	
	importarea(chireiden)
	importarea(mugenkan)
	
	addr.alignbank();
	palettes:
	insert "pal/basic.bin"
}