#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os, sys, re
import fileinput
#import pipejamDB


### Main function ###
def separateLevels(infile, outdirectory, fileMap, useRA):
	print ('parsing xml')
	count = 1
	writeLines = False
	writeNextLine = False
	isLevel = False
	nextID = 1
	readLinkedVarIDs = False
	inLinkedVarIDs = False
	linkedVarIDs = []
	#get levelID from RA
	if useRA:
		id = pipejamDB.getNewLevelID()
	else:
		id = str(nextID)
	nextID = nextID + 1
	levelFile = open(outdirectory + '/'+id+'.xml','w')
	levelFile.write('<world version="3">\n')

	for line in fileinput.input(infile):
			
		if line.find('linked-varIDs') != -1:
			inLinkedVarIDs = not inLinkedVarIDs;
			if inLinkedVarIDs == False:
				linkedVarIDs.append(line)
				readLinkedVarIDs = True
			
		if inLinkedVarIDs == True and readLinkedVarIDs == False:
			linkedVarIDs.append(line)
			
		if readLinkedVarIDs == False:
			continue
			
		if line.find('<level') != -1:
			for item in linkedVarIDs:
				levelFile.write("%s" % item)
			nameStart = line.find('name="') + 6
			nameEnd = line.find('"', nameStart)
			name = line[nameStart:nameEnd]
			fileMap.write('<level name="'+name+'" id="'+id+'"/>')
			writeLines = True
			writeNextLine = True

			print (name)
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
			if useRA:
				id = pipejamDB.getNewLevelID()
			else:
				id = str(nextID)
			nextID = nextID + 1
			nameStart = line.find('name="') + 6
			nameEnd = line.find('"', nameStart)
			name = line[nameStart:nameEnd]
			fileMap.write('<level name="'+name+'" id="'+id+'"/>')

			levelFile = open(outdirectory + '/'+id+'.xml','w')
			levelFile.write('<world version="3">\n')
		 
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
	print ('calling separateLevels')
	fileMap = open(outdirectory + '/'+'filemap.xml','w')

	separateLevels(infile, outdirectory, fileMap, False)