#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os, sys, re
from xml.dom.minidom import parse, parseString
from xml.dom.minidom import getDOMImplementation
import pipejamDB


def replace(file, pattern, subst):
    # Read contents from file as a single string
    file_handle = open(file, 'r')
    file_string = file_handle.read()
    file_handle.close()

    # Use RE package to allow for replacement (also allowing for (multiline) REGEX)
    file_string = (re.sub(pattern, subst, file_string))

    # Write contents to file.
    # Using mode 'w' truncates the file.
    file_handle = open(file, 'w')
    file_handle.write(file_string)
    file_handle.close()

### Main function ###
def separateLevels(infile, outdirectory, fileMap):
	allxml = parse(infile)
	worlds = allxml.getElementsByTagName('world')
	wx = worlds[0]
	
	# Gather all levels, visit each, generate a unique id, wrap in a world element and save it as a separate file
	# also, make sure all id and name attributes don't contain periods. (As a packaged class might.)
	for level in wx.getElementsByTagName('level'):
		#get levelID from RA
		id = pipejamDB.getNewLevelID()
		level.setAttribute('id', str(id))
		
		levelname = level.getAttribute('name')

		impl = getDOMImplementation()
		newdoc = impl.createDocument(None, "world", None)
		world_element = newdoc.documentElement
		world_element.appendChild(level)
		writexml = open(outdirectory + '/' + id + '.xml','w')
		world_element.writexml(writexml)
		writexml.close()

		#is there a period?
		if levelname.find(".") != -1:
			newlevelname = levelname.replace(".", "_")
			replace(outdirectory + '/' + id + '.xml',levelname, newlevelname)

		fileMap.write('<level name="'+level.getAttribute('name')+'" id="'+id+'"/>')


### Command line interface ###
if __name__ == "__main__":
	if (len(sys.argv) < 2) or (len(sys.argv) > 3):
		print ('\n\nUsage: %s input_file output_directory\n\n  input_file: name of classic XML '
			'file to be parsed, omitting ".xml" extension\n  output_directory: output directory. Must exist.') % (sys.argv[0], sys.argv[0])
		quit()
	if len(sys.argv) == 3:
		outdirectory = sys.argv[2]
	else:
		outdirectory = sys.argv[1]
	infile = sys.argv[1]
	print 'calling separateLevels'
	fileMap = open(outdirectory + '/'+'filemap1.xml','w')

	separateLevels(infile, outdirectory, fileMap)