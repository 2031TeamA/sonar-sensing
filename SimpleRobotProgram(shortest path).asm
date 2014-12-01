
; SimpleRobotProgram.asm
; Created by Kevin Johnson
; (no copyright applied; edit freely, no attribution necessary)
; This program does basic initialization of the DE2Bot
; and provides an example of some peripherals.
 
; Section labels are for clarity only.
 
 
 
ORG        &H000       ;Begin program at x000
;***************************************************************
;* Initialization
;***************************************************************

;set the starting point
	LOAD	Zero
	STORE	PointS

GetPoints:	;I want to write a program to display the hex value of switches on the LEDS
	
	IN		SWITCHES
	OUT		LEDS
	AND		MaskC1
	STORE	Point1
	IN		SWITCHES
	AND		MaskC2
	SHIFT	-5
	STORE	Point2
	SHIFT	8
	ADD		Point1
	OUT		SSEG2
	IN		SWITCHES
	AND		MaskC3
	SHIFT	-10
	STORE	Point3
	OUT		SSEG1
	LOAD	PointS
	OUT		LCD
	
	
					; Wait for user to press PB3
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  5           ; Both LEDG2 and LEDG3
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask2       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   GetPoints ; not ready (KEYs are active-low, hence JPOS)
	
;=================================================================================

	LOAD	PointS		;this will be the starting point
	STORE	TempPoint
	CALL	SetXY
	LOAD	TempX
	STORE	PointSX
	LOAD	TempY
	STORE	PointSY

FoundStart:		;
	LOAD	PointSX
	SHIFT	12
	STORE	Temp
	LOAD	PointSY
	SHIFT	8
	ADD		TEMP
	ADD		PointS
	OUT		LCD
	
	; Wait for user to press PB3
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  1           ; Both LEDG4 and LEDG5
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask0       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   FoundStart ; not ready (KEYs are active-low, hence JPOS)
	
;=================================================================================

	LOAD	Point1
	STORE	TempPoint
	CALL	SetXY
	LOAD	TempX
	STORE	Point1X
	LOAD	TempY
	STORE	Point1Y

Found1:		;
	LOAD	Point1X
	SHIFT	12
	STORE	Temp
	LOAD	Point1Y
	SHIFT	8
	ADD		TEMP
	ADD		Point1
	OUT		LCD
	
	; Wait for user to press PB3
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  3           ; Both LEDG4 and LEDG5
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask1       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   Found1 ; not ready (KEYs are active-low, hence JPOS)
	
;=================================================================================
	
	LOAD	Point2
	STORE	TempPoint
	CALL	SetXY
	LOAD	TempX
	STORE	Point2X
	LOAD	TempY
	STORE	Point2Y

Found2:	
	LOAD	Point2X
	SHIFT	12
	STORE	Temp
	LOAD	Point2Y
	SHIFT	8
	ADD		TEMP
	ADD		Point2
	OUT		LCD
	
	; Wait for user to press PB3
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  5           ; Both LEDG6 and LEDG7
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask2       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   Found2 ; not ready (KEYs are active-low, hence JPOS)
	
;=================================================================================
	
	LOAD	Point3
	STORE	TempPoint
	CALL	SetXY
	LOAD	TempX
	STORE	Point3X
	LOAD	TempY
	STORE	Point3Y
	
Found3:
	LOAD	Point3X
	SHIFT	12
	STORE	Temp
	LOAD	Point3Y
	SHIFT	8
	ADD		TEMP
	ADD		Point3
	OUT		LCD
	
	; Wait for user to press PB1
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  1           ; Both LEDG2 and LEDG3
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask0       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   Found3 ; not ready (KEYs are active-low, hence JPOS)

;=================================================================================

;This will calculate the distances from each of the 6 possible paths

;calc SPP1
	LOAD	PointSX
	STORE	X1
	STORE	XC
	LOAD	PointSY
	STORE	Y1
	STORE	YC
	LOAD	Point1X
	STORE	X2
	LOAD	Point1Y
	STORE	Y2
	LOAD	Y2
	SUB		Y1
	STORE	DeltaY

	CALL	CalcDist	

FoundSPP1:
	LOAD	Dist
	STORE	SPP1
	OUT		LCD

	; Wait for user to press PB2
	IN		TIMER       ; We'll blink the LEDs above PB3
	AND		Mask1
	SHIFT	3           ; Both LEDG6 and LEDG7
	STORE	Temp        ; (overkill, but looks nice)
	SHIFT	1
	OR		Temp
	OUT		XLEDS
	IN		XIO         ; XIO contains KEYs
	AND		Mask1       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS 	FoundSPP1 ; not ready (KEYs are active-low, hence JPOS)
	
