localize:
	OUT RESETPOS
	CALL forwardTilWall
	CALL stopBot
	CALL turnLeft
	CALL stopBot
	
	OUT RESETPOS
	CALL forwardTilWall
	CALL stopBot
	CALL turnLeft
	CALL stopBot

	OUT RESETPOS
	CALL forwardTilWall
	CALL stopBotGetdistanceA
	CALL turnLeft
	CALL stopBot
	OUT RESETPOS
	
	CALL forwardTilWall
	CALL stopBotGetdistanceB
	CALL turnLeft
	CALL stopBot
	OUT RESETPOS	
	
	LOAD distance1
	OUT SSEG1
	LOAD distance2
	OUT SSEG2
	
	RETURN


	
forwardTilWall:
	LOADI &b00000100
	OUT SONAREN
	IN DIST2		;read forward sensor
	ADDI -200		;we will say once 200mm to wall we need to stop
	JPOS Forward	;if not at wall continue moving forward
	RETURN			;once at wall you need to return
	
Forward:
	LOADI 300
	OUT RVELCMD
	OUT LVELCMD
	JUMP forwardTilWall
	
turnLeft:
	IN THETA
	ADDI -90
	JZERO retEarly	;no need to overshoot. if at 90 return out of subroutine before setting wheel velocity 
	LOADI 100
	OUT RVELCMD
	LOADI -100
	OUT LVELCMD
	JNEG turnLeft	;if not at 90 degree continue moving
	JPOS turnLeft  ;if not at 90 degree continue moving

retEarly:
	RETURN
	
stopBot:
	LOADI &b00000000
	OUT SONAREN
	LOADI 0
	OUT RVELCMD
	OUT LVELCMD
	RETURN
	
stopBotGetdistanceA:
	LOADI &b00000000
	OUT SONAREN
	LOADI 0
	OUT RVELCMD
	OUT LVELCMD
	IN XPOS
	STORE distance1
	RETURN
	
stopBotGetdistanceB:
	LOADI &b00000000
	OUT SONAREN
	LOADI 0
	OUT RVELCMD
	OUT LVELCMD
	IN XPOS
	STORE distance2
	RETURN

;;Will input the massive if statements here wednesday
	
	
distance1:		dw 0	;first distance travelled
distance2:      dw 0	;second distance travelled
