import sys
from tulip import tlp
import networkx as nx
import itertools
import math
import json, os
from Queue import *
import layout_tulip
import treemapSlice
##import pydot
##import gv


def json_dump(obj, fp):
    json.dump(obj, fp, indent=2, separators=(',',': '), sort_keys=True)
    fp.write('\n')


def CalculateMetaDataBottomUp(tlp_graph, tlp_id_to_name, NodeNameToId, NodeGroupMap):
    
    queue = Queue()
    for node in tlp_graph.getNodes():
        nodeKey = tlp_id_to_name[node]
        print ("NOOOODEKYES: ", nodeKey)
        queue.put(nodeKey)

    while not queue.empty():
        nodeKey = queue.get()
        print ("Node key in queue get: ", nodeKey)
        if NodeGroupMap[nodeKey].has_key("children"):
            
            children = NodeGroupMap[nodeKey]["children"]
            NodeGroupMap[nodeKey]["numLeafNodes"] = sum([NodeGroupMap[child]["numLeafNodes"] for child in children])
            NodeGroupMap[nodeKey]["size"] = math.log(NodeGroupMap[nodeKey]["numLeafNodes"], 1.3)  ## TODO play around with size

            if not NodeGroupMap[nodeKey].has_key("position"):
                avgPosition = (0, 0)
                for childKey in children:
                    child = NodeGroupMap[childKey]
                    print ("CHILDDD: ", childKey, ": ", child)
                    avgPosition = (child["position"][0] + avgPosition[0], child["position"][1] + avgPosition[1])

                avgPosition = (avgPosition[0]/len(children), avgPosition[1]/len(children))
                NodeGroupMap[nodeKey]["position"] = avgPosition

        if NodeGroupMap[nodeKey].has_key("parent"):
            parentId = NodeGroupMap[nodeKey]["parent"]
            children = NodeGroupMap[parentId]["children"]

            allHaveField = True
            for childKey in children:
                child = NodeGroupMap[childKey]
                allHaveField = allHaveField and child.has_key("position")

            ## Only add parent if all chilren have been processed already.  This is important since the parents use childrens' processed data
            if allHaveField:
                queue.put(parentId)

    return NodeGroupMap


