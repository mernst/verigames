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

#get all submissions for levelId, sort by score, take top 20, compare, take unique top 5 in distance, store in Levels collection
def selectLevelVariantsToServe(db, levelID):
	#??test to see if there are enough recent submissions to make it worthwhile to update
	#test_collection = db.CurrentSolutions
	#test_levelList = []
	#for level in test_collection.find({"levelID":levelID}):
	#	test_levelList.append(level)
		
	#if len(test_levelList) < 5:
	#	return
	
	#if we made it this far, remove to limit redundancy
	#test_collection.remove({"levelID":levelID})
	
	collection = db.Solvers
	levelList = []
	for level in collection.find({"levelID":levelID}):
		if 'hash' in level:
			levelList.append(level)
			#flag as not duplicate to begin with
			level["duplicate"] = "none"

	#if not solved, if not in levels, copy over, then return
	if len(levelList) == 0:
		print "none found"
		levels = db.Levels.find({"levelID":levelID})
		if levels is None:
			db.Levels.insert(level)
		return
	
	if len(levelList) > 20:
		numLevelsToScore = 20
	else:
		numLevelsToScore = len(levelList)

	print numLevelsToScore
	
	levelList.sort(key=lambda x: x['current_score'], reverse=True)
	scoredLevels = []
	for i in range(0, numLevelsToScore):
		scoredLevels.append(levelList[i])
		totalDifference = 0
		for j in range(0, numLevelsToScore):
			if i == j:
				continue
			difference = compareLevels(levelList[i], levelList[j])
			totalDifference = totalDifference + difference
			#if we have an exact match, the the second gets flagged
			if difference == 0:
				levelList[j]["duplicate"] = str(levelList[i]["_id"])
		
		levelList[i]["distanceScore"] = totalDifference
				
				
	scoredCollection = db.ScoredLevels	
	
	#clear out old entries
	scoredCollection.remove({"levelID":levelID})
	#insert into separate collection for future use?
	for i in range(0, len(scoredLevels)):
		scoredCollection.insert(scoredLevels[i])	
		
	#total scores and choose best 5
	serveList = chooseLevelVariants(scoredLevels)
	levelCollection = db.Levels
	
	levelCollection.remove({"levelID":levelID})
	#insert into separate collection for future use?
	for i in range(0, len(serveList)):
		levelCollection.insert(serveList[i])	
		
	print 'done'
	
	
def compareLevels(level1, level2):
	levelHash1 = level1["hash"]
	levelHash2 = level2["hash"]

	difference = 0
	for i in range(1, len(levelHash1)):
		score1 = levelHash1[i]
		score2 = levelHash2[i]
		
		if score1 > score2:
			difference = difference + (score1 - score2)
		else:
			difference = difference + (score2 - score1)
			
	if "distanceArray" not in level1:
		level1["distanceArray"] = {}
	if "distanceArray" not in level2:
		level2["distanceArray"] = {}

	if 'id' in level1:
		level1ID = str(level1["id"])
	if '_id' in level1:
		level1ID = str(level1["_id"])
		if isinstance(level1["_id"], dict):
			level1ID = str(level1["_id"]["$oid"])
		
	if 'id' in level2:
		level2ID = str(level2["id"])		
	if '_id' in level2:
		level2ID = str(level2["_id"])
		if isinstance(level2["_id"], dict):
			level2ID = str(level2["_id"]["$oid"])
		
	level1["distanceArray"][level2ID] = difference
	level2["distanceArray"][level1ID] = difference
	
	return difference
	
#total scores and choose best 5, move from baseLevels collection
def chooseLevelVariants(levelList):

	levelList.sort(key=lambda x: x['distanceScore'], reverse=True)
	
	serveList = []
	numberSaved = 0
	for i in range(0, len(levelList)):
		if levelList[i]["duplicate"] == "none":
			serveList.append(levelList[i])
			numberSaved = numberSaved+1
		if numberSaved == 5:
			break;
			
	print numberSaved
	return serveList;	
	

client = Connection('api.flowjam.verigames.com', 27017)
db = client.game2api
collection = db.BaseLevels

for level in collection.find():
	print "scoring " + level["levelID"]
	selectLevelVariantsToServe(db, level["levelID"])
	