;calc SPP2
	LOAD	PointSX
	STORE	X1
	STORE	XC
	LOAD	PointSY
	STORE	Y1
	STORE	YC
	LOAD	Point2X
	STORE	X2
	LOAD	Point2Y
	STORE	Y2
	LOAD	Y2
	SUB		Y1
	STORE	DeltaY

	CALL	CalcDist	

FoundSPP2:
	LOAD	Dist
	STORE	SPP2
	OUT		LCD

	; Wait for user to press PB3
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  5           ; Both LEDG6 and LEDG7
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask2       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   FoundSPP2 ; not ready (KEYs are active-low, hence JPOS)

;calc SPP3
	LOAD	PointSX
	STORE	X1
	STORE	XC
	LOAD	PointSY
	STORE	Y1
	STORE	YC
	LOAD	Point3X
	STORE	X2
	LOAD	Point3Y
	STORE	Y2
	LOAD	Y2
	SUB		Y1
	STORE	DeltaY

	CALL	CalcDist	

FoundSPP3:
	LOAD	Dist
	STORE	SPP3
	OUT		LCD

	; Wait for user to press PB1
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  1           ; Both LEDG2 and LEDG3
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask0       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   FoundSPP3 ; not ready (KEYs are active-low, hence JPOS)

;calc P1P2
	LOAD	Point1X
	STORE	X1
	STORE	XC
	LOAD	Point1Y
	STORE	Y1
	STORE	YC
	LOAD	Point2X
	STORE	X2
	LOAD	Point2Y
	STORE	Y2
	LOAD	Y2
	SUB		Y1
	STORE	DeltaY

	CALL	CalcDist	

FoundP1P2:
	LOAD	Dist
	STORE	P1P2
	OUT		LCD

	; Wait for user to press PB2
	IN		TIMER       ; We'll blink the LEDs above PB3
	AND		Mask1
	SHIFT	3           ; Both LEDG6 and LEDG7
	STORE	Temp        ; (overkill, but looks nice)
	SHIFT	1
	OR		Temp
	OUT		XLEDS
	IN		XIO         ; XIO contains KEYs
	AND		Mask1       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS 	FoundP1P2 ; not ready (KEYs are active-low, hence JPOS)
	
;calc P1P3
	LOAD	Point1X
	STORE	X1
	STORE	XC
	LOAD	Point1Y
	STORE	Y1
	STORE	YC
	LOAD	Point3X
	STORE	X2
	LOAD	Point3Y
	STORE	Y2
	LOAD	Y2
	SUB		Y1
	STORE	DeltaY

	CALL	CalcDist	

FoundP1P3:
	LOAD	Dist
	STORE	P1P3
	OUT		LCD

	; Wait for user to press PB3
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  5           ; Both LEDG6 and LEDG7
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask2       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   FoundP1P3 ; not ready (KEYs are active-low, hence JPOS)

;calc P2P3
	LOAD	Point2X
	STORE	X1
	STORE	XC
	LOAD	Point2Y
	STORE	Y1
	STORE	YC
	LOAD	Point3X
	STORE	X2
	LOAD	Point3Y
	STORE	Y2
	SUB		Y1
	STORE	DeltaY

	CALL	CalcDist	

FoundP2P3:
	LOAD	Dist
	STORE	P2P3
	OUT		LCD

	; Wait for user to press PB1
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  1           ; Both LEDG2 and LEDG3
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask0       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   FoundP2P3 ; not ready (KEYs are active-low, hence JPOS)

;=====================================================================================

; set the distances for the unique 6 paths
SetDist:
	LOAD	SPP1
	ADD		P1P2
	ADD		P2P3
	STORE	SPP1P2P3
	
	LOAD	SPP1
	ADD		P1P3
	ADD		P2P3	;P3P2
	STORE	SPP1P3P2
	
	LOAD	SPP2
	ADD		P1P2	;P2P1
	ADD		P1P3
	STORE	SPP2P1P3
	
	LOAD	SPP2
	ADD		P2P3
	ADD		P1P3	;P3P1
	STORE	SPP2P3P1
	
	LOAD	SPP3
	ADD		P1P3	;P3P1
	ADD		P1P2
	STORE	SPP3P1P2
	
	LOAD	SPP3
	ADD		P2P3	;P3P2
	ADD		P1P2	;P2P1
	STORE	SPP3P2P1
	
SetPaths:
	LOAD	SPP3P2P1
	OUT		LCD
		
	; Wait for user to press PB2
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  3           ; Both LEDG2 and LEDG3
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask1       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   SetPaths ; not ready (KEYs are active-low, hence JPOS)
	
;====================================================================================
	
;This calculates the shortests path given 6 paths
	
