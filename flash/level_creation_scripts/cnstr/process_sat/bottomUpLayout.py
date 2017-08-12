import sys
from tulip import tlp
import networkx as nx
import itertools
import math
import json, os
from Queue import *
import copy
import _util
#import treemapSlice
##import pydot
##import gv


## TODO: Make sure you only create a parent if it contains enough children - NOTE: TRY REFACTORING FIRSTPASS
## TODO: maybe combine loops so we don't iterate through three separate times.  - Would take some refactoring
## Todo: figure out file size

def makeGroupName(x, y, size):
    return "Group" + str(x) + ":" + str(y) + "Size" + str(size)


def separateInfoFiles(topNode, nodeGroupMap, outputFile):
    ## have route file with top level (or top few levels)

    ## then others are just named whatever

    maxSize = 5000 ## adjust based on how long it takes to load

    fileContents = []
    fileNumber = 0
    fileName = outputFile + "sub" 

    #i = 0

    for nodeKey in topNode["children"]:
        curNode = nodeGroupMap[nodeKey]
        fileContents.append(curNode) ## ensures all top level is in file 0


    queue = Queue() ## TODO: figure out if need lifoqueue or not.  Make sure going through depth first to add to files
    for nodeKey in topNode["children"]:
        queue.put(nodeKey)


    while not queue.empty(): ## TODO there's a bug in here somewhere relating to adding fileNames properly. NOT GOING DEPTH FIRST
        nodeKey = queue.get()
        curNode = nodeGroupMap[nodeKey]

        ##for curNodeName in curNodes:
        ##    curNode = nodeGroupMap[curNodeName]

        if curNode.has_key("children"):
            curNode["fileNames"] = []

            for child in curNode["children"]:
                childNode = nodeGroupMap[child]
                if len(fileContents) >= maxSize:
                    _util.json_dump({"contents": fileContents}, open(fileName + str(fileNumber) + ".json", "w"))
                    fileContents = []
                    fileNumber += 1

                fileContents.append(childNode)
                curNode["fileNames"].append(fileName + str(fileNumber))

                queue.put(child)

    _util.json_dump({"contents": fileContents}, open(fileName + str(fileNumber) + ".json", "w"))



