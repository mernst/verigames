import sys
from tulip import tlp
import networkx as nx
import itertools
import math
import json, os
from Queue import *
#import treemapSlice
##import pydot
##import gv


def json_dump(obj, fp):
    json.dump(obj, fp, indent=2, separators=(',',': '), sort_keys=True)
    fp.write('\n')

def makeGroupName(x, y, size):
    return "Group" + str(x) + ":" + str(y) + "Size" + str(size)

def layout(tlp_graph, view_layout, tlp_id_to_name, tlp_name_to_id, outputFile):

    nx_graph = nx.Graph()
    
    for edge in tlp_graph.getEdges():
        print("ID1: ", tlp_graph.source(edge), "ID2: ", tlp_graph.target(edge))

        nx_graph.add_edge(tlp_id_to_name[tlp_graph.source(edge)], tlp_id_to_name[tlp_graph.target(edge)])

    nodeGroupMap = {}

    botLeft = (1000,1000)
    topRight = (0,0)
    allLeaves = []

    currentLevel = []

    size = 4 ## has to be int

    for nodeId in tlp_graph.getNodes(): 

        nodeName = tlp_id_to_name[nodeId]
        allLeaves.append(nodeName)

        position = (view_layout[nodeId][0], view_layout[nodeId][1])

        gridSq = ((int(position[0]) / size) * size, (int(position[1]) / size) * size)

        nodeGroupName = makeGroupName(str(gridSq[0]), str(gridSq[1]), size)
        if nodeGroupMap.has_key(nodeGroupName):
            nodeGroupMap[nodeGroupName]["children"].append(nodeName)
            nodeGroupMap[nodeGroupName]["numLeafNodes"] += 1

            children = nodeGroupMap[nodeGroupName]["children"]
            newX = (nodeGroupMap[nodeGroupName]["position"][0] + nodeName["position"][0] * len(children)) / (len(children) + 1)
            newY = (nodeGroupMap[nodeGroupName]["position"][1] + nodeName["position"][1] * len(children)) / (len(children) + 1)
            nodeGroupMap[nodeGroupName]["position"] = (newX, newY)
        else:
            nodeGroupMap[nodeGroupName] = {"children": [nodeName], "position": position, "numLeafNodes": 1, "size": 4, "gridSize": size}
            currentLevel.append(nodeGroupName)

        ##print("POISITION: ", position)
        
        botLeft = (min(botLeft[0], position[0]), min(botLeft[1], position[1]))
        topRight = (max(topRight[0], position[0]), max(topRight[1], position[1]))

        nodeGroupMap[nodeName] = {"parent": nodeGroupName, "position": position, "numLeafNodes": 1, "size": 2, "gridSize": 1} ## TODO DOUBLE CHECK SIZE AND GRIDSIZE


    width = topRight[0] - botLeft[0]
    height = topRight[1] - botLeft[1]
    maxSize = int(min(width, height))

    size = size * 2
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
                nodeGroupMap[parentGroupName]["position"] = (newX, newY)

            else:
                nodeGroupMap[parentGroupName] = {"children": [nodeName], "position": position, "numLeafNodes": childNode["numLeafNodes"], "gridSize": size}
                nextLevel.append(parentGroupName)

            ## TODO toggle size to scale well in all cases

            numLeafNodes = nodeGroupMap[parentGroupName]["numLeafNodes"] 
            quarterGridSize = size / 4
            if numLeafNodes > quarterGridSize:
                sizeOver = int(math.ceil(numLeafNodes - quarterGridSize))
                print("SIZEOVER: ", sizeOver)
                addOver = sizeOver / 4  ## test divide by 16 for very dense and large graphs
                actualSize = quarterGridSize + addOver
            else:
                actualSize = numLeafNodes

            nodeGroupMap[parentGroupName]["size"] = actualSize
            childNode["parent"] = parentGroupName

        print("SIZE: ", size)
        size = size * 2
        currentLevel = nextLevel[:]


    nodeGroupMap["Group0"] = {"children": currentLevel, "position": (0,0), "numLeafNodes": 1}

    for nodeName in currentLevel:
        nodeGroupMap[nodeName]["parent"] = "Group0"

    json_dump(nodeGroupMap, open(outputFile + "GroupingTree" + ".json", "w"))

    ## use below for drawing each level to Tulip.  This takes a long time on large graphs and can also run out of memory
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