CheckP1:	;This checks to see if Path 1 is the shortest path
	LOAD	SPP1P2P3
	SUB		SPP1P3P2
	JPOS	CheckP2
	
	LOAD	SPP1P2P3
	SUB		SPP2P1P3
	JPOS	CheckP3
	
	LOAD	SPP1P2P3
	SUB		SPP2P3P1
	JPOS	CheckP4
	
	LOAD	SPP1P2P3
	SUB		SPP3P1P2
	JPOS	CheckP5
	
	LOAD	SPP1P2P3
	SUB		SPP3P2P1
	JPOS	CheckP6
	
	LOAD	One
	STORE	ShortPath
	JPOS	FoundShort
	
CheckP2:
	LOAD	SPP1P3P2
	SUB		SPP2P1P3
	JPOS	CheckP3
	
	LOAD	SPP1P3P2
	SUB		SPP2P3P1
	JPOS	CheckP4
	
	LOAD	SPP1P3P2
	SUB		SPP3P1P2
	JPOS	CheckP5
	
	LOAD	SPP1P3P2
	SUB		SPP3P2P1
	JPOS	CheckP6
	
	LOAD	Two
	STORE	ShortPath
	JPOS	FoundShort

CheckP3:
	LOAD	SPP2P1P3
	SUB		SPP2P3P1
	JPOS	CheckP4
	
	LOAD	SPP2P1P3
	SUB		SPP3P1P2
	JPOS	CheckP5
	
	LOAD	SPP2P1P3
	SUB		SPP3P2P1
	JPOS	CheckP6
	
	LOAD	Three
	STORE	ShortPath
	JPOS	FoundShort

CheckP4:
	LOAD	SPP2P3P1
	SUB		SPP3P1P2
	JPOS	CheckP5
	
	LOAD	SPP2P3P1
	SUB		SPP3P2P1
	JPOS	CheckP6
	
	LOAD	Four
	STORE	ShortPath
	JPOS	FoundShort

CheckP5:
	LOAD	SPP3P1P2
	SUB		SPP3P2P1
	JPOS	CheckP6
	
	LOAD	Five
	STORE	ShortPath
	JPOS	FoundShort

CheckP6:
	LOAD	Six
	STORE	ShortPath
	JPOS	FoundShort
	
	
 FoundShort:
 	LOAD	ShortPath
 	OUT		LCD
 	
 	
	; Wait for user to press PB3
	IN		TIMER       ; We'll blink the LEDs above PB3
	AND		Mask1
	SHIFT	5           ; Both LEDG6 and LEDG7
	STORE	Temp        ; (overkill, but looks nice)
	SHIFT	1
	OR		Temp
	OUT		XLEDS
	IN		XIO         ; XIO contains KEYs
	AND		Mask2       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS 	FoundShort ; not ready (KEYs are active-low, hence JPOS)

	
;=================================================================================

SetPoints: 
	LOAD	ShortPath
	STORE	Temp
	
	;ShortPath = 1
	LOAD	Point1
	STORE	P1
	LOAD	Point2
	STORE	P2
	LOAD	Point3
	STORE	P3
	LOAD	Temp
	SUB		One
	STORE	Temp
	JZERO	PointsSet
	
	;ShortPath = 2
	LOAD	Point1
	STORE	P1
	LOAD	Point3
	STORE	P2
	LOAD	Point2
	STORE	P3
	LOAD	Temp
	SUB		One
	STORE	Temp
	JZERO	PointsSet
	
	;ShortPath = 3
	LOAD	Point2
	STORE	P1
	LOAD	Point1
	STORE	P2
	LOAD	Point3
	STORE	P3
	LOAD	Temp
	SUB		One
	STORE	Temp
	JZERO	PointsSet
	
	;ShortPath = 4
	LOAD	Point2
	STORE	P1
	LOAD	Point3
	STORE	P2
	LOAD	Point1
	STORE	P3
	LOAD	Temp
	SUB		One
	STORE	Temp
	JZERO	PointsSet
	
	;ShortPath = 5
	LOAD	Point3
	STORE	P1
	LOAD	Point1
	STORE	P2
	LOAD	Point2
	STORE	P3
	LOAD	Temp
	SUB		One
	STORE	Temp
	JZERO	PointsSet
	
	;ShortPath = 6
	LOAD	Point3
	STORE	P1
	LOAD	Point2
	STORE	P2
	LOAD	Point1
	STORE	P3
	LOAD	Temp
	SUB		One
	STORE	Temp
	JZERO	PointsSet
	

