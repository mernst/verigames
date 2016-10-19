
f = open('p_000050_00000000Layout.json', 'r')


layout = eval(f.read())

variables = layout["layout"]["vars"]

for key in variables.keys():
	variable = variables[key];
	variable["x"] = variable["x"] * 1.5;
	variable["y"] = variable["y"] * 1.5;


layout["layout"]["vars"] = variables

print layout