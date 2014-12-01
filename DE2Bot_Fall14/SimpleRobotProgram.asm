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
    
    ;CALL    TurnLeft90

    CALL    ReadInput
    CALL    TryTurning
    CALL    Localize
    ;LOAD    CurrPosX
    ;SHIFT   8
    ;ADD     CurrPosY
    LOAD    CurrPosTry
    OUT     SSEG2
    OUT     RESETPOS
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
XDIST:  DW  500
MoveForward:
    OUT     RESETPOS
    LOADI   250
    ;STORE   LimitHigh
MoveFwdLoop:
    LOADI	300
    CALL    MoveMotorsAC
    IN		XPOS
    SUB		XDIST ;what to subtract if we want to move Y?
    CALL    LimitRoutine
    JNEG	MoveForward
    OUT 	RESETPOS
    CALL    StopMotors
    RETURN

LimitHigh:  DW  115
LimitLow:   DW  80
LimitValue: DW  0
LimitRoutine:
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
    LOADI   -90
    JUMP    TurnStart
TurnRight90:
    LOADI   90
TurnStart:
    CALL    Increment
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

Increment:
    JNEG    IncrementNeg
    ADDI    1
    RETURN
IncrementNeg:
    ADDI    -1
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

    OUT     SSEG1
    CALL    ComparePosits       ; Find out where the robot currently is, which stores CurrPosX, CurrPosY, CurrRotat
    ;LOAD    CurrPosX
    LOAD    CurrPosTry
    JPOS    CompareRet
    CALL    TryTurning
    JUMP    Localize
CompareRet:
    RETURN