PointsSet:
	LOAD	Zero
	STORE	Temp
	LOAD	P3
	SHIFT	8
	STORE	Temp
	LOAD	P2
	ADD		Temp
	OUT		SSEG1
	
	LOAD	Zero
	STORE	Temp
	LOAD	P1
	SHIFT	8
	STORE	Temp
	LOAD	PointS
	ADD		Temp
	OUT		SSEG2

		; Wait for user to press PB1
	IN		TIMER       ; We'll blink the LEDs above PB3
	AND		Mask1
	SHIFT	1           ; Both LEDG6 and LEDG7
	STORE	Temp        ; (overkill, but looks nice)
	SHIFT	1
	OR		Temp
	OUT		XLEDS
	IN		XIO         ; XIO contains KEYs
	AND		Mask0       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS 	PointsSet ; not ready (KEYs are active-low, hence JPOS)
;=================================================================================
;	At this point, the shortest path has been found and displayed on the SSEGs 
;	from (right to left) showing the starting point > P1 > P2 > P3
;=================================================================================
Init:
	; Always a good idea to make sure the robot
	; stops in the event of a reset.
	LOAD   Zero
	OUT    LVELCMD     ; Stop motors
	OUT    RVELCMD
	OUT    SONAREN     ; Disable sonar (optional)
	
	CALL   SetupI2C    ; Configure the I2C to read the battery voltage
	CALL   BattCheck   ; Get battery voltage (and end if too low).
	OUT    LCD         ; Display batt voltage on LCD

WaitForSafety:
	; Wait for safety switch to be toggled
	IN     XIO         ; XIO contains SAFETY signal
	AND    Mask4       ; SAFETY signal is bit 4
	JPOS   WaitForUser ; If ready, jump to wait for PB3
	IN     TIMER       ; We'll use the timer value to
	AND    Mask1       ;  blink LED17 as a reminder to toggle SW17
	SHIFT  8           ; Shift over to LED17
	OUT    XLEDS       ; LED17 blinks at 2.5Hz (10Hz/4)
	JUMP   WaitForSafety
	
WaitForUser:
	; Wait for user to press PB3
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  5           ; Both LEDG6 and LEDG7
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask2       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   WaitForUser ; not ready (KEYs are active-low, hence JPOS)
	LOAD   Zero
	OUT    XLEDS       ; clear LEDs once ready to continue

;***************************************************************
;* Main code
;***************************************************************
Main: ; "Real" program starts here.
	OUT    RESETPOS    ; reset odometry in case wheels moved after programming	

	
Go:	LOAD	FSlow
	OUT		LVELCMD
	;LOAD	RFast
	OUT		RVELCMD
	JUMP	Go

; The following code ("Center" through "DeadZone") is purely for example.
; It attempts to gently keep the robot facing 0 degrees, showing how the
; odometer and motor controllers work.
Center:
	; The 0/359 jump in THETA can be difficult to deal with.
	; This code shows one way to handle it: by moving the
	; discontinuity away from the current heading.
	IN     THETA       ; get the current angular position
	ADDI   -180        ; test whether facing 0-179 or 180-359
	JPOS   NegAngle    ; robot facing 180-360; handle that separately
PosAngle:
	ADDI   180         ; undo previous subtraction
	JUMP   CheckAngle  ; THETA positive, so carry on
NegAngle:
	ADDI   -180        ; finish conversion to negative angle:
	                   ;  angles 180 to 359 become -180 to -1
	
CheckAngle:
	; AC now contains the +/- angular error from 0, meaning that
	;  the discontinuity is at 179/-180 instead of 0/359
	OUT    LCD         ; Good data to display for debugging
	; As an example of math, multiply the error by 5 :
	; (AC + AC<<2) = AC*5
	STORE  Temp
	SHIFT  2          ; divide by two
	ADD    Temp        ; add original value
	
	; Cap velcmd at +/-100 (a slow speed)
	JPOS   CapPos      ; handle +/- separately
