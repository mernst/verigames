package com.cgs.elements;

public class Point
{
	public int x;
	public int y;
	
	public Point()
	{
		x = 0;
		y = 0;
	}
	
	public Point(int _x, int _y)
	{
		x = _x;
		y = _y;
	}
	
	public String toString()
	{
		return x+","+y;
	}
};
