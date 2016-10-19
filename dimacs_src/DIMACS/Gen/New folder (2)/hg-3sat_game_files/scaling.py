
f = open('p_000250_00000000Layout.json', 'r')


layout = eval(f.read())

variables = layout["layout"]["vars"]

xmax = 0
xmin = 1000

ymax = 0
ymin = 1000

for key in variables.keys():
	variable = variables[key];
	xcoord = variable["x"]
	ycoord = variable["y"]

	if xcoord > xmax:
		xmax = xcoord
	if xcoord < xmin:
		xmin = xcoord
	if ycoord > ymax:
		ymax = ycoord
	if ycoord < ymin:
		ymin = ycoord


xmarker = (xmin+xmax)/2
ymarker = (ymin+ymax)/2

for key in variables.keys():
	variable = variables[key];
	xcoord = variable["x"]
	ycoord = variable["y"]


	if xcoord<=xmarker and ycoord<=ymarker:
		variable["x"] = variable["x"] / 2;
		variable["y"] = variable["y"] / 2;
		i = 1
	elif xcoord>=xmarker and ycoord<=ymarker:
		variable["x"] = variable["x"] * 2;
		variable["y"] = variable["y"] / 2;
		i = 2
	elif xcoord<=xmarker and ycoord>=ymarker:
		variable["x"] = variable["x"] / 2;
		variable["y"] = variable["y"] * 2;
		i = 3
	elif xcoord>=xmarker and ycoord>=ymarker:
		variable["x"] = variable["x"] * 2;
		variable["y"] = variable["y"] * 2;
		i = 0


layout["layout"]["vars"] = variables

print layout