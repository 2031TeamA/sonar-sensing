; SimpleRobotProgram.asm
; Created by Kevin Johnson
; (no copyright applied; edit freely, no attribution necessary)
; This program does basic initialization of the DE2Bot
; and provides an example of some peripherals.

ORG        &H000       ;Begin program at x000
;***************************************************************
;* Initialization
;***************************************************************
Init:
    LOADI   0
    OUT     LVELCMD
    OUT     RVELCMD
    OUT     SONAREN     ; Disable sonar (optional)
    OUT     SSEG1
    OUT     SSEG2
    OUT     LCD
    
    CALL    SetupI2C    ; Configure the I2C to read the battery voltage
    CALL    BattCheck   ; Get battery voltage (and end if too low).
    ;OUT     LCD         ; Display batt voltage on LCD

WaitForSafety:          ; Wait for safety switch to be toggled
    IN      XIO         ; XIO contains SAFETY signal
    AND     Mask4       ; SAFETY signal is bit 4
    JPOS    WaitForUser ; If ready, jump to wait for PB3
    IN      TIMER       ; We'll use the timer value to
    AND     Mask1       ;  blink LED17 as a reminder to toggle SW17
    SHIFT   8           ; Shift over to LED17
    OUT     XLEDS       ; LED17 blinks at 2.5Hz (10Hz/4)
    JUMP    WaitForSafety
    
