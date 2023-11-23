TITLE String Primitives and Macros     (Proj6_knickerp.asm)

; Author: Paige Knickerbocker
; Last Modified: 06-11-2023
; OSU email address: knickerp@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:        6         Due Date: 06-11-2023
; Description: This program gets 10 valid strings of numbers 
; from the user, and converts each one into an integer using string primitives, 
; storing the integers in an array. It will then convert each integer in the list
; back to a string of ASCII characters in order to print the list of values to
; to the console. Finally the program calculates the sum and truncated average
; of the values and converts these values to strings to be printed to the console.

INCLUDE Irvine32.inc

mGetString	MACRO	prompt, inString, byteCount
	push	EDX
	push	ECX
	push	EAX

	mov		EDX, prompt
	call	WriteString

	mov		EDX, inString
	mov		ECX, 41
	call	ReadString
	mov		byteCount, EAX

	pop		EAX
	pop		ECX
	pop		EDX
ENDM

mDisplayString	 MACRO	 outString
	push	EDX

	mov		EDX, outString
	call	WriteString

	pop		EDX
ENDM


ARRAYSIZE = 10

.data

intro1		BYTE	"String Primitives and Macros by Paige Knickerbocker",13,10,0
intro2		BYTE	"Please enter 10 signed integers that can fit in a 32-bit register.",13,10,
					"I will display the list of values along with the sum and average",13,10,
					"of the values.",13,10,0
prompt1		BYTE	"Please enter a signed integer: ",0
error1		BYTE	"Invalid characters or number out of range.",13,10,0
error2		BYTE	"No value entered.",13,10,0
prompt2		BYTE	"Please try again: ",0
title1		BYTE	"Here is the list of values entered: ",0
title2		BYTE	"The sum of these values: ",0
title3		BYTE	"The truncated average: ",0
space		BYTE	" ",0
goodbye		BYTE	"Thank you for using my program. Goodbye.",13,10,0
numList		SDWORD	ARRAYSIZE DUP(?)
inNum		BYTE	40 DUP(?)
outNum		BYTE	12 DUP(?)
sum			SDWORD	0
sumStr		BYTE	12 DUP(?)
average		SDWORD	?
avgStr		BYTE	12 DUP(?)
byteCt		DWORD	?
pass		DWORD	0


.code
main PROC

	; write introduction to console
	mDisplayString		OFFSET intro1
	call	CrLf
	mDisplayString		OFFSET intro2
	call	CrLf

	; initialize values for readLoop
	mov		ECX, ARRAYSIZE
	mov		EDI, OFFSET numList

_readLoop:
	push	OFFSET byteCt
	push	OFFSET inNum
	push	EDI
	push	OFFSET prompt1
	push	OFFSET error1
	push	OFFSET error2
	push	OFFSET prompt2
	call	ReadVal
	inc		pass
	add		EDI, 4
	loop	_readLoop

	; initialize for WriteVal
	call	CrLf
	mDisplayString		OFFSET title1
	call	CrLf
	mov		ECX, ARRAYSIZE
	mov		ESI, OFFSET numList

_writeLoop:
	push	OFFSET outNum
	push	OFFSET space
	push	[ESI]
	call	WriteVal

	add		ESI, 4
	loop	_writeLoop

	call	CrLf
	call	CrLf

	; calculate sum of values
	mov		ECX, ARRAYSIZE
	mov		ESI, OFFSET numList

_sumLoop:
	mov		EAX, [ESI]
	add		EAX, sum
	mov		sum, EAX
	add		ESI, 4		; next position in numList
	loop	_sumLoop

	; display sum
	mDisplayString		OFFSET title2
	push	OFFSET sumStr
	push	OFFSET space
	push	sum
	call	WriteVal
	call	CrLf
	call	CrLf

	; calculate truncated average
	mov		sum, EAX
	cdq		
	mov		EBX, arraysize
	idiv	EBX
	mov		average, EAX

	; display average
	mDisplayString		OFFSET title3
	push	OFFSET avgStr
	push	OFFSET space
	push	average
	call	WriteVal
	call	CrLf
	call	CrLf

	; write goodbye to console
	mDisplayString		OFFSET goodbye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ***************************************************************
; Procedure to read a string of numbers from the user, validate the 
; each character, convert the string to an integer, validate that the
; integer is in range. If invalid, prompts user to enter new string,
; if valid, saves integer to array. Calls mDisplayString and
; mGetString
; receives: addresses of prompt1, prompt2, error1, error2, numList,
; inNum, byteCount
; returns: stores valid integer in numList
; preconditions:  prompt1, prompt2, error1, error2, inNum are strings;
; numList is an array; byteCount exists
; registers changed: EAX, AL, ESI, EBX, ECX, EDI
; ***************************************************************

