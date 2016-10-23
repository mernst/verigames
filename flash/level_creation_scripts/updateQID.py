import hashlib, json, os, sys
import _util

LEVEL_KEYS = {
	'qid': False,
	'id': False,
	'file': True,
	'version': True,
	'scoring': True,
	'default': True,
	'groups': True,
	'variables': True,
	'cut_edges': True,
	'constraints': True,
}

LAYOUT_KEYS = {
	'qid': False,
	'layout': True,
}

ASSIGNMENTS_KEYS = {
	'qid': False,
	'assignments': True,
}



def process_obj(file_obj, keys):
	for key, val in file_obj.iteritems():
		if not keys.has_key(key):
			raise RuntimeError('Unexpected key %s.' % key)

	new_obj = {}
	for key, use in keys.iteritems():
		if not file_obj.has_key(key):
			raise RuntimeError('Missing key %s.' % key)
		
		if use:
			new_obj[key] = file_obj[key]

	return json.dumps(new_obj, sort_keys=True)

def update_qid(prefix):
	level_obj = json.load(open(prefix + '.json'))
	layout_obj = json.load(open(prefix + 'Layout.json'))
	assignments_obj = json.load(open(prefix + 'Assignments.json'))

	str_rep = process_obj(level_obj, LEVEL_KEYS) + process_obj(layout_obj, LAYOUT_KEYS) + process_obj(assignments_obj, ASSIGNMENTS_KEYS)
	hash = hashlib.md5(str_rep)

	new_qid = hash.hexdigest()
	new_id = 'h_' + hash.hexdigest()[0:14]

	level_obj['id'] = new_id
	level_obj['qid'] = layout_obj['qid'] = assignments_obj['qid'] = new_qid

	os.remove(prefix + '.json')
	os.remove(prefix + 'Layout.json')
	os.remove(prefix + 'Assignments.json')

	out_filename = os.path.dirname(prefix) + '/' + ''.join([c for c in new_id.replace(' ', '_') if c.isalnum() or c == '_'])

	_util.json_dump(level_obj, open(out_filename + '.json', 'w'))
	_util.json_dump(layout_obj, open(out_filename + 'Layout.json', 'w'))
	_util.json_dump(assignments_obj, open(out_filename + 'Assignments.json', 'w'))
	


if len(sys.argv) != 2:
    print 'Usage: %s prefix' % sys.argv[0]
    sys.exit(-1)
	
update_qid(sys.argv[1])
