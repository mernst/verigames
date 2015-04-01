import sys, os
from xml.dom.minidom import parse, parseString
import  datetime, time
import pymongo
import gridfs
import bson
from pymongo import Connection
from pymongo import database
from bson.objectid import ObjectId
from bson import json_util
import json

#description file looks like:
#<files version='0' property="ostrusted" >
#<file name='L10823_V16' widgets="1" links="1" conflicts="1"/>
#</files>


def addLevelToDB(infile, description_file):
	index = infile.rfind('/')
	infileroot = infile[index+1:]
	descriptionxml = parse(description_file)
	fileElem = descriptionxml.getElementsByTagName('files')
	version = fileElem[0].getAttribute("version")
	property = fileElem[0].getAttribute("property")

	client = Connection('api.paradox.verigames.com', 27017)
	db = client.game2api
	description = None
	print "finding files"
	files = descriptionxml.getElementsByTagName('file')
	for file in files:
		levelObj = {"version": version, "property": property, "current_score": "0", "serve": "1", "revision":"1", "leader": "New"}
		filename = file.getAttribute("name")
		levelObj["name"] = filename
		if filename == infileroot:
			description = file
			break
			fddfsf
	if description != None:
		levelObj["levelID"] = str(addFile(db, infile+".zip"))
		levelObj["assignmentsID"] = str(addFile(db, infile+"Assignments.zip"))
		levelObj["layoutID"] = str(addFile(db, infile+"Layout.zip"))
		
		base_collection = db.BaseLevels
		level_collection = db.ActiveLevels
		
		levelObj["target_score"] = description.getAttribute("score")
		levelObj["conflicts"] = description.getAttribute("constraints")
		levelObj["added_date"] = time.strftime("%c")
		levelObj["last_update"] = str(int(time.mktime(datetime.datetime.now().utctimetuple())))
		base_collection.save(levelObj)
		level_collection.save(levelObj)
		print 'saved file'
def addFile(db, fileName):
	print fileName
	fileobj = open(fileName, 'rb')
	contents = fileobj.read()
	fs = gridfs.GridFS(db)
	id = fs.put(contents)
	return id

def addDirectoryToDB(indir, description_file):
	#open description file, loop through entries, if you can find the entry file upload it
	descriptionxml = parse(description_file)
	files = descriptionxml.getElementsByTagName('file')
	for file in files:
		name = file.getAttribute("name")
		print 'adding ' + name
		if os.path.exists(indir + os.path.sep + name + '.zip'):
			addLevelToDB(indir + os.path.sep + name, description_file)
		else:
			print indir + os.path.sep + name + '.zip' + ' not found'
	
### Command line interface ###
if __name__ == "__main__":
	if (len(sys.argv) < 3) or (len(sys.argv) > 3):
		print ('\n\nUsage: %s input_file description_file\n\n  input_file: name of base json '
			'file, omitting ".zip" extension\n  description_file : zip file with file entry describing file') % (sys.argv[0], sys.argv[0])
		quit()

	infile = sys.argv[1]
	description_file = sys.argv[2]
	
	# there seems to be ownership issues when files added through python can't be deleted from java. so do it here, but really make sure you want to remove everything....
	'''
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.game2api
	level_collection = db.Levels
	level_collection.remove()
	base_collection = db.BaseLevels
	base_collection.remove()
	scored_collection = db.ScoredLevels
	scored_collection.remove()
	solved_collection = db.GameSolvedLevels
	solved_collection.remove()
	'''
	if os.path.isdir(infile):
		addDirectoryToDB(infile, description_file)
	else:
		addLevelToDB(infile, description_file)