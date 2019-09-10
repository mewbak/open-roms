
// Just a helper routines

// Find the LAT / SAT / FAT entry index where LAT corresponds to A, returns index in Y
// Carry flag set means not found

find_fls:

	ldy LDTND
	beq find_fls_not_found // table empty
!:
	dey
	bmi find_fls_not_found // no more entries
	cmp LAT, y
	bne !- // does not match, try the next one

	clc
	rts

find_fls_not_found:

	sec
	rts
