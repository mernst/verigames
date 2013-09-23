#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import sys
import pymongo
import bson
from pymongo import Connection
from pymongo import database
from bson.objectid import ObjectId


def getOverallLeaders():
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.gameapi
	collection = db.LeaderTotals
	concatList = []
	for leader in collection.find().sort("groupScore", -1):
		concatList.append('{ "GroupName" : "')
		concatList.append(leader[u'groupName'].encode('ascii', 'replace'))
		concatList.append('", "GroupScore" : ')
		concatList.append(str(leader["groupScore"]))
		concatList.append('},')
	return '{ Leaders: [' + ''.join(concatList).strip(',') + '] }'

def getLevelList():
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.gameapi
	collection = db.Level
	concatList = []
	for level in collection.find():
		concatList.append('{ "LevelName" : "')
		concatList.append(str(level["name"]))
		concatList.append('", "LevelNumber" : ')
		concatList.append('"' + str(level["xmlID"]) + '"')
		concatList.append('},')
	return '{ Levels: [' + ''.join(concatList).strip(',') + '] }'

def getGroupList():
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.gameapi
	collection = db.Groups
	concatList = []
	for group in collection.find({"status":1}):
		concatList.append('{ "GroupName" : "')
		concatList.append(group[u'name'].encode('ascii', 'replace'))
		concatList.append('", "GroupID" : ')
		concatList.append('"' + str(group["_id"]) + '"')
		concatList.append('},')
	return '{ Groups: [' + ''.join(concatList).strip(',') + '] }'
	
def getTopScoresForLevel(levelID):
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.gameapi
	collection = db.LevelTotals
	groupColl = db.Groups
	concatList = []
	for level in collection.find({"xmlID":str(levelID)}).sort("score", -1):
		groupName = ""
		group = groupColl.find_one({"_id":ObjectId(level["groupID"])})
		if group != None:
			groupName = group["name"].encode('ascii', 'replace')
		else:
			groupName = "New Player"
		concatList.append('{ "GroupName" : "')
		concatList.append(groupName)
		concatList.append('", "Points" : ')
		concatList.append(str(level["points"]))
		concatList.append(', "Score" : ')
		concatList.append(str(level["score"]))
		concatList.append('},')
	return '{ Scores: [' + ''.join(concatList).strip(',') + '] }'

def getScoresForGroup(groupID):
	client = Connection('api.flowjam.verigames.com', 27017)
	db = client.gameapi
	levelTotalColl = db.LevelTotals
	levelColl = db.Level
	concatList = []
	for level in levelTotalColl.find({"groupID":groupID}).sort("score",-1):
		levelName = ""
		levelData = levelColl.find_one({"xmlID":level["xmlID"]})
		if levelData != None:
			levelName = levelData["name"]
			
			
		else:
			levelName = "Retired level"
		concatList.append('{ "LevelName" : "')
		concatList.append(levelName)
		concatList.append('", "Points" : ')
		concatList.append(str(level["points"]))
		concatList.append(', "Score" : ')
		concatList.append(str(level["score"]))
		concatList.append('},')
	return '{ Scores: [' + ''.join(concatList).strip(',') + '] }'
	
if sys.argv[1] == "overallLeaders":
    print(getOverallLeaders())
elif sys.argv[1] == "levelList":
	print(getLevelList())
elif sys.argv[1] == "groupList":
	print(getGroupList())
elif sys.argv[1] == "topForLevel":
	print(getTopScoresForLevel(sys.argv[2]))
elif sys.argv[1] == "groupScores":
	print(getScoresForGroup(sys.argv[2]))
else:
    print(sys.argv[1] + " not found")
