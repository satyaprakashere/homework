value record Point2D(int x, int y) {}
value record Rectangle(Point2D p1, Point2D p2) {}

void main() {
	IO.println("Hello from Project Valhalla!!");
	IO.println(new Point2D(10, 20));
	
	var p1 = new Point2D(1, 2);
	var p2 = new Point2D(1, 2);
	
	IO.println(new Rectangle(p1, p2));
		
	IO.println(p1 == p2);
}
