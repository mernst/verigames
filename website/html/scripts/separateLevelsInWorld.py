#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os, sys, re
import fileinput
import pipejamDB


### Main function ###
def separateLevels(infile, outdirectory, fileMap):
	print 'parsing xml'
	count = 1
	writeLines = False
	writeNextLine = False
	isLevel = False
	#get levelID from RA
	id = pipejamDB.getNewLevelID()
	levelFile = open(outdirectory + '/'+id+'.xml','w')
 	levelFile.write('<world>')

	for line in fileinput.input(infile):
		if line.find('<level') != -1:
			
			nameStart = line.find('name="') + 6
			nameEnd = line.find('"', nameStart)
			name = line[nameStart:nameEnd]
			fileMap.write('<level name="'+name+'" id="'+id+'"/>')
			writeLines = True
			writeNextLine = True

			print name
			line = line.replace(".", "_")
			line = line.replace("$", "__")
			line = line.replace("-", "_")

		elif line.find('<board') != -1:
			line = line.replace(".", "_")
			line = line.replace("$", "__")

		elif line.find('<node') != -1:
			line = line.replace(".", "_")
			line = line.replace("$", "__")

		elif line.find('<edge-set') != -1:
			line = line.replace(".", "_")
			line = line.replace("$", "__")


		elif line.find('<layout') != -1:
			writeLines = False
			writeNextLine = False

		elif line.find('</layout') != -1:
			writeNextLine = True

		elif line.find('</level') != -1:
			levelFile.write(line)
			writeLines = False
			levelFile.write('</world>')
			levelFile.flush()
			levelFile.close()
			count+=1
			#get levelID from RA
			id = pipejamDB.getNewLevelID()

			nameStart = line.find('name="') + 6
			nameEnd = line.find('"', nameStart)
			name = line[nameStart:nameEnd]
			fileMap.write('<level name="'+name+'" id="'+id+'"/>')

			levelFile = open(outdirectory + '/'+id+'.xml','w')
			levelFile.write('<world>')
		 
		if writeLines:
			levelFile.write(line)

		if writeNextLine:
			writeLines = True




	levelFile.close()




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
	fileMap = open(outdirectory + '/'+'filemap.xml','w')

	separateLevels(infile, outdirectory, fileMap)