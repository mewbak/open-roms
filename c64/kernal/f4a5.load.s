//
// Official Kernal routine, described in:
//
// - [RG64] C64 Programmer's Reference Guide   - page 286
// - [CM64] Compute's Mapping the Commodore 64 - page 231
// - IEC reference at http://www.zimmers.net/anonftp/pub/cbm/programming/serial-bus.pdf
//
// CPU registers that has to be preserved (see [RG64]): none
//


	// Expects that SETLFS and SETNAM are called before hand.
	// $YYXX = load address.
	// (ignored if SETLFS channel = 1, i.e., like ,8,1)
	// If A=1 then VERIFY instead of LOAD.
	// On exit, $YYXX is the highest address into which data
	// will have been placed.

	// XXX honor MSGFLG bit 6
	// XXX add VERIFY support

LOAD:

	// Are we loading or verifying?
	sta VERCKK

	// Store start address of LOAD
	stx STAL+0
	sty STAL+1

	// Reset status
	jsr kernalstatus_reset

	// We need our helpers to get to filenames under ROMs or IO area
	jsr install_ram_routines

	// Allow platform-specific routine to takeover the flow
	TARGET_HOOK_LOAD()

	// Check whether we support the requested device
	lda current_device_number
	and #$FC
	bne !+
	jmp lvs_illegal_device_number // device number below 4, not an IEC device
!:
	// Device numbers above 30 are also illegal (see https://www.pagetable.com/?p=1031),
	// as the protocol combines device number with command code int one byte,
	// above 30 it is no longer possible (UNLISTEN and UNTALK codes prevent using
	// number 31), yet original ROMs show ILLEGAL DEVICE NUMBER error only
	// for devices 0-3; in our implementation LISTEN / TALK will cause device
	// not present detected for numbers above 30

	// Display SEARCHING FOR + filename
	jsr lvs_display_searching_for

	// http://www.zimmers.net/anonftp/pub/cbm/programming/serial-bus.pdf
	// p13, 16; also p16 tells us this routine doesn't mess with the file table
	// in the C64, only in the drive.

	// Call device to LISTEN (p16)
	lda current_device_number
	jsr LISTEN
	bcc !+
	jmp lvs_device_not_found_error // XXX deduplicate with other jumps in this routine
!:
	// Open channel 0 (reserved for file reading)
	lda #$00
	jsr iec_cmd_open
	bcc !+
	jmp lvs_device_not_found_error // XXX deduplicate with other jumps in this routine
!:
	// Send file name
	jsr lvs_send_file_name
	bcc !+
	jmp lvs_load_verify_error // XXX deduplicate with other jumps in this routine 
!:
	// Now command device to talk (p16)
	lda current_device_number
	jsr TALK
	bcc !+
	jmp lvs_load_verify_error // XXX deduplicate with other jumps in this routine 
!:
	lda #$60 // open channel / data (p3) , required according to p13
	sta TBTCNT
	jsr iec_tx_command
	bcc !+
	jmp lvs_load_verify_error // XXX deduplicate with other jumps in this routine 
!:
	// We are currently talker, so do the IEC turn around so that we
	// are the listener (p16)
	jsr iec_turnaround_to_listen
	bcc !+
	jmp lvs_load_verify_error // XXX deduplicate with other jumps in this routine 
!:
	// Get load address and store it if secondary address is zero
	jsr iec_rx_byte
	bcc !+
	jmp lvs_file_not_found_error // XXX deduplicate with other jumps in this routine
!:
	ldx current_secondary_address
	beq !+
	sta STAL+0
!:
	jsr iec_rx_byte
	bcc !+
	jmp lvs_file_not_found_error // XXX deduplicate with other jumps in this routine
!:
	ldx current_secondary_address
	beq !+
	sta STAL+1
!:
	// Display start address
	jsr lvs_display_loading_verifying

load_loop:
	// We are now ready to receive bytes
	jsr iec_rx_byte
	bcc !+
	jmp lvs_load_verify_error // XXX deduplicate with other jumps in this routine 
!:
	// Handle the byte (store in memory / verify)
	jsr lvs_handle_byte_load_verify
	bcc !+
	jmp lvs_load_verify_error // XXX deduplicate with other jumps in this routine 
!:	
	// Advance pointer to data
	jsr lvs_advance_pointer
	bcc !+
	jmp lvs_wrap_around_error
!:
	// Check for EOI - if so, this was the last byte
	lda IOSTATUS
	and #K_STS_EOI
	beq load_loop

	// Display end address
	jsr lvs_display_done

	// Close file on drive

	lda current_device_number
	jsr close_load

	// Return last address
	jmp lvs_return_last_address