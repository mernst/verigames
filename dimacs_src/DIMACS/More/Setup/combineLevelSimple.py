import sys

FILES = ["p_000077_00000000","p_000087_00000000","p_000100_00000000","p_000186_00000000","p_000191_00000000","p_000200_00000000"]

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
