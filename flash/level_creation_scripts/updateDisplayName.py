import json, os, sys
import _util

def update_display_name(level_json):
	level_obj = json.load(open(level_json))
	new_name = "jarvis" ## switch to using display name in future
	##level_obj['file'] = new_name ##to be updated with correct name in future

	_util.json_dump(level_obj, open(level_json, 'w'))


if len(sys.argv) != 2:
    print 'Usage: %s prefix' % sys.argv[0]
    sys.exit(-1)
	
update_display_name(sys.argv[1])
