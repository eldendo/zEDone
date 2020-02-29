;
;**************************************************************
;*
;*       e d B I O S 
;*       for zED80 emulator
;*	 	 skeleton bios transformed by ir. Marc Dendooven (2012)
;*
;**************************************************************
;
;WARNING this skeleton bios is for 2.0 !!!!
;	skeletal cbios for first level of CP/M 2.0 alteration
;
msize	equ	62		;cp/m version memory size in kilobytes
;
;	"bias" is address offset from 3400h for memory systems
;	than 16k (referred to as"b" throughout the text)
;
bias	equ	(msize-20)*1024
ccp		equ	3400h+bias	;base of ccp
bdos	equ	ccp+806h	;base of bdos
bios	equ	ccp+1600h	;base of bios
cdisk	equ	0004h		;current disk number 0=a,... l5=p
iobyte	equ	0003h		;intel i/o byte
;
	org	bios		;origin of this program
nsects	equ	($-ccp)/128	;warm start sector count
;
;	jump vector for individual subroutines
;
		jp	boot	;cold start
wboote:	jp	wboot	;warm start
		jp	const	;console status
		jp	conin	;console character in
		jp	conout	;console character out
		jp	list	;list character out
		jp	punch	;punch character out
		jp	reader	;reader character out
		jp	home	;move head to home position
		jp	seldsk	;select disk
		jp	settrk	;set track number
		jp	setsec	;set sector number
		jp	setdma	;set dma address
		jp	read	;read disk
		jp	write	;write disk
		jp	listst	;return list status 
		jp	sectran	;sector translate
;
;	fixed data tables for four-drive standard
;	ibm-compatible 8" disks
;
;	disk Parameter header for disk 00
dpbase:	dw	trans, 0000h
	dw	0000h, 0000h
	dw	dirbf, dpblk
	dw	chk00, all00
;	disk parameter header for disk 01
	dw	trans, 0000h
	dw	0000h, 0000h
	dw	dirbf, dpblk
	dw	chk01, all01
;	disk parameter header for disk 02
	dw	trans, 0000h
	dw	0000h, 0000h
	dw	dirbf, dpblk
	dw	chk02, all02
;	disk parameter header for disk 03
	dw	trans, 0000h
	dw	0000h, 0000h
	dw	dirbf, dpblk
	dw	chk03, all03
;
;	sector translate vector
trans:	db	 1,  7, 13, 19	;sectors  1,  2,  3,  4
	db	25,  5, 11, 17	;sectors  5,  6,  7,  6
	db	23,  3,  9, 15	;sectors  9, 10, 11, 12
	db	21,  2,  8, 14	;sectors 13, 14, 15, 16
	db	20, 26,  6, 12	;sectors 17, 18, 19, 20
	db	18, 24,  4, 10	;sectors 21, 22, 23, 24
	db	16, 22		;sectors 25, 26
;
dpblk:	;disk parameter block, common to all disks
	dw	26		;sectors per track
	db	3		;block shift factor
	db	7		;block mask
	db	0		;null mask
	dw	242		;disk size-1
	dw	63		;directory max
	db	192		;alloc 0
	db	0		;alloc 1
	dw	16		;check size
	dw	2		;track offset
;
;	end of fixed tables
;
;	individual subroutines to perform each function

boot:	;entry point after cold start loader.
		;the cold start loader should load CP/M including edBIOS
		;at this moment done by the emulator
		;simplest case is to just perform parameter initialization
		;startup message should come here
		XOR	A			;zero in the accum
		OUT (0),A		;debug message '0'
		LD (iobyte),A	;clear the iobyte
		LD (cdisk),A	;select disk zero
		jp	gocpm		;initialize and go to cp/m
;
wboot:	;Warm Start. Control is transferred here after branch to $0000 or processor reset
		;LD A,'1'
		;OUT (0),A; debug message: '1'
		;load CP/M excluding edBIOS from first 2 tracks of drive A
		DB $ED, $FE ; Call PatchZ80 routine in emulator.			
					; This reloades CP/M without the bios
					; Schould later be replaced with code like the following
			
