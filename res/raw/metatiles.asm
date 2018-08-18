addr.alignbank()

scope metatiles: {
	constant l1(pc());
	constant l2(pc()+32);
	constant l3(pc()+64);
	constant behavior(pc()+96);
	insert "metatiles.bin"
}