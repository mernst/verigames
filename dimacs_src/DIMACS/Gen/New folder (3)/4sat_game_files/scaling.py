
f = open('p_000100_00000000Layout.json', 'r')


layout = eval(f.read())

variables = layout["layout"]["vars"]

i = 0
for key in variables.keys():
	variable = variables[key];
	if i == 0:
		variable["x"] = variable["x"] / 2;
		variable["y"] = variable["y"] / 2;
		i = 1
	elif i==1:
		variable["x"] = variable["x"] * 2;
		variable["y"] = variable["y"] / 2;
		i = 2
	elif i==2:
		variable["x"] = variable["x"] / 2;
		variable["y"] = variable["y"] * 2;
		i = 3
	elif i==3:
		variable["x"] = variable["x"] * 2;
		variable["y"] = variable["y"] * 2;
		i = 0


layout["layout"]["vars"] = variables

print layout