;wboot:	;simplest case is to read the disk until all sectors loaded
	;lxi	sp, 80h		;use space below buffer for stack
	;mvi	c, 0		;select disk 0
	;call	seldsk
	;call	home		;go to track 00
;;
	;mvi	b, nsects	;b counts * of sectors to load
	;mvi	c, 0		;c has the current track number
	;mvi	d, 2		;d has the next sector to read
;;	note that we begin by reading track 0, sector 2 since sector 1
;;	contains the cold start loader, which is skipped in a warm start
	;lxi	h, ccp		;base of cp/m (initial load point)
;load1:	;load	one more sector
	;push	b		;save sector count, current track
	;push	d		;save next sector to read
	;push	h		;save dma address
	;mov	c, d		;get sector address to register C
	;call	setsec		;set sector address from register C
	;pop	b		;recall dma address to b, C
	;push	b		;replace on stack for later recall
	;call	setdma		;set dma address from b, C
;;
;;	drive set to 0, track set, sector set, dma address set
	;call	read
	;cpi	00h		;any errors?
	;jnz	wboot		;retry the entire boot if an error occurs
;;
;;	no error, move to next sector
	;pop	h		;recall dma address
	;lxi	d, 128		;dma=dma+128
	;dad	d		;new dma address is in h, l
	;pop	d		;recall sector address
	;pop	b	;recall number of sectors remaining, and current trk
	;dcr	b		;sectors=sectors-1
	;jz	gocpm		;transfer to cp/m if all have been loaded
;;
;;	more	sectors remain to load, check for track change
	;inr	d
	;mov	a,d		;sector=27?, if so, change tracks
	;cpi	27
	;jc	load1		;carry generated if sector<27
;;
;;	end of	current track,	go to next track
	;mvi	d, 1		;begin with first sector of next track
	;inr	c		;track=track+1
;;
;;	save	register state, and change tracks
	;push	b
	;push	d
	;push	h
	;call	settrk		;track address set from register c
	;pop	h
	;pop	d
	;pop	b
	;jmp	load1		;for another sector
;;
;;	end of	load operation, set parameters and go to cp/m
gocpm:		; common exit with BOOT
			; set system parameters in zero page
			LD A,$C3
			LD ($00),A
			LD HL, wboote
			LD ($01),HL	;put JP WBOOT ($F203) at address $0000
			;
			LD ($05),A
			LD HL, bdos 
			LD ($06),HL	;put JMP BDOS ($E411) at address $0005
			;
			LD B,$80
			CALL setdma ;set default dma address
			;
			EI
			LD A,(cdisk)
			LD C,A
			;
			;LD A,'*' ;debug
			;OUT (0),A ;debug 
			;
			JP ccp ;transfer control to CCP 

;;
;;	simple i/o handlers (must be filled in by user)
;;	in each case, the entry point is provided, with space reserved
;;	to insert your own code
;;
const:		; return $FF in A if a character is ready to be read. $00 otherwise
			;LD A,'2'
			;OUT (0),A
			IN A,(1) 
			RET
			
conin:		;console character into register a
			;LD A,'3' ;debug
			;OUT (0),A ;debug
tmp:		IN A,(1) ;wait until a character is ready 
			CP 0
			JR Z,tmp; conin
			IN A,(0) ;read it in A
			AND $7F ;set MSB to 0 for 7 bit ascii
;			OUT (0),A ;debug
			RET

conout:		LD A,C ;send character in C to output
			OUT (0),A
			RET

list:		RET
listst:		RET
punch:		RET
reader:		RET

;;
;list:	;list character from register c
	;mov	a, c	  	;character to register a
	;ret		  	;null subroutine
;;
;listst:	;return list status (0 if not ready, 1 if ready)
	;xra	a	 	;0 is always ok to return
	;ret
;;
;punch:	;punch	character from	register C
	;mov	a, c		;character to register a
	;ret			;null subroutine
