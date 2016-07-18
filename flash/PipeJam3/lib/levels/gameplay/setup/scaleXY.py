import sys, json

if len(sys.argv) != 3:
	print 'Usage: %s filename scale_factor_float' % argv[0]
	quit()
scale_factor = float(sys.argv[2])
layout_f = sys.argv[1]
with open(layout_f, 'r') as fin:
	layout_obj = json.load(fin)
	for group_key in layout_obj.get('layout', {}):
		if group_key == "vars":
			for key in layout_obj['layout'][group_key]:
				thing = layout_obj['layout'][group_key][key]
				try:
					thing['x'] = float(thing['x']) * scale_factor
				except Exception as e:
					pass
				try:
					thing['y'] = float(thing['y']) * scale_factor
				except Exception as e:
					pass
		else:
			for i in range(0, len(layout_obj['layout'][group_key])):
				layout_obj['layout'][group_key][i] = float(layout_obj['layout'][group_key][i]) * scale_factor
with open(layout_f, 'w') as fout:
	fout.write(json.dumps(layout_obj, indent=2, sort_keys=True))