## combines edges that point to same group, only tracks edges starting at current depth
def bottomUpThirdPassForGroup(tlp_graph, tlp_id_to_name, nodeGroupMap):

    queue = Queue()
    for node in tlp_graph.getNodes():
        nodeKey = tlp_id_to_name[node]

        print ("NODEKYES: ", nodeKey)
        queue.put(nodeKey)

    while not queue.empty():
        nodeKey = queue.get()

        node = nodeGroupMap[nodeKey]

        if node.has_key("children") and not node.has_key("edges"):

            node["edges"] = [] 

            edgeDict = {}

            ##parentSatPercent = 0.0

            totalNumConstraintNodes = 0
            parentNumSat = 0

            for child in node["children"]:
                childNode = nodeGroupMap[child] 
                potentialEdges = childNode["edges"]

                if childNode.has_key("sat"):
                    parentNumSat += childNode["sat"][0]
                    totalNumConstraintNodes += childNode["sat"][1]
                    ##parentSatPercent += childNode["psat"] * (childNode["numConstraintNodes"] / float(totalNumConstraintNodes))

                #childNode.pop("numConstraintNodes", None)
                #childNode.pop("numSat", None)

                for edge in potentialEdges:

                    parentEdge = copy.copy(edge)
                    edgeHierarchy = copy.copy(parentEdge["to"])

                    edgeHierarchy = edgeHierarchy[1:] ## removes first element (node from level below)

                    print("parentEdge: ", parentEdge, " childEdge: ", edge)
                    if len(edgeHierarchy) > 0:
                        firstNode = edgeHierarchy[0] ## starts at level of parent node
                        if not edgeDict.has_key(firstNode) and firstNode != nodeKey:
                            print("inhere: ", firstNode)

                            parentEdge["oPos"] = nodeGroupMap[firstNode]["position"]

                            if node.has_key("parent") and node["parent"] == "Group0":
                                print("toppopping")
                                parentEdge["to"] = nodeGroupMap[firstNode]["name"]  ## name field is what unity wants, not key.  Much shorter
                            else:
                                parentEdge["to"] = edgeHierarchy

                            edgeDict[firstNode] = (parentEdge["sign"], parentEdge["oVal"])   ## node to sign
                            node["edges"].append(parentEdge)
                        
                        elif edgeDict.has_key(firstNode):
                            print("hasFIRSTNODE: ", firstNode)
                            existingSign = edgeDict[firstNode][0]
                            existingOValue = edgeDict[firstNode][1]

                            newSign = existingSign
                            newOValue = existingOValue

                            if existingSign != 2 and parentEdge["sign"] != existingSign:
                                existingSign = 2
                                newSign = 2
                                print("Existingsign")
                            if existingOValue != 2 and existingOValue != 5 and parentEdge["oVal"] != existingOValue:
                                if existingOValue < 2:
                                    newOValue = 2
                                else: 
                                    newOValue = 5

                            for nodeEdge in node["edges"]:
                                if nodeEdge["oPos"] == nodeGroupMap[firstNode]["position"]:
                                    print("soisdf", nodeGroupMap[firstNode])
                                    nodeEdge["sign"] = newSign
                                    nodeEdge["oVal"] = newOValue
                                    break
                        
                    edge["to"] = nodeGroupMap[edge["to"][0]]["name"] # sets level below to have only it's current level as pointer
                    ##if childNode.has_key("children") and edge.has_key("pointingTo"):
                        ##edge.pop("pointingTo", None)
                    print("parentPointing: ", parentEdge["oPos"] , " childPointing: ", edge["oPos"])


            #if node["parent"] != "Group0":
            #    node["numConstraintNodes"] = totalNumConstraintNodes
            #    node["numSat"] = parentNumSat
            '''
            if totalNumConstraintNodes > 0:
                if totalNumConstraintNodes > parentNumSat:
                    node["psat"] = int(parentNumSat / float(totalNumConstraintNodes) * 100) ##will be floored, which we want, so don't lie and say its fully sat
                else:
                    node["psat"] = 100 ##int(round(parentNumSat / float(totalNumConstraintNodes) * 100))
            else: 
                node["psat"] = 100 ## TODO decide if we want to have the value at all.  Helpful when processing on unity side
            '''
            node["sat"] = [parentNumSat, totalNumConstraintNodes]
        if node.has_key("parent") and node["parent"] != "Group0":
            queue.put(node["parent"])



def makeListOfAncestors(nodeName, nodeGroupMap):

    node = nodeGroupMap[nodeName]
    parentList = [nodeName]
    while node.has_key("parent") and node["parent"] != "Group0":
        parentName = node["parent"]
        parentList.append(parentName)
        node = nodeGroupMap[parentName]

    return parentList

## TODO change these so edges only point to cur level
def bottomUpSecondPass(tlp_graph, tlp_id_to_name, nodeGroupMap, nodeConstraintMap):

    for nodeId in tlp_graph.getNodes(): 
        nodeName = tlp_id_to_name[nodeId]

        if nodeConstraintMap["constraintMap"].has_key(nodeName): ## only constraints are in here, not vars

            constraints = nodeConstraintMap["constraintMap"][nodeName]
            signs = nodeConstraintMap["signMap"][nodeName] ## should match constraints
            nodeGroupMap[nodeName]["edges"] = []

            ##nodeGroupMap[nodeName]["numConstraintNodes"] = 1

            i = 0

            ## assign value to each var

            varValues = []
            constraintSatisfied = 3
            for x in range(0, len(signs)):
                varVal = 0  ## TODO change this to change starting variable value
                varValues.append(varVal)  ## could make random or assign from input somehow

                if (signs[x] == -1 and varVal == 0) or (signs[x] == 1 and varVal == 1): ## have same sign
                    constraintSatisfied = 4

            ## check if satisfied

            for varNodeName in constraints:

                ## sets edges for constraint node, and for any var nodes it points to

                if (signs[i] == -1 and varValues[i] == 0) or (signs[i] == 1 and varValues[i] == 1):
                    constraintSatisfiedbyCurVar = 1
                else:
                    constraintSatisfiedbyCurVar = 0

                nodeGroupMap[nodeName]["edges"].append({"oVal": constraintSatisfiedbyCurVar, "sign": signs[i], "oPos": nodeGroupMap[varNodeName]["position"], "to":makeListOfAncestors(varNodeName, nodeGroupMap)})

                if nodeGroupMap[varNodeName].has_key("edges"):
                    nodeGroupMap[varNodeName]["edges"].append({"oVal": constraintSatisfied, "sign": signs[i], "oPos": nodeGroupMap[nodeName]["position"], "to": makeListOfAncestors(nodeName, nodeGroupMap)})
                else:
                    nodeGroupMap[varNodeName]["edges"] = [{"oVal": constraintSatisfied, "sign": signs[i], "oPos": nodeGroupMap[nodeName]["position"], "to": makeListOfAncestors(nodeName, nodeGroupMap)}]

                i += 1

            if constraintSatisfied == 4:
                nodeGroupMap[nodeName]["sat"] = [1, 1]
                nodeGroupMap[nodeName]["numSat"] = 1
            else:
                nodeGroupMap[nodeName]["sat"] = [0, 1]
                nodeGroupMap[nodeName]["numSat"] = 0


