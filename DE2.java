package pack;

import java.util.ArrayList;

public class DE2 {
	
	int x, y, x1, y1, x2, y2, deltaX, deltaY;
	
	public DE2(){
		
	}

	public ArrayList <String> navigateEverywhere(Point start, ArrayList<Point> points){
		ArrayList <String> directions = new ArrayList <String> ();
		for (Point point : points){
			directions.addAll( navigate(start,point) );
			start = point;
		}
		return directions;
	}
	
	
	public ArrayList <String> navigate(Point start, Point finish){
		
		//setup
		ArrayList <String> directions = new ArrayList <String> ();
		x1 = start.x;
		y1 = start.y;
		x = x1;
		y = y1;
		x2 = finish.x;
		y2 = finish.y;

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
		Point start = new Point(4,2);
		Point finish = new Point(6,4);
		dir = bot.navigate(start,finish);
		
		
		ArrayList<Point> points = new ArrayList<Point>();
		points.add(new Point(1,1));
		points.add(finish);
		points.add(start);
		dir = bot.navigateEverywhere(start,points);
		
		bot.printDirections(dir);
	}

	public static class Point{
		int x, y;
		public Point(int x, int y){
			this.x = x;
			this.y = y;
		}
		
	}
}
