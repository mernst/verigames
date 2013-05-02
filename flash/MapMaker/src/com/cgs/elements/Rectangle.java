package com.cgs.elements;

//keep track of original values (doubles) and normalized ones (ints)
public class Rectangle {

	public int x;
	public int y;
	public double width;
	public double height;
	
	public double finalXPos;
	public double finalYPos;
	
	public Rectangle()
	{
		x = 0;
		y = 0;
		width = 0;
		height = 0;
	}
	
	public Rectangle(int _x, int _y, int _width, int _height)
	{
		x = _x;
		y = _y;
		width = _width;
		height = _height;
	}
	
	public String toAttributeString()
	{
		String attributeString = "top=\"" + finalYPos + "\""
									+ " left=\"" + finalXPos + "\""
									+ " bottom=\"" + (finalYPos+height) + "\""
									+ " right=\"" + (finalXPos+width) + "\"";
		
		return attributeString;
	}
	
	public String toString()
	{
		return x+","+y+" "+width+","+height;
	}
};