def LevelFiles(topNode, totalNumBaseNodes, nodeGroupMap, maxDepth, fullWidth, fullHeight, lowestLevelUnderOneThousandNodes, lowestSize, sizeIncreaseFactor, outputFile):

    levelToStartDivide = lowestLevelUnderOneThousandNodes

    fileContents = []
    ##botLeftCorner = (0,0) ##TODO REALLY FIGURE OUT FULLGRIDSIZE - IT's A MAGIC NUMBER THAT DOESN"T EVEN ALWAYS WORK
    ##fullGridSize = topNode["gridSize"] * 4 ## VERIFY: should be 8 times size of fileGridSize because it's that ensures it encompasses full graph
    ##fileGridSize = topNode["gridSize"] / 2 ## real first level is half size of group0
    ##print("FILEGRIDSIZE: ", fileGridSize)
    level = 0

    groupNumber = 1  ## 0 is still reserved for top root node


    curLevel = []
    for nodeKey in topNode["children"]:
        curNode = nodeGroupMap[nodeKey]
        ##curNode["position"] = (curNode["position"][0] + addToNormalize[0], curNode["position"][0] + addToNormalize[0], 
        fileContents.append(curNode)
        #if curNode.has_key("psat"):
            ##curNode["psat"] = round(curNode["psat"], 2)
        if curNode.has_key("children"):
            ##curNode["name"] = "G" + str(groupNumber)
            ##groupNumber += 1
            for childKey in curNode["children"]:
                childNode = nodeGroupMap[childKey]
                curLevel.append(childNode)

        curNode.pop("children", None)
        curNode.pop("parent", None)

    # call to generate level name for a given hash
    generatedName = generateLevelName("resources/adjectives_file.txt", "resources/nouns_file.txt", "5d41402abc4b2a76b9719d911017c592")
    
    routeFile = {"contents": fileContents, "routeInfo":{"lowestSize": lowestSize, "sizeIncreaseFactor":sizeIncreaseFactor, "totalNumBaseNodes":totalNumBaseNodes, "maxDepth": maxDepth, "fullWidth": fullWidth, "fullHeight": fullHeight, "levelToStartDivide": levelToStartDivide, "generatedName": generatedName}} ## maybe supply factor above
    _util.json_dump(routeFile, open(str((0,0)) + "level" + str(level) + ".json", "w"))
    fileContents = []
    #fileGridSize = fileGridSize / 2
    level += 1

    nextLevel = []
    while len(curLevel) > 0:

        numFilesInLevel = 1
        posFileDict = {}

        if (level > levelToStartDivide):
            levelDiff = level - levelToStartDivide   #(fileGridSize / 4) ## 4 is starting size - refactor
            ##if levelDiff % 2 != 0:
            ##    levelDiff += 1

            power = min(levelDiff * 2 + 2, 12)

            numFilesInLevel = int(2 ** power)
            print("numlevelsinfile: ", numFilesInLevel)
            print("levetostartdidvide ", levelToStartDivide, "level ", level)

            xSize = int(math.ceil(fullWidth / (numFilesInLevel ** .5)))
            ySize = int(math.ceil(fullHeight / (numFilesInLevel ** .5)))

            ## goes through full grid, setting up file quadrants
            x = 0
            while x < fullWidth:
                y = 0
                while y < fullHeight:
                    posFileDict[x,y] = []
                    y = y + ySize

                x = x + xSize
        else:
            xSize = fullWidth 
            ySize = fullHeight 
            posFileDict[0,0] = []

        print("POSFILEFILE: ", posFileDict)
        for node in curLevel:
            ##for childKey in parentNode["children"]:
                ##childNode = nodeGroupMap[childKey]
            #if node.has_key("psat"):
            #    node["psat"] = round(node["psat"], 2)

            pos = node["position"]

            print("POSSSS: ", pos, "xsize", xSize, "ysize", ySize)

            fileQuad = int(math.floor(pos[0] / (xSize + 1))) * xSize, int(math.floor(pos[1] / (ySize + 1))) * ySize

            posFileDict[fileQuad].append(node)

            if node.has_key("children"):
                #curNode["name"] = "G" + str(groupNumber)
                #groupNumber += 1
                for childKey in node["children"]:
                    childNode = nodeGroupMap[childKey]
                    nextLevel.append(childNode) 

            node.pop("children", None)
            node.pop("parent", None)

        print("NUMLEVELSKSDJFK: ", numFilesInLevel)
        for filePos in posFileDict.keys():
            if len(posFileDict[filePos]) > 0: ##optimization to remove empty files
                _util.json_dump({"contents": posFileDict[filePos]}, open(str(filePos) + "level" + str(level) + ".json", "w"))


        curLevel = list(nextLevel)
        nextLevel = []
        ##fileGridSize = fileGridSize / 2
        level += 1