ReadVal PROC
	push	EBP
	mov		EBP, ESP
	pushad
	cld

	; get first number
	mGetString		[EBP + 20], [EBP + 28], [EBP + 32]

_convert:
	mov		ECX, [EBP + 32]		; string byte count
	mov		EAX, 0
	mov		EBX, 0				; initialize integer to 0
	mov		ESI, [EBP + 28]		; string value
	
	; check first byte
	lodsb				; first byte in AL
	cmp		AL, 45
	je		_negSign	; first byte is negative sign
	cmp		AL, 43
	je		_posSign	; first byte is positive sign
	cmp		AL, 0
	je		_noValue	; first byte is null
	jmp		_posConvert 

_posSign:
	dec		ECX			; first byte isn't digit

_posLoop:
	lodsb

_posConvert:
	; check if character is valid
	cmp		AL, 48
	jl		_notValid
	cmp		AL, 57
	jg		_notValid

	; multiply current integer by 10
	push	EAX				; current byte
	mov		EDX, 0
	mov		EAX, 10
	imul	EBX				; multiply integer by 10
	jo		_multNotValid	; does not fit in 32-bit register
	mov		EBX, EAX		; store current integer in EBX
	pop		EAX

	; convert character
	sub		AL, 48

	; add value to current integer
	add		EBX, EAX
	jo		_NotValid		; integer outside of range

	loop	_posLoop		; move to next byte of string
	
	jmp		_store

_negSign:
	dec		ECX

_negLoop:
	lodsb

	; check if character is valid
	cmp		AL, 48
	jl		_notValid
	cmp		AL, 57
	jg		_notValid

	; multiply current integer by 10
	push	EAX
	mov		EDX, 0
	mov		EAX, 10
	imul	EBX
	jo		_multNotValid
	mov		EBX, EAX
	pop		EAX

	; convert character
	sub		AL, 48

	; subtract value from current integer
	sub		EBX, EAX
	jo		_notValid

	loop	_negLoop
	jmp		_store

_noValue:
	mDisplayString		[EBP + 12]
	mGetString		[EBP + 8], [EBP + 28], [EBP +32]
	jmp		_convert

_multnotValid:
	pop		EAX

_notValid:
	mDisplayString		[EBP + 16]
	mGetString		[EBP + 8], [EBP + 28], [EBP +32]
	jmp		_convert

_store:
	mov		EDI, [EBP + 24]			; list of numbers
	mov		[EDI], EBX		; store integer at current pos in numList

	popad
	pop		EBP
	ret		32

ReadVal	ENDP

; ***************************************************************
; Procedure to take an integer and convert it to a string of ASCII
; characters, calls mDisplayString to display string to console
; receives: addresses of space, outNum; value
; returns: prints string of numbers to console
; preconditions:  outNum is empty string; value is integer, space is string
; registers changed: EAX, EDX, EBX, ECX, EDI
; ***************************************************************
WriteVal PROC
	local	quotient:DWORD, stringLength:DWORD
	pushad
	cld

	; initialize values
	mov		ECX, 0
	mov		EDI, [EBP + 16]		; outNum 
	push	EDI
	mov		EAX, [EBP + 8]		; integer at position
	mov		quotient, EAX
	mov		stringLength, 0
	mov		EBX, 10

	; check if value is zero
	cmp		EAX, 0
	je		_zero

	; check if value is negative
	cmp		EAX, 0
	jg		_divideLoop		; positive value
	imul	EAX, -1
	mov		quotient, EAX
	mov		EAX, 45			
	stosb					; first byte of string = "-"

_divideLoop:
	mov		EAX, quotient
	cdq
	idiv	EBX				; divide by 10
	push	EDX				; store remainder
	inc		ECX
	mov		quotient, EAX
	cmp		EAX, 0
	jne		_divideLoop		; not at lowest digit in integer

_convertLoop:
	pop		EAX
	add		EAX, 48			; convert remainder/digit to ascii
	stosb
	inc		stringLength
	loop	_convertLoop
	jmp		_display

_zero:
	mov		EBX, 48			
	mov		[EDI], EBX		; move 0 to outNum
	jmp		_display
	

_display:
	; display number as string
	mDisplayString		[EBP + 16]		; outNum
	mDisplayString		[EBP + 12]		; space

	; clear number string
	pop		EDI						; start of outNum
	mov		ECX, stringLength
	mov		EAX, 0
	rep		stosb					; make each byte in outNum 0

	popad
	ret		16

WriteVal ENDP

END main
