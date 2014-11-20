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
    LOAD    Zero
    OUT     LVELCMD
    OUT     RVELCMD
    OUT     SONAREN     ; Disable sonar (optional)
    OUT     LCD
    
    CALL    SetupI2C    ; Configure the I2C to read the battery voltage
    CALL    BattCheck   ; Get battery voltage (and end if too low).
    OUT     LCD         ; Display batt voltage on LCD

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
    LOAD    Zero
    OUT     XLEDS       ; clear LEDs once ready to continue

;***************************************************************
;* Main code
;***************************************************************
Main:                   ; Program starts here.
    CALL    StopMotors  ; Reset robot
    OUT     RESETPOS
    LOADI   &B00101101  ; Enable sides sensors (1 & 5) and front sensors (2 & 3)
    OUT     SONAREN
    LOAD    OneFtDist     ; We're using a cutoff distance of 3 feet
    ADD     TwoFeet
    LOADI   OneFtDist
    STORE   DistCutoff
    
    CALL    TryTurning
    LOADI   0
    ;OUT     SONAREN
DieHard:
    LOADI   &HFFFF
    ;OUT     SSEG1
    CALL    ReadSides
    CALL    IsValidReading
    OUT     LCD
    LOAD    Temp
    ;OUT     SSEG2
    JUMP    DieHard
 
Die:                    ; Permadeath (and stops when program is complete)
    CALL    StopMotors
    OUT     SONAREN
    LOAD    DEAD         ; An indication that we are dead
    OUT     SSEG2
Forever:
    JUMP    Forever      ; Do this forever.
DEAD: DW    &HDEAD

;***************************************************************
;* Subroutines
;***************************************************************

First5Bits: EQU &B11111
ReadInput:
    IN      SWITCHES
    AND     First5Bits  ; Look only at 1st 5 bits
    STORE   Dist1       ; Destination 1
    IN      SWITCHES
    SHIFT   -5          ; Bring to front, chopping off 1st 5 bits (destination 1)
    AND     First5Bits  ; Look only at new 1st 5 bits
    STORE   Dist2       ; Destination 2
    IN      SWITCHES
    SHIFT   -10         ; Bring to front, chopping off 1st 10 bits (destination 1 & 2)
    AND     First5Bits  ; Look only at new 1st 5 bits
    STORE   Dist3       ; Destination 3
    RETURN

SideArgs:   DW  0       ; Variable for reading side distances
Error:      DW  50     ; Error to ignore robot width
ReadSides:  
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
    OUT     LCD       ; Out to SSEG1 for testing
    RETURN
Read4:
    LOADI   4           ; Load 4 for output
    OUT     LCD       ; Out to SSEG1 for testing
    RETURN
Read5:
    LOADI   5           ; Load 5 for output
    OUT     LCD       ; Out to SSEG1 for testing
    RETURN
Read6:
    LOADI   6           ; Load 6 for output
    OUT     LCD       ; Out to SSEG1 for testing
    RETURN

Counter:        DW  3  
TryDistValue:   DW  4
FrontCutoff:    DW  1000
TryTurning:             ; Tries to turn until it detects a valid orientation based on side distance
    OUT     RESETPOS    ; Needs to be reworked to incorporate front distance as well
    CALL    TurnMotorsFSlow
TurnLoop45:
    CALL    UpdateMotors
    CALL    Wait1
    LOAD    Counter
    ADDI    -1
    STORE   Counter
    JPOS    TurnLoop45
TurnCheck:
    CALL    ReadSides
    CALL    IsValidReading
    JPOS    TurnLoop45
TurnLoop:
    CALL    UpdateMotors
    CALL    ReadSides
    CALL    IsValidReading
    JNEG    TurnLoop
    IN      DIST3
    OUT     SSEG2
    IN      DIST2
    OUT     SSEG1
    IN      DIST3
    SUB     FrontCutoff
    JPOS    TurnLoop
    
    ;IN      DIST3
    ;OUT     SSEG2
    ;SUB     FrontCutoff
    ;JPOS    TurnLoop
    CALL    BrakeMotors
    RETURN
    

    ;SUB     TryDistValue    ; Check if valid
    ;JZERO   DoneValid       ; Valid Reading
    ;IN      THETA
    ;ADD     DEG90
    ;JPOS    TurnLoop        ; Still not 90 degrees yet
    ;LOAD    TryDistValue
    ;ADDI    2
    ;STORE   TryDistValue    ; Decrement checker by 2 (try 4, then 6, then 8)
    ;SUB     8
    ;JPOS    Failed
    ;JUMP    TryTurning
    
DoneValid:
    RETURN
Failed:
    RETURN
    
TurnUntilValid:     ; Old attempt to turn until a valid reading
    LOAD    FSlow   ; More prone to errors because odd angles
    CALL    TurnMotors
    CALL    DispLCD
    CALL    ReadSides
    
    CALL    IsValidReading
    JNEG    TurnUntilValid ; Loop until something close by
    CALL    StopMotors
    RETURN