def calculateSize(nodeName, nodeGroupMap, size, useLog):
    ## pass in name of node to find size of.
    ## TODO move size calc to unity side - can also adjust dynamically then if needed
    numLeafNodes = nodeGroupMap[nodeName]["numLeafNodes"] 

    if useLog:
        actualSize = math.log(numLeafNodes, 1.2)

    else: 
        quarterGridSize = size / 4
        if numLeafNodes > quarterGridSize:
            sizeOver = int(math.ceil(numLeafNodes - quarterGridSize))
            print("SIZEOVER: ", sizeOver)
            addOver = sizeOver / 4  ## test divide by 16 for very dense and large graphs
            actualSize = quarterGridSize + addOver
        else:
            actualSize = numLeafNodes

    nodeGroupMap[nodeName]["size"] = actualSize


def layout(tlp_graph, constraintMapFile, view_layout, tlp_id_to_name, tlp_name_to_id, totalNumBaseNodes, layoutAlgThreshold, outputFile):

    with open(constraintMapFile) as json_data:
        nodeConstraintMap = json.load(json_data)




    ## if different layout is what's causing scale issues, examine the differences for same graph
    ## check if size > threshold for other algorithm,
    ## if so, scale down positions or shift them over

    ## will this help with too many nodes being grouped together?  Maybe, hard to tell till we see side by side


