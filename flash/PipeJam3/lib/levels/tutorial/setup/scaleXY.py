import sys, json

if len(sys.argv) != 3:
	print 'Usage: %s filename scale_factor_float' % sys.argv[0]
	quit()

layout_f = sys.argv[1]
scale_factor = float(sys.argv[2])

lo_x = lo_y = 1e100
hi_x = hi_y = -1e100

with open(layout_f, 'r') as fin:
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

with open(layout_f, 'w') as fout:
	fout.write(json.dumps(layout_obj, indent=2, sort_keys=True))
