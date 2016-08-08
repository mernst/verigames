import json

# dump JSON in a nice format
def json_dump(obj, fp):
	json.dump(obj, fp, indent=2, separators=(',',': '), sort_keys=True)
	fp.write('\n')



# combine levels into one array
def combine_levels(outfilename, infilenames):
	levels = []

	for infilename in infilenames:
		with open(infilename, 'r') as infile:
			level = json.load(infile)
			levels.append(level)

	levels_obj = {}
	levels_obj['levels'] = levels

	with open(outfilename, 'w') as outfile:
		json_dump(levels_obj, outfile)

# combine all three files for levels based on prefix
def combine_levels_all(outprefix, inprefixes):
	combine_levels(outprefix + '.json', [pref + '.json' for pref in inprefixes])
	combine_levels(outprefix + 'Assignments.json', [pref + 'Assignments.json' for pref in inprefixes])
	combine_levels(outprefix + 'Layout.json', [pref + 'Layout.json' for pref in inprefixes])