## TODO: ensure each parent has at least 20 children or 10-30 - some way to reduce amount of levels


    nx_graph = nx.Graph()
    
    for edge in tlp_graph.getEdges():
        print("ID1: ", tlp_graph.source(edge), "ID2: ", tlp_graph.target(edge))

        nx_graph.add_edge(tlp_id_to_name[tlp_graph.source(edge)], tlp_id_to_name[tlp_graph.target(edge)])


    botLeft = view_layout.getMin()
    topRight = view_layout.getMax()
    nodeGroupMap = {}

    allLeaves = []

    currentLevel = []
    level = 0

    if totalNumBaseNodes > layoutAlgThreshold:
        size = 64
    else:
        size = 16 ## has to be int
    lowestSize = size

    ##totalNumBaseNodes = 0

    groupNumber = 1  ## 0 is still reserved for top root node

    for nodeId in tlp_graph.getNodes(): 

        ##totalNumBaseNodes += 1

        nodeName = tlp_id_to_name[nodeId]
        allLeaves.append(nodeName)

        position = (view_layout[nodeId][0], view_layout[nodeId][1])
        normalizedPosition = (position[0] + botLeft[0] * -1, position[1] + botLeft[1] * -1)

        normalizedPosition = (round(normalizedPosition[0], 2), round(normalizedPosition[1], 2))

        print("botLeft ", botLeft, "topRight ", topRight, " position ", position, " normalizedPosition ", normalizedPosition)

        gridSq = ((int(normalizedPosition[0]) / size) * size, (int(normalizedPosition[1]) / size) * size)
        nodeGroupName = makeGroupName(str(gridSq[0]), str(gridSq[1]), size)

        nodeGroupMap[nodeName] = {"name":nodeName, "parent": nodeGroupName, "position": normalizedPosition, "numLeafNodes": 1, "size": 1} ## TODO DOUBLE CHECK SIZE AND GRIDSIZE

        if nodeGroupMap.has_key(nodeGroupName):
            nodeGroupMap[nodeGroupName]["children"].append(nodeName)
            nodeGroupMap[nodeGroupName]["numLeafNodes"] += 1

            children = nodeGroupMap[nodeGroupName]["children"]
            newX = (nodeGroupMap[nodeGroupName]["position"][0] + nodeGroupMap[nodeName]["position"][0] * len(children)) / (len(children) + 1)
            newY = (nodeGroupMap[nodeGroupName]["position"][1] + nodeGroupMap[nodeName]["position"][1] * len(children)) / (len(children) + 1)
            nodeGroupMap[nodeGroupName]["position"] = (round(newX, 2), round(newY, 2))
        else:
            nodeGroupMap[nodeGroupName] = {"name":"G" + str(groupNumber), "children": [nodeName], "position": normalizedPosition, "numLeafNodes": 1, "size": 1}
            groupNumber += 1
            currentLevel.append(nodeGroupName)



    lowestLevelUnderOneThousandNodes = -1  # change to highest over 1000


    level += 1

    width = topRight[0] - botLeft[0]
    height = topRight[1] - botLeft[1]
    print("finalwidth: ", width, "finalheight: ", height)

    maxSize = int(max(width, height)) ## int(min(width, height))

    if totalNumBaseNodes > layoutAlgThreshold:
        sizeIncreaseFactor = 6
    else:
        sizeIncreaseFactor = 3

    size = size * sizeIncreaseFactor

    while size < maxSize/4: 
   
        nextLevel = []
        ## could make below block work for above - pull out as function
        for nodeName in currentLevel: 

            childNode = nodeGroupMap[nodeName]
            position = childNode["position"]

            gridSq = ((int(position[0]) / size) * size, (int(position[1]) / size) * size) 

            ## position is actual averaged position, so you get top left corner for consistent/findable name
            parentGroupName = makeGroupName(str(gridSq[0]), str(gridSq[1]), size)
            if nodeGroupMap.has_key(parentGroupName):
                nodeGroupMap[parentGroupName]["children"].append(nodeName)

                childLeafCount = childNode["numLeafNodes"]
                origParentLeafCount =  nodeGroupMap[parentGroupName]["numLeafNodes"] 
                nodeGroupMap[parentGroupName]["numLeafNodes"] += childLeafCount

                children = nodeGroupMap[parentGroupName]["children"]
                newX = (nodeGroupMap[parentGroupName]["position"][0] * origParentLeafCount + childNode["position"][0] * childLeafCount) / (childLeafCount + origParentLeafCount)
                newY = (nodeGroupMap[parentGroupName]["position"][1] * origParentLeafCount + childNode["position"][1] * childLeafCount) / (childLeafCount + origParentLeafCount)
                nodeGroupMap[parentGroupName]["position"] = (round(newX, 2), round(newY, 2))

            else:
                nodeGroupMap[parentGroupName] = {"name": "G" + str(groupNumber), "children": [nodeName], "position": position, "numLeafNodes": childNode["numLeafNodes"]}
                groupNumber += 1
                nextLevel.append(parentGroupName)


                calculateSize(parentGroupName, nodeGroupMap, size, totalNumBaseNodes > layoutAlgThreshold) ## NOTE: HAS TO MATCH VALUE FROM LAYOUTTULIP - could pass it in

            childNode["parent"] = parentGroupName

        print("SIZE: ", size)
        size = size * sizeIncreaseFactor

        print("LENCURRENTLYEV: ", len(nextLevel))
        if lowestLevelUnderOneThousandNodes == -1 and len(nextLevel) < 350: ## CHANGE THIS FOR effecting when to start splitting files
            print("lowsfoijs: ", level + 2)
            lowestLevelUnderOneThousandNodes = level + 2

        currentLevel = nextLevel[:]

        level += 1

    if len(currentLevel) > 350: ## in case even highest level has too many nodes (which you should probably fix by adding more levels)
        lowestLevelUnderOneThousandNodes = level - 1

    nodeGroupMap["Group0"] = {"children": currentLevel, "position": (0,0), "numLeafNodes": 1}

    for nodeName in currentLevel:
        nodeGroupMap[nodeName]["parent"] = "Group0"



    bottomUpSecondPass(tlp_graph, tlp_id_to_name, nodeGroupMap, nodeConstraintMap)

    bottomUpThirdPassForGroup(tlp_graph, tlp_id_to_name, nodeGroupMap)

    lowestLevelUnderOneThousandNodes = max(level - lowestLevelUnderOneThousandNodes, 0) ## to get level from top
    
    print("actuallowestlevel: ", level - 1)

    LevelFiles(nodeGroupMap["Group0"], totalNumBaseNodes, nodeGroupMap, level, int(width + 1), int(height + 1), lowestLevelUnderOneThousandNodes, lowestSize, sizeIncreaseFactor, outputFile)

    ##separateInfoFiles(nodeGroupMap["Group0"], nodeGroupMap, outputFile)

    '''
    levelExport = []
    subName = 0
    level = 0
    for nodeId in tlp_graph.getNodes(): ## refactor
        nodeName = tlp_id_to_name[nodeId] 
        if len(levelExport) >= 250000:
            _util.json_dump(levelExport, open(outputFile + "GroupingLevel" + str(level) + "sub" + str(subName) + ".json", "w"))
            subName += 1
            levelExport = []
        else:
            nodeGroupMap[nodeName].pop('gridSize', None)
            nodeGroupMap[nodeName].pop('numLeafNodes', None)
            levelExport.append(nodeGroupMap[nodeName])


    ## get rid of parent field, gridSize, numLeafNodes, maybe size

    _util.json_dump(levelExport, open(outputFile + "GroupingLevel" + str(level) + "sub" + str(subName) + ".json", "w"))
    '''



    _util.json_dump(nodeGroupMap, open(outputFile + "GroupingTree" + ".json", "w"))

    ## use below for drawing each level to Tulip.  This takes a long time on large graphs and can also run out of memory
    #draw solo version might be more memory efficient, or just slower
    '''
    parentNodes = [nodeGroupMap["Group0"]] 

    tlp_idToNodeGroup = {}
    tlp_name_to_id = {}

    level = 1
    while len(parentNodes) > 0:
        tlp_graph = tlp.newGraph()

    ##for x in range(0,1): ## x is depth from top

        allChildren = []
        allChildrenKeys = []
        for parentNode in parentNodes:
            allChildren.extend([nodeGroupMap[child] for child in parentNode["children"]])
            allChildrenKeys.extend([child for child in parentNode["children"]])

        print ("ALLCHILDREN: ", allChildrenKeys)

        for child in allChildrenKeys:
            id = tlp_graph.addNode()
            tlp_idToNodeGroup[id] = nodeGroupMap[child]
            tlp_name_to_id[child] = id
            print("CHILD KEY", child)

        ## For connecting groups at same level and to parents
        for parentNode in parentNodes:
            lastNode = None
            for child in parentNode["children"]:
                if not lastNode:
                    print("IN HERE")
                    ##lastNode = nodeGroupMap[child]["parent"]
                if tlp_name_to_id.has_key(lastNode):
                    print("LastNode", lastNode, " child: ", child)
                    #tlp_graph.addEdge(tlp_name_to_id[lastNode], tlp_name_to_id[child])                    
                lastNode = child
        
        for nodeKey in allChildrenKeys:
            node = tlp_name_to_id[nodeKey] 
            properties = tlp_graph.getNodePropertiesValues(node)  ## this doesn't seem right

            groupNode = tlp_idToNodeGroup[node]

            ##colorFactor = int(groupNode["parent"][5:]) + 1 
            properties["viewSize"] = tlp.Vec3f(groupNode["size"], groupNode["size"], 1.0)
            properties["viewLayout"] = tlp.Vec3f(groupNode["position"][0], groupNode["position"][1], 0.0)
            ##properties["viewLabel"] = nodeKey
            ##properties["viewShape"] = tlp.NodeShape.Square

            ## LEVEL ISN'T ALWAYS ACCURATE.  Can go through top to bottom afterwards
            ##level = math.log(int((maxSize / 4) / groupNode["gridSize"]), 2) + 1

            print("GROUPNODE", groupNode)

            ##properties["viewColor"] = tlp.Color(int(math.floor(255 / level)), 0, min(int(math.floor(math.pow((level - 1), 2))), 255), min(int(math.floor(level / .01)), 255))
            print("PROPERTIES: ", properties)

            tlp_graph.setNodePropertiesValues(node, properties)

        parentNodes = [child for child in allChildren if child.has_key("children")]

        params = tlp.getDefaultPluginParameters('JSON Export', tlp_graph)
        success = tlp.exportGraph('JSON Export', tlp_graph, outputFile + "botUp" + str(level) + ".json", params)

        level += 1


    params = tlp.getDefaultPluginParameters('JSON Export', tlp_graph)
    success = tlp.exportGraph('JSON Export', tlp_graph, outputFile + "botUp" + ".json", params)

    '''


    ## draws base nodes layed out graph with original edges
    tlp_graph = tlp.newGraph()

    tlp_name_to_id = {}
    for leaf in allLeaves:
        print("LEAF", leaf)
        id = tlp_graph.addNode()
        tlp_name_to_id[leaf] = id
        node = id
        properties = tlp_graph.getNodePropertiesValues(node)

        groupNode = nodeGroupMap[leaf]

        properties["viewSize"] = tlp.Vec3f(groupNode["size"], groupNode["size"], 1.0)
        properties["viewLayout"] = tlp.Vec3f(groupNode["position"][0], groupNode["position"][1], 0.0)
        ##properties["viewLabel"] = leaf

        print("PROPERTIES: ", properties)

        tlp_graph.setNodePropertiesValues(node, properties)

    for edge in nx_graph.edges():  ## to draw all edges of base clauses/vars
        tlp_graph.addEdge(tlp_name_to_id[edge[0]], tlp_name_to_id[edge[1]])

    params = tlp.getDefaultPluginParameters('JSON Export', tlp_graph)
    success = tlp.exportGraph('JSON Export', tlp_graph, outputFile + "levelVisLEAFS" + ".json", params)


def generateLevelName(adjFile, nounFile, hashStr):
    # Read all adjectives
    adjFileHandle = open(adjFile)
    adjList = adjFileHandle.readlines()
    adjFileHandle.close()
    
    # Read all nouns
    nounFileHandle = open(nounFile)
    nounList = nounFileHandle.readlines()
    nounFileHandle.close()
    
    # Compute sum of all chars in hash str. Use ord values
    sumVal = 0
    for ch in hashStr:
        sumVal = sumVal + ord(ch)
    print (sumVal)
    
    # Get adjective from adj list using mod
    adjIndex = sumVal % len(adjList)
    levelAdj = adjList[adjIndex]
    print (levelAdj)

    # Get noun from noun list using mod
    nounIndex = sumVal % len(nounList)
    levelNoun = nounList[nounIndex]
    print (levelNoun)
    
    adjStr = levelAdj.capitalize()
    nounStr = levelNoun.capitalize()
    adjStr = adjStr.rstrip() 
    nounStr = nounStr.rstrip()
    levelName = adjStr + nounStr
    return levelName

