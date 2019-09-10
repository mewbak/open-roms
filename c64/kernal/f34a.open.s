
//
// Official Kernal routine, described in:
//
// - [RG64] C64 Programmer's Reference Guide   - page 289
// - [CM64] Compute's Mapping the Commodore 64 - page 230/231
//
// CPU registers that has to be preserved (see [RG64]): none
//


OPEN:

	// Reset status
	jsr kernalstatus_reset

	// Check if the logical file number is unique
	ldy LDTND
!:
	beq !+
	dey
	lda LAT, y
	cmp current_logical_filenum
	bne open_not_yet_open
	jmp kernalerror_FILE_ALREADY_OPEN
open_not_yet_open:
	cpy #$00
	jmp !-
!:
	// Check if we have space in tables

	ldy LDTND
	cpy #$0A
	bcc open_has_space
!:
	// Table is full
	jmp kernalerror_TOO_MANY_OPEN_FILES

open_has_space:

	// Update the tables

	// LAT / FAT / SAT support implemented according to
	// 'Compute's Mapping the Commodore 64', page 52

	lda current_logical_filenum
	sta LAT, y
	lda current_device_number
	sta FAT, y
	lda current_secondary_address
	sta SAT, y

	iny
	sty LDTND

	// Check for command to send
	lda FNLEN
	beq open_done_success
	
	// Check for IEC device
	lda current_device_number
	jsr iec_check_devnum
	bcc open_iec

	// FALLTROUGH
open_done_success:

	clc
	rts

open_iec:

	// We have a command to send to IEC device
	jsr LISTEN
	bcc !+
	jmp kernalerror_DEVICE_NOT_FOUND
!:
	lda current_secondary_address
	jsr iec_cmd_open
	bcc !+
	jmp kernalerror_DEVICE_NOT_FOUND
!:

	// We need our helpers to get to filenames under ROMs or IO area
	jsr install_ram_routines

	// Send command ('file name')
	jsr lvs_send_file_name

	jmp open_done_success