FtAmount:   DW  0
FtCount:    DW  0
GetFeet:                ; Converts AC sensor reading to feet
    STORE   FtAmount
    LOAD    Zero
    STORE   FtCount
FeetLoop:
    LOAD    FtCount
    ADDI    1
    STORE   FtCount        ; Store feet counted
    LOAD    FtAmount
    SUB     OneFtDist
    STORE   FtAmount
    JPOS    FeetLoop    ; Still positive ? Then another foot long
    LOAD    FtCount        ; Store output value in AC to return
    RETURN    

DispLCD:
    LOAD    Temp
    OUT     LCD
    RETURN
    
MoveMotorsBSlow:
    LOADI   0
    SUB     FSlow
    JUMP    MoveMotorsAC
MoveMotorsFSlow:
    LOAD    FSlow
    JUMP    MoveMotorsAC
MoveMotors:
    LOAD    MotorSpeed
    JUMP    MoveMotorsAC
StopMotors:             ; Stops all motors
    LOAD    Zero
MoveMotorsAC:            ; Sets motor velocity to AC
    STORE   VelL
    STORE   VelR
    JUMP    UpdateMotors

TurnMotorsFSlow:
    LOAD    FSlow
    JUMP    TurnMotorsAC
TurnMotorsBSlow:
    LOADI   0
    SUB     FSlow
    JUMP    TurnMotorsAC
TurnMotors:             ; Sets motor velocity to AC (turning)
    LOAD    MotorSpeed
TurnMotorsAC:
    STORE   VelL
    LOAD    Zero
    SUB     VelL
    STORE   VelR
    JUMP    UpdateMotors

BrakeMotors:
    LOADI   0
    SUB     VelL
    STORE   VelL
    LOADI   0
    SUB     VelR
    STORE   VelR
    CALL    UpdateMotors
    LOADI   4
    CALL    WaitAC
    LOADI   0
    STORE   VelR
    STORE   VelL
    JUMP    UpdateMotors
    
UpdateMotors:
    LOAD    VelL
    OUT     LVELCMD
    LOAD    VelR
    OUT     RVELCMD
    RETURN
    
Mod360:
    JNEG    Add360
Sub360:
    SUB     DEG360
    JPOS    Sub360
Add360:
    ADD     DEG360
    JNEG    Add360
    RETURN

AbsArgs:    DW  0
AbsoluteVal:
    JNEG    OppositeSign
    RETURN
OppositeSign:           ; Returns with AC as (-AC)
    STORE   AbsArgs
    LOAD    Zero
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
    LOAD    Four
    OUT     BEEP        ; start beep sound
    CALL    GetBattLvl  ; get the battery level
    OUT     SSEG1       ; display it everywhere
    OUT     SSEG2
    OUT     LCD
    LOAD    Zero
    ADDI    -1          ; 0xFFFF
    OUT     LEDS        ; all LEDs on
    OUT     XLEDS
    CALL    Wait1       ; 1 second
    Load    Zero
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
    LOAD    Zero        ; 0x0000 (A/D port 0, no increment)
    OUT     I2C_DATA    ; to I2C_DATA register
    OUT     I2C_RDY     ; start the communication
    CALL    BlockI2C    ; wait for it to finish
    RETURN

BlockI2C:               ; Subroutine to block until I2C device is idle
    LOAD    Zero
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
    LOAD    Zero
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

Dest1:      DW  0
Dest2:      DW  0
Dest3:      DW  0

Temp:       DW  0   ; Temporary Variable
Temp2:      DW  0   ; Temporary Variable 2
MotorSpeed: DW  0   ; Motor Speed
WaitTime:   DW  0   ; Input to Wait
DistCutoff: DW  0   ; Distance Cutoff
DistLeft:   DW  0
DistRight:  DW  0

VelL:       DW  0
VelR:       DW  0

;OUR VARIABLES
X1:         DW  0
X2:         DW  0
Y1:         DW  0
Y2:         DW  0
BOT:        DW  8
TOP:        DW  10
X7:         DW  0
Y7:         DW  0

A:          DW  0
OneFtDist:  DW  304 ; roughly 304.8 mm per ft (but ticks are ~1.05 mm, so about 290.3 ticks)
divsave:    DW  0

B:          DW  0
sav:        DW  0

;***************************************************************
;* Constants
;* (though there is nothing stopping you from writing to these)
;***************************************************************
NegOne:     DW  -1
Zero:       DW  0
One:        DW  1
Two:        DW  2
Three:      DW  3
Four:       DW  4
Five:       DW  5
Six:        DW  6
Seven:      DW  7
Eight:      DW  8
Nine:       DW  9
Ten:        DW  10

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