WaitForUser:            ; Wait for user to press PB3
    IN      TIMER       ; We'll blink the LEDs above PB3
    AND     Mask1
    SHIFT   5           ; Both LEDG6 and LEDG7
    STORE   Temp        ; (overkill, but looks nice)
    SHIFT   1
    OR      Temp
    OUT     XLEDS
    IN      XIO         ; XIO contains KEYs
    AND     Mask2       ; KEY3 mask (KEY0 is reset and can't be read)
    JPOS    WaitForUser ; not ready (KEYs are active-low, hence JPOS)
    LOADI   0
    OUT     XLEDS       ; clear LEDs once ready to continue

;***************************************************************
;* Main code
;***************************************************************
Main:                   ; Program starts here.
    CALL    StopMotors  ; Reset robot
    OUT     RESETPOS
    LOADI   &B00101101  ; Enable sides sensors (1 & 5) and front sensors (2 & 3)
    OUT     SONAREN


    CALL    ReadInput
    CALL    TryTurning
    CALL    Localize
    ;JUMP    navigate
    ;LOAD    CurrPosX
    ;SHIFT   8
    ;ADD     CurrPosY
    ;LOAD    CurrPosTry
    ;OUT     SSEG2
    ;OUT     RESETPOS
	;LOADI	2
	;STORE	MoveDist
	;CALL	MoveForward
	;  OUT     RESETPOS 
DieHard:
    CALL    ReadSides   ; Just for some simple testing of readings
    CALL    IsValidReading
    CALL    StopMotors
    LOADI   0
    OUT     SONAREN
    LOAD    DEAD         ; An indication that we are dead
    JUMP    DieHard

DEAD: DW    &HDEAD

;***************************************************************
;* Subroutines
;***************************************************************

MoveForward:
    OUT     RESETPOS
    LOADI   250
    ;STORE   LimitHigh
	CALL	MoveDistInFeet
MoveFwdLoop:
    LOADI	300
    CALL    MoveMotorsAC
    IN		XPOS
    SUB		MoveDist
    JNEG	MoveFwdLoop
    OUT 	RESETPOS
    CALL    StopMotors
    RETURN

LimitHigh:  DW  115
LimitLow:   DW  80
LimitValue: DW  0
LimitRoutine:
    JZERO   RetLowCutoff
    STORE   LimitValue
    JPOS    LimitHigher
    CALL    OppositeSign
    CALL    LimitRoutine
    CALL    OppositeSign
    RETURN
LimitHigher:
    SUB     LimitHigh
    JPOS    RetHighCutoff
    LOAD    LimitValue
    SUB     LimitLow
    JNEG    RetLowCutoff
    LOAD    LimitValue
    RETURN
RetHighCutoff:
    LOAD    LimitHigh
    RETURN
RetLowCutoff:
    LOAD    LimitLow
    RETURN

TurnAmount: DW  0
TurnAC:
    JUMP    TurnStart
TurnLeft90:
    LOADI   -88
    JUMP    TurnStart
TurnRight90:
    LOADI   88
TurnStart:
    STORE   TurnAmount
    OUT     RESETPOS
TurnACLoop:
    IN      THETA
    CALL    LimitDeg180
    ADD     TurnAmount
    SHIFT   2
    CALL    LimitRoutine
    CALL    TurnMotorsAC
	IN      THETA
    CALL    LimitDeg180
	ADD     TurnAmount
	JNEG    TurnACLoop
    CALL    BrakeMotors
	OUT     RESETPOS
	RETURN

;   DO NOT CHANGE THESE
;   EVER
;   OR I WILL HUNT YOU DOWN
;Posit#           ULDR  ; Position (X, Y) --> Up Lf Dn Rt
Posit0:     DW  &H3003  ; Position (1, 1)
Posit1:     DW  &H3102  ; Position (2, 1)
Posit2:     DW  &H1201  ; Position (3, 1)
Posit3:     DW  &H1300  ; Position (4, 1)
;Posit4
;Posit5
Posit6:     DW  &H2013  ; Position (1, 2)
Posit7:     DW  &H2112  ; Position (2, 2)
Posit8:     DW  &H0211  ; Position (3, 2)
Posit9:     DW  &H0310  ; Position (4, 2)
;Posit10
;Posit11
Posit12:    DW  &H1024  ; Position (1, 3)
Posit13:    DW  &H1123  ; Position (2, 3)
Posit14:    DW  &H1202  ; Position (3, 3)
Posit15:    DW  &H1301  ; Position (4, 3)
Posit16:    DW  &H1400  ; Position (5, 3)
;Posit17
Posit18:    DW  &H0035  ; Position (1, 4)
Posit19:    DW  &H0134  ; Position (2, 4)
Posit20:    DW  &H0213  ; Position (3, 4)
Posit21:    DW  &H0312  ; Position (4, 4)
Posit22:    DW  &H0411  ; Position (5, 4)
Posit23:    DW  &H0500  ; Position (6, 4)
Loc11:      DW  &H0101
Loc21:      DW  &H0201
Loc31:      DW  &H0301
Loc41:      DW  &H0401
Loc12:      DW  &H0102
Loc22:      DW  &H0202
Loc32:      DW  &H0302
Loc42:      DW  &H0402
Loc13:      DW  &H0103
Loc23:      DW  &H0203
Loc33:      DW  &H0303
Loc43:      DW  &H0403
Loc53:      DW  &H0503
Loc14:      DW  &H0104
Loc24:      DW  &H0204
Loc34:      DW  &H0304
Loc44:      DW  &H0404
Loc54:      DW  &H0504
Loc64:      DW  &H0604

CurrFootprint: DW  0
CurrRotat:  DW  0           ; 0 UP, 1 LEFT, 2 DOWN, 3 RIGHT
CurrPosX:   DW  0
CurrPosY:   DW  0
CurrPosTry: DW  0
GridCutoff: DW  100
Localize:
    IN      Dist0           ; Fix any reading errors
    IN      Dist5           ; Fix any reading errors
    CALL    Wait1           ; Wait a tiny bit
    
    IN      Dist0           ; After rotating 90, front reading
    SUB     GridCutoff      ; Subtract enough to ignore current square
    CALL    GetFeet         ; Convert to feet
    SHIFT   -1              ; Convert to grid
    SHIFT   12              ; XXXX ---- ---- ----
    STORE   CurrFootprint   ; Store in footprint
    
    IN      Dist5           ; After rotating 90, back reading
    SUB     GridCutoff      ; Subtract enough to ignore current square
    CALL    GetFeet
    SHIFT   -1              ; Convert to grid
    SHIFT   4               ; ---- ---- XXXX ----
    ADD     CurrFootprint
    STORE   CurrFootprint
    
    CALL    TurnLeft90      ; Turn 90 degrees to the left
    
    IN      Dist0           ; Left reading
    SUB     GridCutoff      ; Subtract enough to ignore current square
    CALL    GetFeet
    SHIFT   -1              ; Convert to grid
    SHIFT   8               ; ---- XXXX ---- ----
    ADD     CurrFootprint
    STORE   CurrFootprint
    
    IN      Dist5           ; Right reading
    SUB     GridCutoff      ; Subtract enough to ignore current square
    CALL    GetFeet
    SHIFT   -1              ; Convert to grid
    ADD     CurrFootprint
    STORE   CurrFootprint   ; Generate the current robot footprint

    ;OUT     SSEG1
    CALL    ComparePosits       ; Find out where the robot currently is, which stores CurrPosX, CurrPosY, CurrRotat
    ;LOAD    CurrPosX
    LOAD    CurrPosTry
    JPOS    CompareRet
    CALL    TryTurning
    JUMP    Localize
CompareRet:
    CALL    BeepFor3Secs
    RETURN

TempHead:       DW  0           ; The temp variable for the robot footprint
TempRot:        DW  -1          ; The temp variable for the robot rotation
ComparePosits:
    LOADI   -1
    STORE   TempRot
    LOAD    CurrFootprint       ; Take the current footprint
    STORE   TempHead            ; Copy it for safekeeping
CompareLoop:
    LOAD    TempRot             ; Start incrementing the rotation
    ADDI    1
    STORE   TempRot
Next0:                      ; Position 0
    ;LOADI   1
    ;STORE   CurrPosX        ; Store the X coordinate
    ;LOADI   1
    ;STORE   CurrPosY        ; Store the Y coordinate
    LOAD    Loc11
    STORE   CurrPosTry
    LOAD    Posit0
    SUB     TempHead
    JZERO   DoneComparePosits ; Check difference to see if footprint matches
Next1:                      ; Position 1
    LOAD    Loc21
    STORE   CurrPosTry
    LOAD    Posit1
    SUB     TempHead
    JZERO   DoneComparePosits
Next2:                      ; Position 2
    LOAD    Loc31
    STORE   CurrPosTry
    LOAD    Posit2
    SUB     TempHead
    JZERO   DoneComparePosits
Next3:                      ; Position 3
    LOAD    Loc41
    STORE   CurrPosTry
    LOAD    Posit3
    SUB     TempHead
    JZERO   DoneComparePosits
Next6:                      ; Position 6
    LOAD    Loc12
    STORE   CurrPosTry
    LOAD    Posit6
    SUB     TempHead
    JZERO   DoneComparePosits
Next7:                      ; Position 7
    LOAD    Loc22
    STORE   CurrPosTry
    LOAD    Posit7
    SUB     TempHead
    JZERO   DoneComparePosits
Next8:                      ; Position 8
    LOAD    Loc32
    STORE   CurrPosTry
    LOAD    Posit8
    SUB     TempHead
    JZERO   DoneComparePosits
Next9:                      ; Position 9
    LOAD    Loc42
    STORE   CurrPosTry
    LOAD    Posit9
    SUB     TempHead
    JZERO   DoneComparePosits
Next12:                     ; Position 12
    LOAD    Loc13
    STORE   CurrPosTry
    LOAD    Posit12
    SUB     TempHead
    JZERO   DoneComparePosits
Next13:                     ; Position 13
    LOAD    Loc23
    STORE   CurrPosTry
    LOAD    Posit13
    SUB     TempHead
    JZERO   DoneComparePosits
Next14:                     ; Position 14
    LOAD    Loc33
    STORE   CurrPosTry
    LOAD    Posit14
    SUB     TempHead
    JZERO   DoneComparePosits
Next15:                     ; Position 15
    LOAD    Loc43
    STORE   CurrPosTry
    LOAD    Posit15
    SUB     TempHead
    JZERO   DoneComparePosits
Next16:                     ; Position 16
    LOAD    Loc53
    STORE   CurrPosTry
    LOAD    Posit16
    SUB     TempHead
    JZERO   DoneComparePosits
Next18:                     ; Position 18
    LOAD    Loc14
    STORE   CurrPosTry
    LOAD    Posit18
    SUB     TempHead
    JZERO   DoneComparePosits
Next19:                     ; Position 19
    LOAD    Loc24
    STORE   CurrPosTry
    LOAD    Posit19
    SUB     TempHead
    JZERO   DoneComparePosits
Next20:                     ; Position 20
    LOAD    Loc34
    STORE   CurrPosTry
    LOAD    Posit20
    SUB     TempHead
    JZERO   DoneComparePosits
Next21:                     ; Position 21
    LOAD    Loc44
    STORE   CurrPosTry
    LOAD    Posit21
    SUB     TempHead
    JZERO   DoneComparePosits
Next22:                     ; Position 22
    LOAD    Loc54
    STORE   CurrPosTry
    LOAD    Posit22
    SUB     TempHead
    JZERO   DoneComparePosits
Next23:                     ; Position 23
    LOAD    Loc64
    STORE   CurrPosTry
    LOAD    Posit23
    SUB     TempHead
    JZERO   DoneComparePosits

    LOAD    TempRot
    ADDI    -4
    JNEG    NextContinue    ; Has it more more than 4 times?
    LOAD    TempRot
    ;OUT     SSEG1
    LOADI   -1              ; If so, set coordinates to (-1, -1)
    STORE   CurrPosX
    STORE   CurrPosY
    STORE   CurrPosTry
    RETURN        ; Die
NextContinue:
    LOAD    TempHead        ; Load the heading
    AND     FrstNibble   ; Get the 4 MSBs
    SHIFT   -12             ; Shift them to the far right
    STORE   Temp            ; Store them
    LOAD    TempHead        ; Get the heading back
    SHIFT   4               ; Shift them to the left (4 LSBs are now 0)
    ADD     Temp            ; Add the 4 original MSBs
    STORE   TempHead        ; Store it
    ;OUT     LCD
    JUMP    CompareLoop     ; Keep on chuggin'
DoneComparePosits:
    LOAD    TempRot         ; Found a match! Update the rotation
    STORE   CurrRotat
    LOAD    CurrPosTry
    AND     LastNibble
    STORE   CurrPosY
    LOAD    CurrPosTry
    SHIFT   -8
    AND     LastNibble
    STORE   CurrPosX
    LOAD    CurrPosTry
    OUT     SSEG1
    RETURN

Destin1:      DW  0           ; Destination 1 ID (from switches)
Destin2:      DW  0           ; Destination 2 ID (from switches)
Destin3:      DW  0           ; Destination 3 ID (from switches)
SubX:       DW  0           ; Temp variable for math
TempX:      DW  0           ; Temp variable while updating X coordinate
TempY:      DW  0           ; Temp variable while updating Y coordinate
First5Bits: DW  &B0000000000011111 ; First 5 bits (used for obtaining the correct destinations from switches)
Dest1X:     DW  0           ; Destination 1 X coordinate
Dest1Y:     DW  0           ; Destination 1 Y coordinate
Dest2X:     DW  0           ; Destination 2 X coordinate
Dest2Y:     DW  0           ; Destination 2 Y coordinate
Dest3X:     DW  0           ; Destination 3 X coordinate
Dest3Y:     DW  0           ; Destination 3 Y coordinate
ReadInput:              ; Reads input switches, stores the (X, Y) coordinates of each
    IN      SWITCHES
    AND     First5Bits  ; Look only at 1st 5 bits
    STORE   Destin1       ; Destination 1
    IN      SWITCHES
    SHIFT   -5          ; Bring to front, chopping off 1st 5 bits (destination 1)
    AND     First5Bits  ; Look only at new 1st 5 bits
    STORE   Destin2       ; Destination 2
    IN      SWITCHES
    SHIFT   -10         ; Bring to front, chopping off 1st 10 bits (destination 1 & 2)
    AND     First5Bits  ; Look only at new 1st 5 bits
    STORE   Destin3       ; Destination 3
    
    LOAD    Destin1
    CALL    ReadX       ; Find the X coordinate from the Position #
    STORE   Dest1X
    LOAD    Destin1
    CALL    ReadY       ; Find the Y coordinate from the Position #
    STORE   Dest1Y
    
    LOAD    Destin2
    CALL    ReadX
    STORE   Dest2X
    LOAD    Destin2
    CALL    ReadY
    STORE   Dest2Y
    
    LOAD    Destin3
    CALL    ReadX
    STORE   Dest3X
    LOAD    Destin3
    CALL    ReadY
    STORE   Dest3Y
    
    LOAD    Dest1X      ; Displaying:  Get X coordinate
    SHIFT   8           ; Shift it to left 2 digits of SSEG/LCD
    ADD     Dest1Y      ; Add Y coordinate (right 2 digits)
    ;OUT     SSEG1       ; Display
    RETURN

ReadX:                  ; Gets the X coordinate from the position #
    STORE   TempX       ; Store position # temporarily
ReadXLoop:
    LOAD    TempX
    ADDI    -6          ; Keep on subtracting 6
    STORE   TempX
    JPOS    ReadXLoop
    JZERO   ReadXLoop
    ADDI    7           ; Until negative, fix value, add 1 for offset (1, 1)
    RETURN
    
ReadY:                  ; Gets the Y coordinate from the position #
    STORE   SubX        ; Store position # temporarily
    LOADI   0
    STORE   TempY       ; Set Y to 0
ReadYLoop:
    LOAD    TempY
    ADDI    1
    STORE   TempY       ; Increment Y while still > 0 (Square 0 --> 1, Height 6 --> 2)
    LOAD    SubX
    ADDI    -6
    STORE   SubX
    JPOS    ReadYLoop
    JZERO   ReadYLoop
    LOAD    TempY
    RETURN

SideArgs:   DW  0       ; Variable for reading side distances
Error:      DW  50      ; Error to ignore robot width
ReadSides:              ; Read side sensors and get total (with error accounting)
    IN      Dist0       ; Read sensor 0 (left side)
    STORE   SideArgs    ; Store
    IN      Dist5       ; Read sensor 5 (right side)
    ADD     SideArgs    ; Add left side
    ADD     Error
    STORE   SideArgs    ; Store
    RETURN

IsValidReading:         ; Checks if correctly seeing a distance of 8, 10, or 12 feet
    CALL    GetFeet
    STORE   Temp
    ADDI    -8          
    JZERO   Read4       ; Sees 4 squares on either side
    ADDI    -2
    JZERO   Read5       ; Sees 5 squares on either side
    ADDI    -2
    JZERO   Read6       ; Sees 6 squares on either side
    LOADI   -1          ; Bad reading
    RETURN
Read4:
    LOADI   4           ; Load 4 squares for output
    RETURN
Read5:
    LOADI   5           ; Load 5 squares for output
    RETURN
Read6:
    LOADI   6           ; Load 6 squares for output
    RETURN
    
Counter:        DW  3  
FrontCutoff:    DW  1000
TryTurning:             ; Tries to turn until it detects a valid orientation based on side distance
    OUT     RESETPOS
TurnLoopStart:          ; Turns a bit before detecting a good distance - starts turning to build up inertia
    CALL    TurnMotorsFSlow
    CALL    Wait1
    LOAD    Counter
    ADDI    -1
    STORE   Counter
    JPOS    TurnLoopStart
TurnCheck:              ; Makes sure it doesn't start reading a good distance - odd things happen when seeing a wall immediately.
    CALL    ReadSides
    CALL    IsValidReading
    JPOS    TurnLoopStart
TurnLoop:               ; Turns the robot until it reads a good distance (going sideways) as well as one in front
    CALL    TurnMotorsFSlow
    CALL    ReadSides
    CALL    IsValidReading
    JNEG    TurnLoop
    IN      DIST3
    SUB     FrontCutoff
    JPOS    TurnLoop
    CALL    BrakeMotors
    LOADI   3
    CALL    WaitAC
    CALL    ReadSides   ; Tests still sees good distance after breaking
    CALL    IsValidReading
    JNEG    TurnLoop    ; Tries again if invalid
    LOADI   -3
    CALL    TurnAC
    RETURN

FtAmount:   DW  0
FtCount:    DW  0
GetFeet:                ; Converts AC sensor reading to feet. Effectively Math.ceiling(sensorVal/FootDistance)
    STORE   FtAmount    ; Stores AC reading
    LOADI   0
    STORE   FtCount     ; Resets counter
FeetLoop:               ; Loops counting feet
    LOAD    FtCount
    ADDI    1
    STORE   FtCount     ; Store feet counted
    LOAD    FtAmount
    SUB     OneFtDist
    STORE   FtAmount
    JPOS    FeetLoop    ; Still positive ? Then another foot long
    LOAD    FtCount     ; Store output value in AC to return
    RETURN    

BeepFor3Secs:
    LOADI   4
    OUT     BEEP
    LOADI   30
    CALL    WaitAC
    LOADI   0
    OUT     BEEP
    RETURN
    
MoveMotorsFSlow:        ; Moves the robot at the default slow velocity
    LOAD    FSlow
    JUMP    MoveMotorsAC
StopMotors:             ; Sets all motors to 0
    LOADI   0
MoveMotorsAC:           ; Sets motor velocity to AC
    STORE   VelL
    STORE   VelR
    JUMP    UpdateMotors

TurnMotorsFSlow:        ; Rotates the robot at the default slow velocity
    LOAD    FSlow
TurnMotorsAC:           ; Rotates the robot at the AC velocity
    STORE   VelL
    LOADI   0
    SUB     VelL
    STORE   VelR
    JUMP    UpdateMotors

BrakeMotors:            ; Provides a 'braking' system by inverting the velocities for a short time, then setting to 0
    LOADI   0
    SUB     VelL
    STORE   VelL
    LOADI   0
    SUB     VelR
    STORE   VelR
    CALL    UpdateMotors
    LOADI   2
    CALL    WaitAC
    LOADI   0
    STORE   VelR
    STORE   VelL
    JUMP    UpdateMotors
    
VelL:       DW  0
VelR:       DW  0
UpdateMotors:           ; Reassigns the motor velocities to the motor controllers - use in loops
    LOAD    VelL
    OUT     LVELCMD
    LOAD    VelR
    OUT     RVELCMD
    RETURN
    
Mod360:
	JNEG    M360N       ; loop exit condition
	ADDI    -360        ; start removing 360 at a time
	JUMP    Mod360      ; keep going until negative
M360N:
	ADDI    360         ; get back to positive
	JNEG    M360N       ; (keep adding 360 until non-negative)
	RETURN
    
LimitDeg180:
    ADDI    179
    CALL    Mod360
    ADDI    -179
    RETURN

AbsArgs:    DW  0
AbsoluteVal:            ; Gets the absolute value
    JNEG    OppositeSign
    RETURN
OppositeSign:           ; Returns with AC as (-AC)
    STORE   AbsArgs
    LOADI   0
    SUB     AbsArgs
    RETURN

Wait1:  LOADI   10      ; Wait for 1 second
WaitAC: STORE   WaitTime; Wait for ticks in AC
Wait:   OUT   Timer     ; Wait for ticks in WaitTime
WaitLoop:               ; Wait for number of ticks
    IN      Timer
    OUT     XLEDS       ; User-feedback that a pause is occurring.
    SUB     WaitTime
    JNEG    WaitLoop
    RETURN

BattCheck:              ; Gets battery voltage, halts if too low (SetupI2C must be executed prior to this)
    CALL    GetBattLvl
    JZERO   BattCheck   ; A/D hasn't had time to initialize
    SUB     MinBatt
    JNEG    DeadBatt
    ADD     MinBatt     ; get original value back
    RETURN

DeadBatt:               ; Check for low battery, halt if too low
    LOADI   4
    OUT     BEEP        ; start beep sound
    CALL    GetBattLvl  ; get the battery level
    OUT     SSEG1       ; display it everywhere
    OUT     SSEG2
    ;OUT     LCD
    LOADI   0
    ADDI    -1          ; 0xFFFF
    OUT     LEDS        ; all LEDs on
    OUT     XLEDS
    CALL    Wait1       ; 1 second
    LOADI   0
    OUT     BEEP        ; stop beeping
    OUT     LEDS        ; LEDs off
    OUT     XLEDS
    CALL    Wait1       ; 1 second
    JUMP    DeadBatt    ; repeat forever
    
GetBattLvl:             ; Reads battery voltage (assuming SetupI2C has been run)
    LOAD    I2CRCmd     ; 0x0190 (write 0B, read 1B, addr 0x90)
    OUT     I2C_CMD     ; to I2C_CMD
    OUT     I2C_RDY     ; start the communication
    CALL    BlockI2C    ; wait for it to finish
    IN      I2C_DATA    ; get the returned data
    RETURN

SetupI2C:               ; Subroutine to configure the I2C for reading batt voltage (Only needs to be done once after each reset)
    CALL    BlockI2C    ; wait for idle
    LOAD    I2CWCmd     ; 0x1190 (write 1B, read 1B, addr 0x90)
    OUT     I2C_CMD     ; to I2C_CMD register
    LOADI   0           ; 0x0000 (A/D port 0, no increment)
    OUT     I2C_DATA    ; to I2C_DATA register
    OUT     I2C_RDY     ; start the communication
    CALL    BlockI2C    ; wait for it to finish
    RETURN

BlockI2C:               ; Subroutine to block until I2C device is idle
    LOADI   0
    STORE   Temp        ; Used to check for timeout
BI2CL:
    LOAD    Temp
    ADDI    1           ; this will result in ~0.1s timeout
    STORE   Temp
    JZERO   I2CError    ; Timeout occurred; error
    IN      I2C_RDY     ; Read busy signal
    JPOS    BI2CL       ; If not 0, try again
    RETURN             ; Else return
I2CError:
    LOADI   0
    ADDI    &H12C       ; "I2C"
    OUT     SSEG1
    OUT     SSEG2       ; display error message
    JUMP    I2CError

; Subroutine to send AC value through the UART,
; formatted for default base station code:
; [ AC(15..8) | AC(7..0) | \lf ]
; Note that special characters such as \lf are
; escaped with the value 0x1B, thus the literal
; value 0x1B must be sent as 0x1B1B, should it occur.
UARTSend:
    STORE   UARTTemp
    SHIFT   -8
    ADDI    -27   ; escape character
    JZERO   UEsc1
    ADDI    27
    OUT     UART_DAT
    JUMP    USend2
UEsc1:
    ADDI    27
    OUT     UART_DAT
    OUT     UART_DAT
USend2:
    LOAD    UARTTemp
    AND     LowByte
    ADDI    -27   ; escape character
    JZERO   UEsc2
    ADDI    27
    OUT     UART_DAT
    RETURN
UEsc2:
    ADDI    27
    OUT     UART_DAT
    OUT     UART_DAT
    RETURN
UARTTemp:   DW  0

UARTNL:
    LOAD    NL
    OUT     UART_DAT
    SHIFT   -8
    OUT     UART_DAT
    RETURN
NL: DW      &H0A1B

;---------------------navigation stuff------------------


; points have already been entered and placed into dest1X,
; dest1Y, etc. MoveForward & TurnLeft90 implemented




Navigate:
		LOADI	-1
		STORE	Resetting
		;fix direction stuff
		setDir:
		LOAD	CurrRotat
		JZERO	currDirNorth
		ADDI	-1
		JZERO	currDirWest
		ADDI    -1
		JZERO	currDirSouth
		LOADI	2
		STORE	CURRDIR	;east
		JUMP	RegStuff
		
currDirNorth:
		LOADI   0
		STORE	CURRDIR
		JUMP	RegStuff
currDirWest:
		LOADI	3
		STORE	CURRDIR
		JUMP	RegStuff
currDirSouth:
		LOADI	1
		STORE	CURRDIR

RegStuff:
		LOAD	CurrPosY
		STORE	yRegion
		LOAD 	CurrPosX
		STORE 	TempX
		CALL	RegionSet
		LOAD	tempRegion
		STORE	currRegion
		LOAD	Resetting
		JPOS	check2
		;for 1st dest coord
		LOAD	Dest1Y
		STORE	yRegion
		LOAD	Dest1X
		STORE 	TempX
		CALL	RegionSet
		LOAD	tempRegion
		STORE	dest1Region
		;for 2nd dest coord
		LOAD	Dest2Y
		STORE	yRegion
		LOAD	Dest2X
		STORE 	TempX
		CALL	RegionSet
		LOAD	tempRegion
		STORE	dest2Region
		;for 3rd dest coord
		LOAD	Dest3Y
		STORE	yRegion
		LOAD	Dest3X
		STORE 	TempX
		CALL	RegionSet
		LOAD	tempRegion
		STORE	dest3Region


;now want to go from curr loc to dest1
check1:
		CALL	storeTempsR1	;used to check same region
		CALL	checkSameRegion
		LOAD 	DESTX
		JNEG    diffReg		;weren't in same region
		;otherwise are in the same region
		CALL	Calc	;upon return, have moved
		CALL	BeepFor3Secs	;should have arrived
		;now the currPosX and currPosY have changed
		JUMP	Reset		;will reset current region
		
		
check2: 


storeTempsR1:
		LOAD	dest1Region
		STORE	tempRegion
		LOAD	Dest1X
		STORE	tempRegX
		LOAD	Dest1Y
		STORE	tempRegY
		RETURN
		
Reset:	LOADI	1
		STORE	Resetting
		JUMP	RegStuff
		
		
diffReg:
		LOAD	tempRegion	;will be a destination
		ADDI	-2
		JPOS	destReg3
		JNEG	destReg3
		;jzero, the destination is region 2 and CurrPos is not the same
		LOAD	tempRegX
		STORE	DESTX
		LOAD	tempRegY
		STORE	DESTY
		CALL	R1orR3toR2
		;returns after going to dest
setDest:
		LOAD	tempYdest
		STORE	CurrPosY
		LOAD	tempXdest
		STORE	CurrPosX
		JUMP	Reset
		
		
destReg3:
		LOAD	currRegion
		ADDI	-2
		JNEG	currReg1
		;jzero the current region is 2, want to go to 3
		CALL	R2toR1orR3
		

currReg1:
		LOAD	tempRegX
		STORE	DESTX
		LOAD	tempRegY
		STORE	DESTY
		CALL	Reg1to3vv
		
Reg1to3vv:	;region 1 to 3 and region 3 to 1
		LOAD	DESTX
		STORE	XrestoreAfterHalf
		LOAD	DESTY
		STORE	YrestoreAfterHalf
		LOADI	2
		STORE	DESTX	;make (2,2) the half-way point
		STORE	DESTY
		CALL	Calc	;afterwards, has moved to halfway point
		LOAD	XrestoreAfterHalf
		STORE	DESTX
		LOAD	YrestoreAfterHalf
		STORE	DESTY
		CALL	Calc


RegionSet:
		LOAD	TempX	;load the X coord
		ADDI	-2
		JPOS	notR2
		;is in region2
		LOADI   2
		STORE	tempRegion
		RETURN
notR2:  LOAD	yRegion
		ADDI    -2
		JPOS	Reg3
		;is in region 1
		LOADI   1
		STORE	tempRegion
		RETURN
Reg3:	LOADI	3
		STORE	tempRegion
		RETURN
		

checkSameRegion:
		LOAD	currRegion
		SUB		tempRegion
		JPOS	skip
		JNEG	skip
		;they are both in the same region
		LOAD	Dest1X
		STORE	DESTX
		LOAD	Dest1Y
		STORE	DESTY
		RETURN
skip:	LOADI   -1 		;they were not in the same region,
		STORE   DESTX   ;keep the destinations unset
		STORE   DESTY
		RETURN

		
R1orR3toR2: ;move from region 1 or 3 to region 2, go X first then Y
        LOAD    Dest1X
        STORE   DestX
        LOAD    Dest1Y
        STORE   DestY
		;LOAD	CurrPosX
		;STORE	CurrPosX
		;LOAD	CurrPosY
		;STORE	CurrPosY
		CALL	Calc
		RETURN
R2toR1orR3: ;move Y direction frst then X
		CALL	calcY
		;has moved Y dist
		CALL	calcX
		;has moved X dist
		RETURN

;-------------------

Calc:	CALL 	CalcX
		;has moved to appropriate X coord
		CALL 	CalcY
		;has moved to appropriate Y coord
		;CALL	checkDest       ;make sure its right
		;CALL	outputDest		;beep and such
		RETURN
calcX:
		LOAD 	CurrPosX
		SUB		DESTX
		STORE	XDIST
		JNEG	FlipX
		JPOS	GoWest
		;jzero = stay in this column
		RETURN
FlipX:	LOAD 	XDIST
		XOR 	NegOne
		ADDI    1
		STORE	XDIST
		;distance is now positive
		JUMP 	GoEast


calcY:
		LOAD 	CurrPosY
		SUB 	DESTY
		STORE   YDIST
		JNEG 	FlipY
		JPOS 	GoSouth
		;jzero = stay in this row
		RETURN
FlipY:	LOAD	YDIST
		XOR 	NegOne
		ADDI    1
		STORE	YDIST
		;distance is now positive
		JUMP	GoNorth


GoEast:
		LOAD	CURRDIR
		STORE	tempDir
		LOADI	2
		STORE	CURRDIR		;update currdir after
		LOAD    XDIST
		STORE   MoveDist    ;want to move X coord
		LOAD 	tempDir
		JZERO 	turnRight	;at north
		ADDI	-1
		JZERO 	turnLeft	;at south
		ADDI	-1
		JZERO   East		;at east
		JUMP	turn180     ;at west
East:	LOADI	2
		STORE	CURRDIR
		CALL	MoveForward
		RETURN

GoNorth:
		LOAD	CURRDIR
		STORE	tempDir
		LOADI	0
		STORE	CURRDIR
		LOAD    YDIST
		STORE   MoveDist    ;want to move Y coord
		LOAD 	tempDir
		JZERO 	North		;at north
		ADDI	-3
		JZERO 	turn180		;at south
		ADDI	-1
		JZERO   turnLeft	;at east
		JUMP	turnRight   ;at west
North:	LOADI	0
		STORE 	CURRDIR
		CALL	MoveForward
		RETURN

GoSouth:	
		LOAD	CURRDIR
		STORE	tempDir
		LOADI	1
		STORE	CURRDIR	
		LOAD    YDIST
		STORE   MoveDist    ;want to move Y coord
		LOAD 	tempDir
		JZERO 	turn180		;at north
		ADDI	-1
		JZERO 	South		;at south
		ADDI	-1
		JZERO   turnLeft	;at east
		JUMP	turnRight   ;at west
South:	LOADI	1
		STORE   CURRDIR
		CALL	MoveForward
		RETURN

GoWest:
		LOAD	CURRDIR
		STORE	tempDir
		LOADI	3
		STORE	CURRDIR
		LOAD    XDIST
		STORE   MoveDist    ;want to move X coord
		LOAD 	tempDir
		JZERO 	turnLeft	;at north
		ADDI	-1
		JZERO 	turnRight	;at south
		ADDI	-1
		JZERO   turn180		;at east
		LOADI	3			;at west
		STORE	CURRDIR
		CALL 	MoveForward
		RETURN


turn180:
		CALL 	TurnLeft90
		CALL 	TurnLeft90
		CALL 	MoveForward
		RETURN
turnRight:
		CALL 	TurnRight90
		CALL 	MoveForward
		RETURN
turnLeft:
		CALL 	TurnLeft90
		CALL 	MoveForward
		RETURN
		
	
MoveDistInFeet:
        LOAD    MoveDist
        SHIFT   1
        STORE   MoveDist
        RETURN

		LOADI	0
		STORE	Temp
MDIF:	LOAD	Temp
		ADD		TwoFeet
		STORE	Temp
		LOAD	MoveDist
		ADDI	-1
		STORE	MoveDist
		JPOS	MDIF
		LOAD	Temp
		STORE	MoveDist
		RETURN



;***************************************************************
;* Variables
;***************************************************************

yRegion:			DW    0
tempRegion:			DW    0
tempRegX:			DW    0
tempRegY:			DW    0
tempYdest:			DW	  0
tempXdest:			DW    0
tempDir:			DW	  0
currRegion:			DW    0
dest1Region:		DW    0
dest2Region:		DW    0
dest3Region:		DW    0
XrestoreAfterHalf:	DW	  0
YrestoreAfterHalf:  DW	  0
DESTX:				DW    -1
DESTY:				DW    -1
XDIST:				DW 	  0
YDIST:				DW    0
MoveDist:			DW 	  0
Resetting:			DW	  -1
CURRDIR:			DW    -1
;NORTH:				DW    0
;SOUTH:				DW    1
;EAST:				DW    2
;WEST:				DW    3
;***************************************************************
;* Variables
;***************************************************************

Temp:       DW  0   ; Temporary Variable
Temp2:      DW  0   ; Temporary Variable 2
WaitTime:   DW  0   ; Input to Wait
OneFtDist:  DW  304 ; roughly 304.8 mm per ft (but ticks are ~1.05 mm, so about 290.3 ticks)
FrstNibble: DW  &HF000
LastNibble: DW  &H000F
NegOne:     DW  &HFFFF ; All 1s

;***************************************************************
;* Constants
;* (though there is nothing stopping you from writing to these)
;***************************************************************

; Some bit masks.
; Masks of multiple bits can be constructed by ORing these
; 1-bit masks together.
Mask0:      DW  &B00000001
Mask1:      DW  &B00000010
Mask2:      DW  &B00000100
Mask3:      DW  &B00001000
Mask4:      DW  &B00010000
Mask5:      DW  &B00100000
Mask6:      DW  &B01000000
Mask7:      DW  &B10000000
LowByte:    DW  &HFF      ; binary 00000000 1111111

; some useful movement values
OneMeter:   DW  961       ; ~1m in 1.05mm units
HalfMeter:  DW  481      ; ~0.5m in 1.05mm units
TwoFeet:    DW  586       ; ~2ft in 1.05mm units
Deg90:      DW  90        ; 90 degrees in odometry units
Deg180:     DW  180       ; 180
Deg270:     DW  270       ; 270
Deg360:     DW  360       ; can never actually happen; for math only
FSlow:      DW  130       ; 100 is about the lowest velocity value that will move
RSlow:      DW  -130
FMid:       DW  350       ; 350 is a medium speed
RMid:       DW  -350
FFast:      DW  500       ; 500 is almost max speed (511 is max)
RFast:      DW  -500

MinBatt:    DW  130       ; 13.0V - minimum safe battery voltage
I2CWCmd:    DW  &H1190    ; write one i2c byte, read one byte, addr 0x90
I2CRCmd:    DW  &H0190    ; write nothing, read one byte, addr 0x90

;***************************************************************
;* IO address space map
;***************************************************************
SWITCHES:   EQU &H00  ; slide switches
LEDS:       EQU &H01  ; red LEDs
TIMER:      EQU &H02  ; timer, usually running at 10 Hz
XIO:        EQU &H03  ; pushbuttons and some misc. inputs
SSEG1:      EQU &H04  ; seven-segment display (4-digits only)
SSEG2:      EQU &H05  ; seven-segment display (4-digits only)
LCD:        EQU &H06  ; primitive 4-digit LCD display
XLEDS:      EQU &H07  ; Green LEDs (and Red LED16+17)
BEEP:       EQU &H0A  ; Control the beep
CTIMER:     EQU &H0C  ; Configurable timer for interrupts
LPOS:       EQU &H80  ; left wheel encoder position (read only)
LVEL:       EQU &H82  ; current left wheel velocity (read only)
LVELCMD:    EQU &H83  ; left wheel velocity command (write only)
RPOS:       EQU &H88  ; same values for right wheel...
RVEL:       EQU &H8A  ; ...
RVELCMD:    EQU &H8B  ; ...
I2C_CMD:    EQU &H90  ; I2C module's CMD register,
I2C_DATA:   EQU &H91  ; ... DATA register,
I2C_RDY:    EQU &H92  ; ... and BUSY register
UART_DAT:   EQU &H98  ; UART data
UART_RDY:   EQU &H98  ; UART status
SONAR:      EQU &HA0  ; base address for more than 16 registers....
DIST0:      EQU &HA8  ; the eight sonar distance readings
DIST1:      EQU &HA9  ; ...
DIST2:      EQU &HAA  ; ...
DIST3:      EQU &HAB  ; ...
DIST4:      EQU &HAC  ; ...
DIST5:      EQU &HAD  ; ...
DIST6:      EQU &HAE  ; ...
DIST7:      EQU &HAF  ; ...
SONALARM:   EQU &HB0  ; Write alarm distance; read alarm register
SONARINT:   EQU &HB1  ; Write mask for sonar interrupts
SONAREN:    EQU &HB2  ; register to control which sonars are enabled
XPOS:       EQU &HC0  ; Current X-position (read only)
YPOS:       EQU &HC1  ; Y-position
THETA:      EQU &HC2  ; Current rotational position of robot (0-359)
RESETPOS:   EQU &HC3  ; write anything here to reset odometry to 0