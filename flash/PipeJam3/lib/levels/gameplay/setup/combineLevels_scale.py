import os

execfile('../../util.py')

all_files = os.listdir(os.path.dirname(os.path.realpath(__file__)))

# scale a layout file by the given factor
def scale_layout(filename, scale_factor):
	lo_x = lo_y = 1e100
	hi_x = hi_y = -1e100

	with open(filename, 'r') as fin:
		layout_obj = json.load(fin)
		for node_id in layout_obj['layout']['vars']:
			coords = layout_obj['layout']['vars'][node_id]
			try:
				new_x = float(coords['x']) * scale_factor
				coords['x'] = new_x
				lo_x = min(lo_x, new_x)
				hi_x = max(hi_x, new_x)
			except Exception as e:
				pass
			try:
				new_y = float(coords['y']) * scale_factor
				coords['y'] = new_y
				lo_y = min(lo_y, new_y)
				hi_y = max(hi_y, new_y)
			except Exception as e:
				pass
		if layout_obj['layout'].has_key('bounds'):
			layout_obj['layout']['bounds'] = [lo_x, lo_y, hi_x, hi_y]

	with open(filename, 'w') as fout:
		json_dump(layout_obj, fout)

#scaleInfo = [("p_000050_00000000Layout.json", 5), ("p_000250_00000000Layout.json", 5), ("p_0001200_00000000Layout.json", 3), ("p_000140_00000000Layout.json", 6), ("p_000200_00000000Layout.json", 6), ("p_000084_00000000Layout.json", 6)]
scaleInfo = []

for info in scaleInfo:
 scale_layout(info[0], info[1])


files = []
for file in all_files:
    name, ext = os.path.splitext(file)

    if ext == '.json' and not name.endswith('Assignments') and not name.endswith('Layout'):
        files.append(name)

combine_levels_all('../gameplay', files)
