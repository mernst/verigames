#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import sys
import fileinput

### Main function ###
def obfuscateNames(infilename, outfilename, mapfilename):
	print ('parsing xml')

	namesToIDs = {}
	nextIDNumber = 1
	
	outfile = open(outfilename,'w')
	
	mapfile = open(mapfilename,'w')
	mapfile.write('<?xml version="1.0" ?>\n')	
	mapfile.write('<names>\n')
	for line in fileinput.input(infilename):
			
		if line.find('name="') != -1:
			nameStart = line.find('name="') + 6
			nameEnd = line.find('"', nameStart)
			name = line[nameStart:nameEnd]
			
			id=""
			if name in namesToIDs:
				id = namesToIDs[name]
			else:
				namesToIDs[name] = nextIDNumber
				id = nextIDNumber
				nextIDNumber += 1
				mapfile.write('<map name="'+name+'" id="'+str(id)+'"/>\n')
				
			lineStart = line[:nameStart]
			lineEnd = line[nameEnd:]
			
			line = lineStart + str(id) + lineEnd
			
		outfile.write(line)


	outfile.close()
	
	mapfile.write('</names>\n')
	outfile.close()



### Command line interface ###
if __name__ == "__main__":
	if (len(sys.argv) < 3) or (len(sys.argv) > 4):
		print ('\n\nUsage: %s input_file outfile mapfile\n\n  input_file: name of classic XML '
			'file to be parsed\n  outfile: output file.\n  mapfile: result xml file mapping names to numbers.') % (sys.argv[0])
		quit()
		
	infilename = sys.argv[1]
	outfilename = sys.argv[2]
	mapfilename = sys.argv[3]
	print ('calling obfuscateNames')

	obfuscateNames(infilename, outfilename, mapfilename)