scope joypad {
	addr.alloczp(data, 2);
	constant buttons(data); // byetaxlr
	constant directions(data+1); // 0000udlr
	constant BTN_B($80);
	constant BTN_Y($40);
	constant BTN_SELECT($20);
	constant BTN_START($10);
	constant BTN_A($08);
	constant BTN_X($04);
	constant BTN_L($02);
	constant BTN_R($01);
	constant DIR_UP($08);
	constant DIR_DOWN($04);
	constant DIR_LEFT($02);
	constant DIR_RIGHT($01);
}