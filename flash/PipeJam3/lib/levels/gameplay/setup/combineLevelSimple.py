import sys
import os

allFiles = os.listdir(os.path.dirname(os.path.realpath(__file__)))
FILES = []
for file in allFiles:
	name = file.split(".")[0]
	
	if name != "combineLevelSimple" and name!= "extractLevelSimple" and name != "layout" and name != "scaleXY":
		name = name.split("Layout")[0]
		name = name.split("Assignments")[0]

		FILES.append(name)

FILES = list(set(FILES))

print FILES



def combineLevels(files):
	lines = '{"levels":[\n'
	for i, file in enumerate(files):
		if i > 0:
			lines += ',\n'
		for line in open(file):
			linestr = line.rstrip()
			lines += linestr + '\n'
	lines += ']}'
	return lines

open('../gameplay.json', 'w').writelines(combineLevels([fn + '.json' for fn in FILES]))
open('../gameplayAssignments.json', 'w').writelines(combineLevels([fn + 'Assignments.json' for fn in FILES]))
open('../gameplayLayout.json', 'w').writelines(combineLevels([fn + 'Layout.json' for fn in FILES]))
