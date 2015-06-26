import sys, os
import json

inputpath = sys.argv[1]
outputfile = sys.argv[2]
version = sys.argv[3]
property = sys.argv[4]
type = sys.argv[5]

pathlen = len(inputpath)

descriptionFile = open(outputfile,'w')
descriptionFile.write('<files version="'+version+'" property="'+property+'" type="'+type+'" >\n')
	
cmd = os.popen('ls %s/*Assignments.json' % inputpath) #find Assignments files in an attempt to find unique named files for each level
for fullfilename in cmd:
	print fullfilename
	startfilenameindex = fullfilename.rfind('/')
	endfilenameindex = fullfilename.rfind('A')
	filename = fullfilename[startfilenameindex+1:endfilenameindex]
	print filename
	numWidgetsStartIndex = filename.find('_')+1
	numWidgetsEndIndex = filename.find('_', numWidgetsStartIndex)
	numWidgets = str(int(filename[numWidgetsStartIndex:numWidgetsEndIndex])) #get rid of leading zeros
	print numWidgets
	score = 0
	#conflicts get updated during game play, links are ignored currently as widgets mostly predict size of level
	descriptionFile.write('<file name="'+filename+'" constraints="'+numWidgets+'"  score="'+str(score)+'"/>\n')

descriptionFile.write('</files>\n')
