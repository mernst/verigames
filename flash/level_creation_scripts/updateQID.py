import hashlib, json, os, sys
import _util

KEY_USE       = 0 # must be present, used in checksum
KEY_SKIP      = 1 # must be present, not used in checksum
KEY_OPTIONAL  = 2 # does not need to be present

LEVEL_KEYS = {
	'id': KEY_SKIP,
	'version': KEY_USE,
	'qid': KEY_SKIP,
	'display_name': KEY_OPTIONAL,
	'comments': KEY_OPTIONAL,
	'file': KEY_USE,
	'scoring': KEY_USE,
	'default': KEY_USE,
	'groups': KEY_USE,
	'variables': KEY_USE,
	'cut_edges': KEY_USE,
	'constraints': KEY_USE,
}

LAYOUT_KEYS = {
	'id': KEY_SKIP,
	'layout': KEY_USE,
}

ASSIGNMENTS_KEYS = {
	'id': KEY_SKIP,
	'assignments': KEY_USE,
}



def process_obj(file_obj, keys):
	for key, val in file_obj.iteritems():
		if not keys.has_key(key):
			raise RuntimeError('Unexpected key %s.' % key)

	new_obj = {}
	for key, use in keys.iteritems():
		if use == KEY_OPTIONAL:
			continue

		if not file_obj.has_key(key):
			raise RuntimeError('Missing key %s.' % key)
		
		if use == KEY_USE:
			new_obj[key] = file_obj[key]

	return json.dumps(new_obj, sort_keys=True)

def update_qid(prefix):
	level_obj = json.load(open(prefix + '.json'))
	layout_obj = json.load(open(prefix + 'Layout.json'))
	assignments_obj = json.load(open(prefix + 'Assignments.json'))

	str_rep = process_obj(level_obj, LEVEL_KEYS) + process_obj(layout_obj, LAYOUT_KEYS) + process_obj(assignments_obj, ASSIGNMENTS_KEYS)
	hash = hashlib.md5(str_rep)

	new_qid = hash.hexdigest()
	new_name = 'h_' + hash.hexdigest()[0:14]

	level_obj['display_name'] = new_name  ##will be removed when update display name switches over
	level_obj['id'] = level_obj['qid'] = layout_obj['id'] = assignments_obj['id'] = new_qid

	os.remove(prefix + '.json')
	os.remove(prefix + 'Layout.json')
	os.remove(prefix + 'Assignments.json')

	dirname = os.path.dirname(prefix)
	if dirname != '':
		dirname = dirname + '/'
	out_filename = dirname + ''.join([c for c in new_name.replace(' ', '_') if c.isalnum() or c == '_'])

	_util.json_dump(level_obj, open(out_filename + '.json', 'w'))
	_util.json_dump(layout_obj, open(out_filename + 'Layout.json', 'w'))
	_util.json_dump(assignments_obj, open(out_filename + 'Assignments.json', 'w'))
	


if len(sys.argv) != 2:
    print 'Usage: %s prefix' % sys.argv[0]
    sys.exit(-1)
	
update_qid(sys.argv[1])