FirstFourBits:  DW  &HF000      ; The first 4 bits (used for rotations0
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
    LOADI   &H0101
    STORE   CurrPosTry
    LOAD    Posit0
    SUB     TempHead
    JZERO   DoneComparePosits ; Check difference to see if footprint matches
Next1:                      ; Position 1
    ;LOADI   2
    ;STORE   CurrPosX
    ;LOADI   1
    ;STORE   CurrPosY
    LOADI   &H0201
    STORE   CurrPosTry
    LOAD    Posit1
    SUB     TempHead
    JZERO   DoneComparePosits
Next2:                      ; Position 2
    ;LOADI   3
    ;STORE   CurrPosX
    ;LOADI   1
    ;STORE   CurrPosY
    LOADI   &H0301
    STORE   CurrPosTry
    LOAD    Posit2
    SUB     TempHead
    JZERO   DoneComparePosits
Next3:                      ; Position 3
    ;LOADI   4
    ;STORE   CurrPosX
    ;LOADI   1
    ;STORE   CurrPosY
    LOADI   &H0401
    STORE   CurrPosTry
    LOAD    Posit3
    SUB     TempHead
    JZERO   DoneComparePosits
Next6:                      ; Position 6
    ;LOADI   1
    ;STORE   CurrPosX
    ;LOADI   2
    ;STORE   CurrPosY
    LOADI   &H0102
    STORE   CurrPosTry
    LOAD    Posit6
    SUB     TempHead
    JZERO   DoneComparePosits
Next7:                      ; Position 7
    ;LOADI   2
    ;STORE   CurrPosX
    ;LOADI   2
    ;STORE   CurrPosY
    LOADI   &H0202
    STORE   CurrPosTry
    LOAD    Posit7
    SUB     TempHead
    JZERO   DoneComparePosits
Next8:                      ; Position 8
    ;LOADI   3
    ;STORE   CurrPosX
    ;LOADI   2
    ;STORE   CurrPosY
    LOADI   &H0302
    STORE   CurrPosTry
    LOAD    Posit8
    SUB     TempHead
    JZERO   DoneComparePosits
Next9:                      ; Position 9
    ;LOADI   4
    ;STORE   CurrPosX
    ;LOADI   2
    ;STORE   CurrPosY
    LOADI   &H0402
    STORE   CurrPosTry
    LOAD    Posit9
    SUB     TempHead
    JZERO   DoneComparePosits
Next12:                     ; Position 12
    ;LOADI   1
    ;STORE   CurrPosX
    ;LOADI   3
    ;STORE   CurrPosY
    LOADI   &H0103
    STORE   CurrPosTry
    LOAD    Posit12
    SUB     TempHead
    JZERO   DoneComparePosits
Next13:                     ; Position 13
    ;LOADI   2
    ;STORE   CurrPosX
    ;LOADI   3
    ;STORE   CurrPosY
    LOADI   &H0203
    STORE   CurrPosTry
    LOAD    Posit13
    SUB     TempHead
    JZERO   DoneComparePosits
Next14:                     ; Position 14
    ;LOADI   3
    ;STORE   CurrPosX
    ;LOADI   3
    ;STORE   CurrPosY
    LOADI   &H0303
    STORE   CurrPosTry
    LOAD    Posit14
    SUB     TempHead
    JZERO   DoneComparePosits
Next15:                     ; Position 15
    ;LOADI   4
    ;STORE   CurrPosX
    ;LOADI   3
    ;STORE   CurrPosY
    LOADI   &H0403
    STORE   CurrPosTry
    LOAD    Posit15
    SUB     TempHead
    JZERO   DoneComparePosits
Next16:                     ; Position 16
    ;LOADI   5
    ;STORE   CurrPosX
    ;LOADI   3
    ;STORE   CurrPosY
    LOADI   &H0503
    STORE   CurrPosTry
    LOAD    Posit16
    SUB     TempHead
    JZERO   DoneComparePosits
Next18:                     ; Position 18
    ;LOADI   1
    ;STORE   CurrPosX
    ;LOADI   4
    ;STORE   CurrPosY
    LOADI   &H0104
    STORE   CurrPosTry
    LOAD    Posit18
    SUB     TempHead
    JZERO   DoneComparePosits
Next19:                     ; Position 19
    ;LOADI   2
    ;STORE   CurrPosX
    ;LOADI   4
    ;STORE   CurrPosY
    LOADI   &H0204
    STORE   CurrPosTry
    LOAD    Posit19
    SUB     TempHead
    JZERO   DoneComparePosits
Next20:                     ; Position 20
    ;LOADI   3
    ;STORE   CurrPosX
    ;LOADI   4
    ;STORE   CurrPosY
    LOADI   &H0304
    STORE   CurrPosTry
    LOAD    Posit20
    SUB     TempHead
    JZERO   DoneComparePosits
Next21:                     ; Position 21
    ;LOADI   4
    ;STORE   CurrPosX
    ;LOADI   4
    ;STORE   CurrPosY
    LOADI   &H0404
    STORE   CurrPosTry
    LOAD    Posit21
    SUB     TempHead
    JZERO   DoneComparePosits
Next22:                     ; Position 22
    ;LOADI   5
    ;STORE   CurrPosX
    ;LOADI   4
    ;STORE   CurrPosY
    LOADI   &H0504
    STORE   CurrPosTry
    LOAD    Posit22
    SUB     TempHead
    JZERO   DoneComparePosits
Next23:                     ; Position 23
    ;LOADI   6
    ;STORE   CurrPosX
    ;LOADI   4
    ;STORE   CurrPosY
    LOADI   &H0604
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
    AND     FirstFourBits   ; Get the 4 MSBs
    SHIFT   -12             ; Shift them to the far right
    STORE   Temp            ; Store them
    LOAD    TempHead        ; Get the heading back
    SHIFT   4               ; Shift them to the left (4 LSBs are now 0)
    ADD     Temp            ; Add the 4 original MSBs
    STORE   TempHead        ; Store it
    OUT     LCD
    JUMP    CompareLoop     ; Keep on chuggin'
DoneComparePosits:
    LOAD    TempRot         ; Found a match! Update the rotation
    STORE   CurrRotat
    RETURN

Dest1:      DW  0           ; Destination 1 ID (from switches)
Dest2:      DW  0           ; Destination 2 ID (from switches)
Dest3:      DW  0           ; Destination 3 ID (from switches)
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
    STORE   Dest1       ; Destination 1
    IN      SWITCHES
    SHIFT   -5          ; Bring to front, chopping off 1st 5 bits (destination 1)
    AND     First5Bits  ; Look only at new 1st 5 bits
    STORE   Dest2       ; Destination 2
    IN      SWITCHES
    SHIFT   -10         ; Bring to front, chopping off 1st 10 bits (destination 1 & 2)
    AND     First5Bits  ; Look only at new 1st 5 bits
    STORE   Dest3       ; Destination 3
    
    LOAD    Dest1
    CALL    ReadX       ; Find the X coordinate from the Position #
    STORE   Dest1X
    LOAD    Dest1
    CALL    ReadY       ; Find the Y coordinate from the Position #
    STORE   Dest1Y
    
    LOAD    Dest2
    CALL    ReadX
    STORE   Dest2X
    LOAD    Dest2
    CALL    ReadY
    STORE   Dest2Y
    
    LOAD    Dest3
    CALL    ReadX
    STORE   Dest3X
    LOAD    Dest3
    CALL    ReadY
    STORE   Dest3Y
    
    LOAD    Dest1X      ; Displaying:  Get X coordinate
    SHIFT   8           ; Shift it to left 2 digits of SSEG/LCD
    ADD     Dest1Y      ; Add Y coordinate (right 2 digits)
    ;OUT     SSEG2       ; Display
    RETURN

ReadX:                  ; Gets the X coordinate from the position #
    STORE   TempX       ; Store position # temporarily
ReadXLoop:
    LOAD    TempX
    ADDI    -6          ; Keep on subtracting 6
    STORE   TempX
    JPOS    ReadXLoop
    JZERO   ReadXLoop
    ADDI    6           ; Until negative, fix value
    ADDI    1           ; And adjust for starting coordinate (1, 1)
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
    ADDI    180
    CALL    Mod360
    ADDI    -180
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

;***************************************************************
;* Variables
;***************************************************************

Temp:       DW  0   ; Temporary Variable
Temp2:      DW  0   ; Temporary Variable 2
WaitTime:   DW  0   ; Input to Wait
OneFtDist:  DW  304 ; roughly 304.8 mm per ft (but ticks are ~1.05 mm, so about 290.3 ticks)
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
LowNibl:    DW  &HF       ; 0000 0000 0000 1111

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
