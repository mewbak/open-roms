
// Well-known BASIC routine, described in:
//
// - [CM64] Compute's Mapping the Commodore 64 - page 97
// - https://www.lemon64.com/forum/viewtopic.php?t=64721&sid=bc400a5a6d404f8f092e4d32a92f5de7
// - https://www.lemon64.com/forum/viewtopic.php?t=70680&sid=3ff66caf7f5fdf2a3c2ff2ee31fc3fd8
// - https://codebase64.org/doku.php?id=base:assembling_your_own_cart_rom_image

NEWSTT:

	// XXX Real implementation is more complicated, it's actually a part
	// of the BASIC main loop. It is, however, often called by various
	// utilities to simply run the software which was just loaded or
	// uncompressed.

	// For now, let's cheat a little - this should provide some compatibility:

	jmp cmd_run