;;
;;
;reader:	;reader character into register a from reader device
	;mvi    a, 1ah		;enter end of file for now (replace later)
	;ani    7fh		;remember to strip parity bit
	;ret
;;
;;
;;	i/o drivers for the disk follow
;;	for now, we will simply store the parameters away for use
;;	in the read and write	subroutines
;;
	
home:		;move to the track 00	position of current drive
			;	translate this call into a settrk call with Parameter 00
			;LD A, '5' ;debug
			;OUT (0),A ;debug
			LD C,0 ; select track 0
			CALL settrk
			RET
;
seldsk:		;select disk given by register c
			LD HL, 0000h	;error return code
			LD A,C
			LD (diskno),A
			CP 4		;must be between 0 and 3
			RET NC			;no carry if 4, 5,...
			;	disk number is in the proper range
			OUT($10),A ; 
			;	compute proper disk Parameter header address
			LD A,(diskno)
			LD L,A		;l=disk number 0, 1, 2, 3
			LD H,0		;high order zero
			ADD HL,HL;*2
			ADD HL,HL;*4
			ADD HL,HL;*8
			ADD HL,HL;*16 (size of each header)
			LD DE, dpbase
			ADD HL,DE;hl=,dpbase (diskno*16)
			RET
;
settrk:		;set track given by register c
			LD A,C
			LD (track),A
			OUT($11),A
			RET
;
setsec:		;set sector given by register c
			LD A,C
			LD (sector),A
			OUT($12),A
			RET
;
sectran:
	;;translate the sector given by bc using the
	;;translate table given by de
			EX DE,HL ; HL points to table
			ADD HL,BC ; HL points to sector in table
			LD L,(HL) ; translated sector in L
			LD H,0	; translated sector in HL
			RET
;
setdma:		;set dma address given by registers b and c
			LD L,C
			LD H,B
			LD (dmaad),HL
			LD A,L
			OUT($13),A
			LD A,H
			OUT($14),A
			RET
;
read:		;LD A,'B' ;debug
			;OUT (0),A ;debug
			LD A,0
			OUT($15),A
			;error condition: always OK ???
			RET
;read:	;perform read operation (usually this is similar to write
;;	so we will allow space to set up read command, then use
;;	common code in write)
	;ds	10h		;set up read command
	;jmp	waitio		;to perform the actual i/o
;;
			
write:		;LD A,'C'; debug
			;OUT (0),A ;debug
			LD A,1
			OUT($15),A
			LD A,0 ; error condition : always ok ???
			RET
;write:	;perform a write operation
	;ds	10h		;set up write command
;;
;waitio:	;enter	here from read	and write to perform the actual i/o
;;	operation. return a 00h in register a if the operation completes
;;	properly, and 0lh if an error occurs during the read or write
;;
;;	in this case, we have saved the disk number in 'diskno' (0, 1)
;;			the track number in 'track' (0-76)
;;			the sector number in 'sector' (1-26)
;;			the dma address in 'dmaad' (0-65535)
	;ds	256		;space reserved for i/o drivers
	;mvi	a, 1		;error condition
	;ret			;replaced when filled-in
;
;	the remainder of the cbios is reserved uninitialized
;	data area, and does not need to be a Part of the
;	system	memory image (the space must be available,
;	however, between"begdat" and"enddat").
;
track:	ds	2		;two bytes for expansion
sector:	ds	2		;two bytes for expansion
dmaad:	ds	2		;direct memory address
diskno:	ds	1		;disk number 0-15
;
;	scratch ram area for bdos use
begdat	equ	$	 	;beginning of data area
dirbf:	ds	128	 	;scratch directory area
all00:	ds	31	 	;allocation vector 0
all01:	ds	31	 	;allocation vector 1
all02:	ds	31	 	;allocation vector 2
all03:	ds	31	 	;allocation vector 3
chk00:	ds	16		;check vector 0
chk01:	ds	16		;check vector 1
chk02:	ds	16	 	;check vector 2
chk03:	ds	16	 	;check vector 3
;
enddat	equ	$	 	;end of data area
datsiz	equ	$-begdat;	;size of data area
	end
