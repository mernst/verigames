import json, os, sys
import _util
from nltk.corpus import wordnet

def update_display_name(level_json):
	level_obj = json.load(open(level_json))
	new_name = "jarvis" ## switch to using display name in future
	##level_obj['file'] = new_name ##to be updated with correct name in future

	## do this wordnet stuff in test file somewhere it can be run on it's own and iterated on quickly
	## get wordnet or some sort of dictionary, use two adjectives followed by noun.

	## take pieces of hash - find closest adjective to converted index for first two thirds, then same for noun for last third?
	

	_util.json_dump(level_obj, open(level_json, 'w'))


if len(sys.argv) != 2:
    print 'Usage: %s prefix' % sys.argv[0]
    sys.exit(-1)
	
update_display_name(sys.argv[1])