CapNeg:
	ADD    DeadZone    ; if close to 0, don't do anything
	JPOS   NoTurn      ; (don't do anything)
	SUB    DeadZone    ; restore original value
	ADDI   100         ; check for <-100
	JPOS   NegOK       ; it was not <-100, so carry on
	LOAD   Zero        ; it was <-100, so clear excess
NegOK:
	ADDI   -100        ; undo the previous addition
	JUMP   SendToMotors
CapPos:
	SUB    DeadZone    ; if close to 0, don't do anything
	JNEG   NoTurn
	ADD    DeadZone    ; restore original value
	ADDI   -100
	JNEG   PosOK       ; it was not >100, so carry on
	LOAD   Zero        ; it was >100, so clear excess
PosOK:
	ADDI   100         ; undo the previous subtraction
	JUMP   SendToMotors
NoTurn:
	LOAD   Zero
	JUMP   SendToMotors
	
	; The desired velocity (angular error * 1.5, capped at
	;  +/-100, and with a 2-degree dead zone) is now in AC
SendToMotors:
	; Since we want to spin in place, we need to send inverted
	;  velocities to the wheels.
	STORE  Temp        ; store calculated desired velocity
	; send the direct value to the left wheel
;	ADD    FMid        ; Could add an offset vel here to move forward
	OUT    LVELCMD
	OUT    SSEG1       ; for debugging purposes
	; send the negated number to the right wheel
	LOAD   Zero
	SUB    Temp        ; AC = 0 - AC
;	ADD    Fmid        ; Could add an offset vel here to move forward
	OUT    RVELCMD	
	OUT    SSEG2       ; debugging
	
	JUMP   Center      ; repeat forever
	
DeadZone:  DW 10       ; Actual deadzone will be /5 due to scaling above.
	                   ; Note that you can place data anywhere.
                       ; Just be careful that it doesn't get executed.
	
Die:
; Sometimes it's useful to permanently stop execution.
; This will also catch the execution if it accidentally
; falls through from above.
	LOAD   Zero         ; Stop everything.
	OUT    LVELCMD
	OUT    RVELCMD
	OUT    SONAREN
	LOAD   DEAD         ; An indication that we are dead
	OUT    SSEG2
Forever:
	JUMP   Forever      ; Do this forever.
DEAD: DW &HDEAD

	
;***************************************************************
;* Subroutines
;***************************************************************


SetXY: ;I want to set the X and Y coordinates respective to each point
	;assume point1 is 0
	LOAD	One
	STORE	TempX
	STORE	TempY
	;check if point1 is zero
	LOAD	TempPoint
	JZERO	Found
	;dec point1 bc it is not 0, and assume it is 1
	SUB		One
	STORE	Temp
	LOAD	Two
	STORE	TempX
	Load	One
	STORE	TempY
	;check if point1 is 1
	LOAD	Temp
	JZERO	Found
	;dec point1 bc its not 1, and assume it is 2
	SUB		One
	STORE 	TEMP
	LOAD	Three
	STORE	TempX
	Load	One
	STORE	TempY
	;check if point1 is 2
	LOAD	Temp
	JZERO	Found
	;dec point1 bc it is not 0, and assume it is 3
	SUB		One
	STORE	Temp
	LOAD	Four
	STORE	TempX
	Load	One
	STORE	TempY
	;check if point1 is 3
	LOAD	Temp
	JZERO	Found
	;dec point1 bc its not 1, and assume it is 4
	SUB		One
	STORE 	TEMP
	LOAD	One
	STORE	TempX
	Load	Two
	STORE	TempY
	;check if point1 is 4
	LOAD	Temp
	JZERO	Found
	;dec point1 bc it is not 0, and assume it is 5
	SUB		One
	STORE	Temp
	LOAD	Two
	STORE	TempX
	Load	Two
	STORE	TempY
	;check if point1 is 5
	LOAD	Temp
	JZERO	Found
	;dec point1 bc its not 1, and assume it is 6
	SUB		One
	STORE 	TEMP
	LOAD	Three
	STORE	TempX
	Load	Two
	STORE	TempY
	;check if point1 is 6
	LOAD	Temp
	JZERO	Found
	;dec point1 bc it is not 0, and assume it is 7
	SUB		One
	STORE	Temp
	LOAD	Four
	STORE	TempX
	Load	Two
	STORE	TempY
	;check if point1 is 7
	LOAD	Temp
	JZERO	Found
	;dec point1 bc its not 1, and assume it is 8
	SUB		One
	STORE 	TEMP
	LOAD	One
	STORE	TempX
	Load	Three
	STORE	TempY
	;check if point1 is 8
	LOAD	Temp
	JZERO	Found
	;dec point1 bc it is not 0, and assume it is 9
	SUB		One
	STORE	Temp
	LOAD	Two
	STORE	TempX
	Load	Three
	STORE	TempY
	;check if point1 is 9
	LOAD	Temp
	JZERO	Found
	;dec point1 bc its not 1, and assume it is 10
	SUB		One
	STORE 	TEMP
	LOAD	Three
	STORE	TempX
	Load	Three
	STORE	TempY
	;check if point1 is 10
	LOAD	Temp
	JZERO	Found
	;dec point1 bc it is not 0, and assume it is 11
	SUB		One
	STORE	Temp
	LOAD	Four
	STORE	TempX
	Load	Three
	STORE	TempY
	;check if point1 is 11
	LOAD	Temp
	JZERO	Found
	;dec point1 bc its not 1, and assume it is 12
	SUB		One
	STORE 	TEMP
	LOAD	Five
	STORE	TempX
	Load	Three
	STORE	TempY
	;check if point1 is 12
	LOAD	Temp
	JZERO	Found
	;dec point1 bc it is not 0, and assume it is 13
	SUB		One
	STORE	Temp
	LOAD	One
	STORE	TempX
	Load	Four
	STORE	TempY
	;check if point1 is 13
	LOAD	Temp
	JZERO	Found
	;dec point1 bc its not 1, and assume it is 14
	SUB		One
	STORE 	TEMP
	LOAD	Two
	STORE	TempX
	Load	Four
	STORE	TempY
	;check if point1 is 14
	LOAD	Temp
	JZERO	Found
	;dec point1 bc it is not 0, and assume it is 15
	SUB		One
	STORE	Temp
	LOAD	Three
	STORE	TempX
	Load	Four
	STORE	TempY
	;check if point1 is 15
	LOAD	Temp
	JZERO	Found
	;dec point1 bc its not 1, and assume it is 16
	SUB		One
	STORE 	TEMP
	LOAD	Four
	STORE	TempX
	Load	Four
	STORE	TempY
	;check if point1 is 16
	LOAD	Temp
	JZERO	Found
	;dec point1 bc it is not 0, and assume it is 17
	SUB		One
	STORE	Temp
	LOAD	Five
	STORE	TempX
	Load	Four
	STORE	TempY
	;check if point1 is 17
	LOAD	Temp
	JZERO	Found
	;dec point1 bc its not 1, and assume it is 18
	SUB		One
	STORE 	TEMP
	LOAD	Six
	STORE	TempX
	Load	Four
	STORE	TempY
	;check if point1 is 18
	LOAD	Temp
	
Found:
	RETURN
	
	
;===========================================================================================

CalcDist:
	LOAD	Zero
	STORE	Dist
	
;check to see if you need to avoid any walls	
	LOAD	X1			;check if x < 3
	SUB		Three
	JNEG	MoveVert 	
	
	LOAD	DeltaY		;check if DeltaY > 1
	SUB		One
	JPOS	AvoidWall1	
	
	LOAD	DeltaY		;check if DeltaY < -1
	SUB		NegOne
	JNEG	AvoidWall1
	
	LOAD	DeltaY		;check if DeltaY = 1
	SUB		One
	JPOS	MoveVert
	JNEG	MoveVert
	LOAD	Y1
	SUB		Two
	JZERO	AvoidWall1
	
	LOAD	DeltaY		;check if DeltaY = -1
	SUB		NegOne
	JPOS	MoveVert
	JNeg	MoveVert
	LOAD	Y1
	SUB		Three
	JZERO	AvoidWall1
	
	Load	X1			;check if need to avoid topright wall
	SUB		Six
	JZERO	AvoidWall2

	
AvoidWall1:
	LOAD	X1
	SUB		Two
	STORE	Temp
	LOAD	Dist
	ADD		Temp
	STORE	Dist
	LOAD	Two
	STORE	XC
	JUMP	MoveVert
	
	LOAD	Seven
	OUT		SSEG2
	
AvoidWall2:
	LOAD	X1
	SUB		Five
	STORE	Temp
	LOAD	Dist
	ADD		Temp
	STORE	Dist
	LOAD	Five
	STORE	XC
	JUMP	MoveVert
	
MoveVert:
	LOAD	DeltaY
	JNEG	MoveVertNeg
	LOAD	Dist
	ADD		DeltaY
	STORE	Dist
	LOAD	Y2
	STORE	YC
	JUMP	MoveHor
	
MoveVertNeg:
	LOAD	Dist
	SUB		DeltaY
	STORE	Dist		;shouldn't you add, not store?
	LOAD	Y2
	STORE	YC
	JUMP	MoveHor

MoveHor:
	LOAD	X2
	SUB		XC
	STORE	DeltaX
	LOAD	DeltaX
	JNEG	MoveHorNeg
	LOAD	Dist
	ADD		DeltaX
	STORE	Dist
	LOAD	X2
	STORE	XC
	JUMP	FoundDist
	
MoveHorNeg:
	LOAD	Dist
	SUB		DeltaX
	STORE	Dist
	LOAD	X2
	STORE	XC
	JUMP	FoundDist
	
FoundDist:
	RETURN

;===================================================================================

; Subroutine to wait (block) for 1 second
Wait1:
	OUT    TIMER
Wloop:
	IN     TIMER
	OUT    XLEDS       ; User-feedback that a pause is occurring.
	ADDI   -10         ; 1 second in 10Hz.
	JNEG   Wloop
	RETURN

; Subroutine to wait the number of counts currently in AC
WaitAC:
	STORE  WaitTime
	OUT    Timer
WACLoop:
	IN     Timer
	OUT    XLEDS       ; User-feedback that a pause is occurring.
	SUB    WaitTime
	JNEG   WACLoop
	RETURN
	WaitTime: DW 0     ; "local" variable.
	
; This subroutine will get the battery voltage,
; and stop program execution if it is too low.
; SetupI2C must be executed prior to this.
BattCheck:
	CALL   GetBattLvl
	JZERO  BattCheck   ; A/D hasn't had time to initialize
	SUB    MinBatt
	JNEG   DeadBatt
	ADD    MinBatt     ; get original value back
	RETURN
; If the battery is too low, we want to make
; sure that the user realizes it...
DeadBatt:
	LOAD   Four
	OUT    BEEP        ; start beep sound
	CALL   GetBattLvl  ; get the battery level
	OUT    SSEG1       ; display it everywhere
	OUT    SSEG2
	OUT    LCD
	LOAD   Zero
	ADDI   -1          ; 0xFFFF
	OUT    LEDS        ; all LEDs on
	OUT    XLEDS
	CALL   Wait1       ; 1 second
	Load   Zero
	OUT    BEEP        ; stop beeping
	LOAD   Zero
	OUT    LEDS        ; LEDs off
	OUT    XLEDS
	CALL   Wait1       ; 1 second
	JUMP   DeadBatt    ; repeat forever
	
; Subroutine to read the A/D (battery voltage)
; Assumes that SetupI2C has been run
GetBattLvl:
	LOAD   I2CRCmd     ; 0x0190 (write 0B, read 1B, addr 0x90)
	OUT    I2C_CMD     ; to I2C_CMD
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	IN     I2C_DATA    ; get the returned data
	RETURN

; Subroutine to configure the I2C for reading batt voltage
; Only needs to be done once after each reset.
SetupI2C:
	CALL   BlockI2C    ; wait for idle
	LOAD   I2CWCmd     ; 0x1190 (write 1B, read 1B, addr 0x90)
	OUT    I2C_CMD     ; to I2C_CMD register
	LOAD   Zero        ; 0x0000 (A/D port 0, no increment)
	OUT    I2C_DATA    ; to I2C_DATA register
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	RETURN
	
; Subroutine to block until I2C device is idle
BlockI2C:
	LOAD   Zero
	STORE  Temp        ; Used to check for timeout
BI2CL:
	LOAD   Temp
	ADDI   1           ; this will result in ~0.1s timeout
	STORE  Temp
	JZERO  I2CError    ; Timeout occurred; error
	IN     I2C_RDY     ; Read busy signal
	JPOS   BI2CL       ; If not 0, try again
	RETURN             ; Else return
I2CError:
	LOAD   Zero
	ADDI   &H12C       ; "I2C"
	OUT    SSEG1
	OUT    SSEG2       ; display error message
	JUMP   I2CError

; Subroutine to send AC value through the UART,
; formatted for default base station code:
; [ AC(15..8) | AC(7..0) | \lf ]
; Note that special characters such as \lf are
; escaped with the value 0x1B, thus the literal
; value 0x1B must be sent as 0x1B1B, should it occur.
UARTSend:
	STORE  UARTTemp
	SHIFT  -8
	ADDI   -27   ; escape character
	JZERO  UEsc1
	ADDI   27
	OUT    UART_DAT
	JUMP   USend2
UEsc1:
	ADDI   27
	OUT    UART_DAT
	OUT    UART_DAT
USend2:
	LOAD   UARTTemp
	AND    LowByte
	ADDI   -27   ; escape character
	JZERO  UEsc2
	ADDI   27
	OUT    UART_DAT
	RETURN
UEsc2:
	ADDI   27
	OUT    UART_DAT
	OUT    UART_DAT
	RETURN
	UARTTemp: DW 0

UARTNL:
	LOAD   NL
	OUT    UART_DAT
	SHIFT  -8
	OUT    UART_DAT
	RETURN
	NL: DW &H0A1B

;***************************************************************
;* Variables
;***************************************************************
Temp:     DW 0 ; "Temp" is not a great name, but can be useful
TempPoint:	DW 0
TempX:		DW 0
TempY:		DW 0

PointS:	  DW &B0
PointSX:  DW 0
PointSY:  DW 0
PointC:	  DW &B0
PointCX:  DW 0
PointCY:  DW 0
Point1:	  DW &B0
Point1X:  DW 0
Point1Y:  DW 0
Point2:	  DW &B0
Point2X:  DW 0
Point2Y:  DW 0
Point3:	  DW &B0
Point3X:  DW 0
Point3Y:  DW 0

Dist:		DW 0
XC:			DW 0
YC:			DW 0
X1:			DW 0
Y1:			DW 0
X2:			DW 0
Y2:			DW 0
DeltaX:		DW 0
DeltaY:		DW 0

SPP1:		DW 0
SPP2:		DW 0
SPP3:		DW 0
P1P2:		DW 0
P1P3:		DW 0
P2P3:		DW 0

SPP1P2P3:	DW 0
SPP1P3P2:	DW 0
SPP2P1P3:	DW 0
SPP2P3P1:	DW 0
SPP3P1P2:	DW 0
SPP3P2P1:	DW 0

ShortPath:	DW 0
P1:			DW 0
P2:			DW 0
P3:			DW 0

;***************************************************************
;* Constants
;* (though there is nothing stopping you from writing to these)
;***************************************************************
NegOne:   DW -1
Zero:     DW 0
One:      DW 1
Two:      DW 2
Three:    DW 3
Four:     DW 4
Five:     DW 5
Six:      DW 6
Seven:    DW 7
Eight:    DW 8
Nine:     DW 9
Ten:      DW 10

; Some bit masks.
; Masks of multiple bits can be constructed by ORing these
; 1-bit masks together.
MaskTemp: DW &B0
MaskC1:   DW &B11111
MaskC2:   DW &B1111100000
MaskC12:  DW &B1111111111
MaskC3:   DW &B111110000000000
Mask0:    DW &B00000001
Mask1:    DW &B00000010
Mask2:    DW &B00000100
Mask3:    DW &B00001000
Mask4:    DW &B00010000
Mask5:    DW &B00100000
Mask6:    DW &B01000000
Mask7:    DW &B10000000
LowByte:  DW &HFF      ; binary 00000000 1111111
LowNibl:  DW &HF       ; 0000 0000 0000 1111

; some useful movement values
OneMeter: DW 961       ; ~1m in 1.05mm units
HalfMeter: DW 481      ; ~0.5m in 1.05mm units
TwoFeet:  DW 586       ; ~2ft in 1.05mm units
Deg90:    DW 90        ; 90 degrees in odometry units
Deg180:   DW 180       ; 180
Deg270:   DW 270       ; 270
Deg360:   DW 360       ; can never actually happen; for math only
FSlow:    DW 100       ; 100 is about the lowest velocity value that will move
RSlow:    DW -100
FMid:     DW 350       ; 350 is a medium speed
RMid:     DW -350
FFast:    DW 500       ; 500 is almost max speed (511 is max)
RFast:    DW -500

MinBatt:  DW 130       ; 13.0V - minimum safe battery voltage
I2CWCmd:  DW &H1190    ; write one i2c byte, read one byte, addr 0x90
I2CRCmd:  DW &H0190    ; write nothing, read one byte, addr 0x90

;***************************************************************
;* IO address space map
;***************************************************************
SWITCHES: EQU &H00  ; slide switches
LEDS:     EQU &H01  ; red LEDs
TIMER:    EQU &H02  ; timer, usually running at 10 Hz
XIO:      EQU &H03  ; pushbuttons and some misc. inputs
SSEG1:    EQU &H04  ; seven-segment display (4-digits only)
SSEG2:    EQU &H05  ; seven-segment display (4-digits only)
LCD:      EQU &H06  ; primitive 4-digit LCD display
XLEDS:    EQU &H07  ; Green LEDs (and Red LED16+17)
BEEP:     EQU &H0A  ; Control the beep
CTIMER:   EQU &H0C  ; Configurable timer for interrupts
LPOS:     EQU &H80  ; left wheel encoder position (read only)
LVEL:     EQU &H82  ; current left wheel velocity (read only)
LVELCMD:  EQU &H83  ; left wheel velocity command (write only)
RPOS:     EQU &H88  ; same values for right wheel...
RVEL:     EQU &H8A  ; ...
RVELCMD:  EQU &H8B  ; ...
I2C_CMD:  EQU &H90  ; I2C module's CMD register,
I2C_DATA: EQU &H91  ; ... DATA register,
I2C_RDY:  EQU &H92  ; ... and BUSY register
UART_DAT: EQU &H98  ; UART data
UART_RDY: EQU &H98  ; UART status
SONAR:    EQU &HA0  ; base address for more than 16 registers....
DIST0:    EQU &HA8  ; the eight sonar distance readings
DIST1:    EQU &HA9  ; ...
DIST2:    EQU &HAA  ; ...
DIST3:    EQU &HAB  ; ...
DIST4:    EQU &HAC  ; ...
DIST5:    EQU &HAD  ; ...
DIST6:    EQU &HAE  ; ...
DIST7:    EQU &HAF  ; ...
SONALARM: EQU &HB0  ; Write alarm distance; read alarm register
SONARINT: EQU &HB1  ; Write mask for sonar interrupts
SONAREN:  EQU &HB2  ; register to control which sonars are enabled
XPOS:     EQU &HC0  ; Current X-position (read only)
YPOS:     EQU &HC1  ; Y-position
THETA:    EQU &HC2  ; Current rotational position of robot (0-359)
RESETPOS: EQU &HC3  ; write anything here to reset odometry to 0
