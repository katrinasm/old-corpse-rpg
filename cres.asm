// This file, and all the compressed data it includes,
// is automatically generated by cres.py.
// The included files originate in the folder "compress",
// and a compressed copy of each is placed in "compressed".
// Please use only the constants defined in this file,
// rather than the change-prone numerical literals they map to.

addr.seek(CRES_BEGIN);

scope cres: {
	fileptrs:
		dl data.corpse_rpg
		dl data.digits
		dl data.gfx
		dl data.kisume_walking
		dl data.orin_walking
		dl data.portal
		dl data.shadow
		dl data.testregion
		dl data.yinyang
		dl data.yuuka_walking
	scope ids {
		constant corpse_rpg(0);
		constant digits(1);
		constant gfx(2);
		constant kisume_walking(3);
		constant orin_walking(4);
		constant portal(5);
		constant shadow(6);
		constant testregion(7);
		constant yinyang(8);
		constant yuuka_walking(9);
	}
	scope data: {
		insert corpse_rpg, "res/compressed/corpse_rpg.rpd";
		insert digits, "res/compressed/digits.rpd";
		insert gfx, "res/compressed/gfx.rpd";
		insert kisume_walking, "res/compressed/kisume_walking.rpd";
		insert orin_walking, "res/compressed/orin_walking.rpd";
		insert portal, "res/compressed/portal.rpd";
		insert shadow, "res/compressed/shadow.rpd";
		insert testregion, "res/compressed/testregion.rpd";
		insert yinyang, "res/compressed/yinyang.rpd";
		insert yuuka_walking, "res/compressed/yuuka_walking.rpd";
	}
}