def partition_it(tlp_graph, view_layout, tlp_id_to_name, tlp_name_to_id, outputFile):
    nx_graph = nx.Graph()
    
    for edge in tlp_graph.getEdges():
        nx_graph.add_edge(tlp_id_to_name[tlp_graph.source(edge)], tlp_id_to_name[tlp_graph.target(edge)])

    # get partition
    sys.stderr.write('computing partition\n')
    hierarchy = nx.girvan_newman(nx_graph)

    nx_use_graph = nx.Graph()

    parents = []
    curDepth = 0

    groupsMade = 0
    NodeNameToId = {} ## the full name of all the nodes together, mapped to string "Group{idnum}" ex: "Group4"
    NodeGroupMap = {}  ## Dict["Group{idnum}": Dict[parent, level, position, size, numLeafNodes, children]]  where children is dictionary of nodeNames that map to NodeGroupMap.  

    i = 1 
    for communities in hierarchy: 

        if len(parents) == 0: ## creates node that has all elements of graph just to start it all connected
            firstParent = []
            for c in communities:
                firstParent += c
            parents.append(firstParent)

            parentNode = ','.join(sorted(firstParent))
            NodeNameToId[parentNode] = "Group" + str(groupsMade)
            parentKey = NodeNameToId[parentNode]
            NodeGroupMap[parentKey] = {"level": 0,"children": []} 
            groupsMade += 1

        else:
            for community in communities:
                for parent in parents:
                    if len(community) < len(parent):
                        if [member for member in community if member in parent]:
                            #print("CHILDNodes: ", community)
                            #print("PARENTNodes: ", parent)
                            communityNode = ','.join(sorted(community))
                            parentNode = ','.join(sorted(parent))
                            print("CHILD: ", communityNode, " PARENT: ", parentNode) 

                            parentKey = NodeNameToId[parentNode]

                            if len(community) == 1:
                                NodeGroupMap[parentKey]["children"].append(communityNode)
                                nodeLayout = (view_layout[tlp_name_to_id[communityNode]][0], view_layout[tlp_name_to_id[communityNode]][1])
                                NodeGroupMap[communityNode] = {"level": NodeGroupMap[parentKey]["level"] + 1, "parent": parentKey, "position": nodeLayout, "numLeafNodes": 1, "size": 3} 

                            else:
                                if not NodeNameToId.has_key(communityNode):
                                    NodeNameToId[communityNode] = "Group" + str(groupsMade)
                                    groupsMade += 1
                            
                                childKey = NodeNameToId[communityNode]

                                NodeGroupMap[parentKey]["children"].append(childKey)
                                NodeGroupMap[childKey] = {"level": NodeGroupMap[parentKey]["level"] + 1, "parent": parentKey, "children": []} 

                            nx_use_graph.add_edge(communityNode, parentNode)

            parents = list(communities)
            ##print("number of recursions: ", i)
            i += 1

    NodeGroupMap = CalculateMetaDataBottomUp(tlp_graph, tlp_id_to_name, NodeNameToId, NodeGroupMap)

    depth = 0
    '''
    for nodeGroups in nodeGroupsAtDepths:
        json_dump({"groups": nodeGroups}, open(outputFile + "Grouping" + str(depth) + ".json", "w"))
        depth += 1
    '''

    json_dump(NodeGroupMap, open(outputFile + "Grouping" + str(curDepth) + ".json", "w"))

    parentNodes = [NodeGroupMap["Group0"]]
    tlp_graph = tlp.newGraph()

    tlp_idToNodeGroup = {}
    tlp_name_to_id = {}
    for x in range(0,4):

        allChildren = []
        allChildrenKeys = []
        for parentNode in parentNodes:
            if parentNode.has_key("children"):
                allChildren.extend([NodeGroupMap[child] for child in parentNode["children"]])
                allChildrenKeys.extend([child for child in parentNode["children"]])

        print ("ALLCHILDREN: ", allChildren)

        for child in allChildren:
            id = tlp_graph.addNode()
            tlp_idToNodeGroup[id] = child
            childKey = allChildrenKeys[allChildren.index(child)]
            tlp_name_to_id[childKey] = id

        for parentNode in parentNodes:
            lastNode = None
            for child in parentNode["children"]:
                if not lastNode:
                    lastNode = NodeGroupMap[child]["parent"] ### NOTE: this isn't working
                if tlp_name_to_id.has_key(lastNode):
                    tlp_graph.addEdge(tlp_name_to_id[lastNode], tlp_name_to_id[child])                    
                lastNode = child
        
        for nodeKey in allChildrenKeys:
            node = tlp_name_to_id[nodeKey] 
            properties = tlp_graph.getNodePropertiesValues(node)

            groupNode = tlp_idToNodeGroup[node]

            colorFactor = int(groupNode["parent"][5:]) + 1
            properties["viewSize"] = tlp.Vec3f(groupNode["size"], groupNode["size"], 1.0)
            properties["viewLayout"] = tlp.Vec3f(groupNode["position"][0], groupNode["position"][1], 0.0)## = tlp.Vec3f(1.0, 2.0, 0.0)  IS THIS WHAT WE use for setting position?

            ## TODO maybe add labels?

            level = groupNode["level"]

            properties["viewColor"] = tlp.Color(int(math.floor(255 / colorFactor)), 0, int(math.floor(math.pow((colorFactor - 1), 2))), min(int(math.floor(level / .02)), 255))
            ##print("PROPERTIES: ", properties)

            tlp_graph.setNodePropertiesValues(node, properties)

        parentNodes = allChildren

        params = tlp.getDefaultPluginParameters('JSON Export', tlp_graph)
        success = tlp.exportGraph('JSON Export', tlp_graph, outputFile + "levelVis" + str(x) + ".json", params)

