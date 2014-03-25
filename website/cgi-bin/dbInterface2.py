#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import sys
import pymongo
import gridfs
import bson
import  datetime, time
import random
from pymongo import Connection
from pymongo import database
from bson.objectid import ObjectId
from bson import json_util
import json
import base64
import requests
import os
from os import listdir
from os.path import isfile, join

def getPlayedTutorials2(playerID):
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.gameapi
	collection = db.CompletedTutorials
	concatList = []
	for level in collection.find({"playerID":playerID}):
		concatList.append(level)

	item = json.dumps(concatList, default=json_util.default)
	return item
	
def reportPlayedTutorial2(messageData):
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.gameapi
	collection = db.CompletedTutorials
	messageObj = json.loads(messageData)
	collection.insert(messageObj)
	return '///success'

def reportPlayerRating2(messageData):
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.gameapi
	collection = db.CompletedLevels
	messageObj = json.loads(messageData)
	collection.insert(messageObj)
	return 'success'

#pass url to localhost:3000
def passURL2(url):
	resp = requests.get('http://localhost:3000' + url)
	responseString = json.dumps(resp.json())
	try:
		#responseString turns out to be a python unicode string, and ActionScript doesn't like the embeded 'u's, so we remove them.
		#responseString = responseString.replace('u\'', "\'")
		#responseString = responseString.replace("\'", "\"")

		if len(responseString) != 0:
			return responseString
		else:
			return 'success'
	except:
		return sys.exc_info()


def passURLPOST2(url, postdata):
	resp = requests.post('http://localhost:3000' + url, data=postdata, headers = {'content-type': 'application/json'})
	responseString = json.dumps(resp.json())

	if len(responseString ) != 0:
		return responseString 
	else:
		return 'success'

def getActiveLevels2():
	try:
		client = Connection('api.flowjam.verigames.com', 27017)
		db = client.game2api
		collection = db.Levels
		concatList = []
		for level in collection.find():
			concatList.append(level)

		item = json.dumps(concatList, default=json_util.default)
		return  item
	except:
		return sys.exc_info()


def getFile2(fileID):
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.game2api
	fs = gridfs.GridFS(db)
	f = fs.get(ObjectId(fileID)).read()
	encoded = base64.b64encode(f)
	return encoded

def getFile2NonEncoded(fileID):
	try:
		#fileObj = json.loads(jsonFileObjStr)
		#fileID = fileObj['fileID']
		#filename = fileObj['filename']
		client = Connection('api.flowjam.verigames.com', 27017)
		db = client.game2api
		fs = gridfs.GridFS(db)
		f = fs.get(ObjectId(fileID)).read()

		with open("/tmp/"+fileID+".zip", 'w') as file1:
			file1.write(f)
			file1.flush()
			os.fsync(file1)

		return "success"
	except:
		e = sys.exc_info()
		return '<html><head/><body><p>' + str(e) + ' Download failed.</p><a href="http://flowjam.verigames.com/game/robots.html">Go back to robots page</a></body></html>'


def submitLevel2(messageData, fileContents):
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.game2api
	fs = gridfs.GridFS(db)
	messageObj = json.loads(messageData)
	decoded = base64.b64decode(fileContents)
	newAssignmentsID = str(fs.put(decoded))
	previousAssignmentsID = messageObj["assignmentsID"]
	messageObj["assignmentsID"] = str(newAssignmentsID)
	collection = db.Solvers
	id = collection.insert(messageObj)
	#mark served level as updated if score is higher than current
	collection = db.Levels
	levelID = messageObj["levelID"]
	for level in collection.find({"assignmentsID":previousAssignmentsID}):
		if int(str(level["current_score"])) < int(messageObj["score"]):
			currentsec = str(int(time.mktime(datetime.datetime.now().utctimetuple())))
			collection.update({"levelID":levelID}, {"$set": {"assignmentsID": newAssignmentsID, "last_update": currentsec, "current_score": messageObj["score"], "revision": messageObj["revision"], "leader": messageObj["username"]}})
	return '{"assignmentsID":"' + str(newAssignmentsID) + '"}'



def test():
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.gameapi

	#mark served level as completed
	collection = db.Level
	xmlID = "52f3cb1ba8e0d6c8940ca999"
	obj = collection.find_one({"xmlID":xmlID})
	collection.update({"xmlID":xmlID}, {"$set": {"submitted": "v6test"}})

	return "food"
	
#CERTAINLY NO REASON TO INCLUDE A SWITCH FUNCTION IN PYTHON
if sys.argv[1] == "findPlayedTutorials2":
	print(getPlayedTutorials2(sys.argv[2]))
elif sys.argv[1] == "reportPlayedTutorial2":
	print(reportPlayedTutorial2(sys.argv[2]))
elif sys.argv[1] == "reportPlayerRating2":
	print(reportPlayerRating2(sys.argv[2]))
elif sys.argv[1] == "passURL2":
	print(passURL2(sys.argv[2]))
elif sys.argv[1] == "passURLPOST2":
	print(passURLPOST(sys.argv[2], sys.argv[3]))

elif sys.argv[1] == "getActiveLevels2":
	print(getActiveLevels2())
elif sys.argv[1] == "getFile2":
	print(getFile2(sys.argv[2]))
elif sys.argv[1] == "getFile2NonEncoded":
	print(getFile2NonEncoded(sys.argv[2]))
elif sys.argv[1] == "submitLevelPOST2":
	print(submitLevel2(sys.argv[2], sys.argv[3]))


elif sys.argv[1] == "test":
	print(test())

elif sys.argv[1] == "foo":
	print("bar")
else:
    print(sys.argv[1] + " not found")
