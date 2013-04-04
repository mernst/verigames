package com.cgs.elements;

//keep track of original values (doubles) and normalized ones (ints)
public class Rectangle {

	public int x;
	public int y;
	public double width;
	public double height;
	
	//use these to keep original values
	public double dx;
	public double dy;
	public double dwidth;
	public double dheight;
	
	public Rectangle()
	{
		x = 0;
		y = 0;
		width = 0;
		height = 0;
		dx = 0;
		dy = 0;
		dwidth = 0;
		dheight = 0;
	}
	
	public Rectangle(int _x, int _y, int _width, int _height)
	{
		x = _x;
		y = _y;
		width = _width;
		height = _height;
	}
	
	public Rectangle(double _x, double _y, double _width, double _height)
	{
		dx = _x;
		dy = _y;
		dwidth = _width;
		dheight = _height;
		x = (int)dx;
		y = (int)dy;
		width = (int)dwidth;
		height = (int)dheight;
	}
	
	public String toString()
	{
		return x+","+y+" "+width+","+height;
	}
};
