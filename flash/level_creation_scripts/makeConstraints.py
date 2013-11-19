#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import sys
import fileinput

class EdgeSet:
	def __init__(self, name, width, editable):
		self.name = name
		self.width = width
		self.editable = editable

### Main function ###
def gatherConstraints(infile, outfile):
	print ('parsing xml')

	edgesets = {}
	varIDToVarIDSetID = {}
	currentStubBoardName = ""
	currentVarIDSetID = ""
	inInput = True
	errorCount = 0
	wideEditableCount = 0
	narrowEditableCount = 0
	wideNoneditableCount = 0
	narrowNoneditableCount = 0
	
	for line in fileinput.input(infile):
			
		if line.find('varID-set') != -1:
			nameStart = line.find('id="') + 4
			nameEnd = line.find('"', nameStart)
			currentVarIDSetID = line[nameStart:nameEnd]
		
		elif line.find('<varID') != -1:
			#find and store name
			nameStart = line.find('id="') + 4
			nameEnd = line.find('"', nameStart)
			varID = line[nameStart:nameEnd]
			varIDToVarIDSetID[varID] = currentVarIDSetID
			
		elif line.find('<board-stub') != -1:
			#find and store name
			nameStart = line.find('name="') + 6
			nameEnd = line.find('"', nameStart)
			currentStubBoardName = line[nameStart:nameEnd]
		
		elif line.find('<stub-input>') != -1:
			inInput = True
		elif line.find('<stub-output>') != -1:
			inInput = False
			
		elif line.find('<stub-connection') != -1:
			#find port name and width
			nameStart = line.find('num="') + 5
			nameEnd = line.find('"', nameStart)
			portName = line[nameStart:nameEnd]
			
			nameStart = line.find('width="') + 7
			nameEnd = line.find('"', nameStart)
			width = line[nameStart:nameEnd]
			
			if width == "narrow":
				narrowNoneditableCount += 1
			else:
				wideNoneditableCount += 1
			name = ""
			if inInput == True:
				name = 'EXT__' + currentStubBoardName + '__XIN__' + portName 
			else:
				name = 'EXT__' + currentStubBoardName + '__XOUT__' + portName 

			edgeSet = EdgeSet(name, width, 'false')
			edgesets[name] = edgeSet
			
		elif line.find('<edge') != -1:
			#find port name and width
			nameStart = line.find('variableID="') + 12
			nameEnd = line.find('"', nameStart)
			variableID = line[nameStart:nameEnd]
			
			
				
			nameStart = line.find('id="') + 4
			nameEnd = line.find('"', nameStart)
			edgeID = line[nameStart:nameEnd]
			
			name = ""
			if int(variableID) < 0:
				name = 'NEG_' + edgeID
			else:
				#update to using varidsetID if this varID is in a set
				if variableID in varIDToVarIDSetID:
					variableID = varIDToVarIDSetID[variableID]
					name = variableID + '_varIDset'
				
			nameStart = line.find('width="') + 7
			nameEnd = line.find('"', nameStart)
			width = line[nameStart:nameEnd]
			
			nameStart = line.find('editable="') + 10
			nameEnd = line.find('"', nameStart)
			editable = line[nameStart:nameEnd]
			
			if width == "narrow":
				if editable == "false":
					narrowNoneditableCount += 1
				else:
					narrowEditableCount += 1
			else:
				if editable == "false":
					wideNoneditableCount += 1
				else:
					wideEditableCount += 1
			
			if not name in edgesets:
				edgeSet = EdgeSet(name, width, editable)
				edgesets[name] = edgeSet
				
			else:
				#check validity of xml
				edgeSet = edgesets[name]
				if edgeSet.width != width or edgeSet.editable != editable:
					#print("error in xml: variableID = " + variableID)
					errorCount += 1
	
	levelFile = open(outfile,'w')
	levelFile.write('<?xml version="1.0" ?>\n')		
	
	mostNumerousCase = 0
	if wideEditableCount > wideNoneditableCount and wideEditableCount > narrowNoneditableCount and wideEditableCount > narrowEditableCount:
			mostNumerousCase = 1
			levelFile.write('<graph version="3" defaultwidth="wide" defaulteditable="true">\n')
	elif wideNoneditableCount > narrowNoneditableCount and wideNoneditableCount > narrowEditableCount:
			mostNumerousCase = 2
			levelFile.write('<graph version="3" defaultwidth="wide" defaulteditable="false">\n')
	elif narrowEditableCount > narrowNoneditableCount:
			mostNumerousCase = 3
			levelFile.write('<graph version="3" defaultwidth="narrow" defaulteditable="true">\n')
	else:
			mostNumerousCase = 4
			levelFile.write('<graph version="3" defaultwidth="narrow" defaulteditable="false">\n')
			
	#turn this off for the time being. Cuts file size some, but the zip file is only slightly smaller, so might not be worth it?
	mostNumerousCase = 0
	
	print (wideEditableCount, wideNoneditableCount, narrowNoneditableCount, narrowEditableCount)
	for key, edgeset in edgesets.items():
		if edgeset.width == "wide" and edgeset.editable == "true":
			currentCase = 1
		elif edgeset.width == "wide" and edgeset.editable == "false":
			currentCase = 2
		elif edgeset.width == "narrow" and edgeset.editable == "true":
			currentCase = 3
		else:
			currentCase = 4
		if currentCase != mostNumerousCase:	
			levelFile.write('<box id="' + edgeset.name + '" width="'+ edgeset.width +'" editable="'+ edgeset.editable +'"/>\n')

	levelFile.write('</graph>\n')

	levelFile.close()
	
	print (errorCount)


### Command line interface ###
if __name__ == "__main__":
	if (len(sys.argv) < 2) or (len(sys.argv) > 3):
		print ('\n\nUsage: %s input_file outfile\n\n  input_file: name of classic XML '
			'file to be parsed\n  outfile: output file.') % (sys.argv[0], sys.argv[0])
		quit()
		
	infile = sys.argv[1]
	outfile = sys.argv[2]
	print ('calling gatherConstraints')

	gatherConstraints(infile, outfile)