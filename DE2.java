package pack;

import java.util.ArrayList;

public class DE2 {
	
	int x, y, x1, y1, x2, y2, deltaX, deltaY;
	
	public DE2(){
		
	}
	
	public ArrayList <String> navigate(int startX, int startY, int finX, int finY){
		
		//setup
		ArrayList <String> directions = new ArrayList <String> ();
		x1 = startX;
		y1 = startY;
		x = x1;
		y = y1;
		x2 = finX;
		y2 = finY;

		deltaY = y2 - y;
		//navigate vertically
		if (deltaY > 0){ //move north
			//faceNorth();
			directions.addAll(goNorth(deltaY));
		}
		else if (deltaY < 0){ //move south
			//faceSouth();
			directions.addAll(goSouth(deltaY));
		}
		else { //don't move
			
		}

		deltaX = x2 - x;
		//navigate horizontally
		if (deltaX > 0){ //move east
			//faceEast();
			directions.addAll(goEast(deltaX));
		}
		else if (deltaX < 0){ //move west
			//faceWest();
			directions.addAll(goWest(deltaX));
		}
		else { //don't move
			
		}
		
		return directions;
	}

	public void setX(int x){this.x = x;}
	public void setY(int y){this.y = y;}

	public ArrayList <String> goNorth(int delta){
		ArrayList <String> directions = new ArrayList <String> ();

		while (delta != 0 && y != 4){ 
			if (y == 2 && x > 2){ //you will hit the wall if you go north
				directions.addAll(avoidBarrier(2));
			}
			else { 
				//move forward 1 square
				directions.add("north");
				y += 1;
				delta -= 1;
			}
		}
		return directions;
	}

	public ArrayList <String> goEast(int delta){
		ArrayList <String> directions = new ArrayList <String> ();
		
		// checks to see if moving east is a valid operation
		while ( (delta != 0) && ((y < 3 && x != 4) || (y == 3 && x != 5) || (y == 4 && x != 6)) ){
			//move forward 1 square
			directions.add("east");
			x += 1;
			delta -= 1;
		}
		return directions;
	}

	public ArrayList <String> goSouth(int delta){ //delta should be negative
		ArrayList <String> directions = new ArrayList <String> ();
		
		while (delta != 0 && y != 1){ 
			if (y == 3 && x > 2){ //you will hit the wall if you go north
				directions.addAll(avoidBarrier(2));
			} 
			else if (y == 4 && x == 6){ //you will hit the wall if you go north
				if (delta < -1) {
					directions.addAll(avoidBarrier(2));
				}
				else if (delta == -1) {
					directions.addAll(avoidBarrier(5));
				}
			}
			else { 
				//move forward 1 square
				directions.add("south");
				y -= 1;
				delta += 1;
			}
		}
		return directions;
	}

	public ArrayList <String> goWest(int delta){ //delta should be negative
		ArrayList <String> directions = new ArrayList <String> ();
		while (delta != 0 && x != 1){
			//move forward 1 square
			directions.add("west");
			x -= 1;
			delta += 1;
		}
		return directions;
	}

	public ArrayList <String> avoidBarrier(int columnToGoTo){
		ArrayList <String> directions = new ArrayList <String> ();
		while (x != columnToGoTo){
			//face west and move forward 1 square
			directions.add("west");
			x -= 1;
		}
		return directions;
	}
	
	public void printDirections(ArrayList <String> directions){
		for (String dir : directions){
			System.out.println(dir);
		}
	}
	
	public static void main(String [] args){
		//test individual functions
		ArrayList <String> dir;
		DE2 bot = new DE2();
		bot.setX(6);
		bot.setY(4);
		dir = bot.goSouth(-1);
		
		//testing main function
		dir = bot.navigate(4, 2, 6, 4);
		
		bot.printDirections(dir);
	}

}
