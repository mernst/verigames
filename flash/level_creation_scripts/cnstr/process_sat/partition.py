import sys
from tulip import tlp
import networkx as nx
import itertools
import math
import json, os
from Queue import *
##import pydot
##import gv


def json_dump(obj, fp):
    json.dump(obj, fp, indent=2, separators=(',',': '), sort_keys=True)
    fp.write('\n')



def CalculateMetaDataBottomUp(tlp_graph, tlp_id_to_name, NodeNameToId, NodeGroupMap):
    ## recur bottom to top 
    ##numParentsLeft = len(tlp_graph.getNodes())

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
            #for child in children:
            #    NodeGroupMap[child]["numLeafNodes"]
            NodeGroupMap[nodeKey]["numLeafNodes"] = sum([NodeGroupMap[child]["numLeafNodes"] for child in children])
            NodeGroupMap[nodeKey]["size"] = math.log(NodeGroupMap[nodeKey]["numLeafNodes"], 2)

## PROBLEM IS that we're not going up level by level, so we go up to parent, and it's other child might be a group that hasn't been processed yet, cause it's deeper
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

            ## Only add parent if all chilren have been processed already
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
    NodeGroupMap = {}
    ## Dict[NodeGroupId: Dict[parent, level, pos, size?, numLeafNodes, children]] ## have to build up rest of info from bottom up on second pass

    i = 1  ## start with 1 because Log 1 = 0
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
                            print("CHILDNodes: ", community)
                            print("PARENTNodes: ", parent)
                            communityNode = ','.join(sorted(community))
                            parentNode = ','.join(sorted(parent))
                            print("CHILD: ", communityNode, " PARENT: ", parentNode) 

                            parentKey = NodeNameToId[parentNode]

                            if len(community) == 1:
                                NodeGroupMap[parentKey]["children"].append(communityNode)
                                nodeLayout = (view_layout[tlp_name_to_id[communityNode]][0], view_layout[tlp_name_to_id[communityNode]][1])
                                NodeGroupMap[communityNode] = {"level": NodeGroupMap[parentKey]["level"] + 1, "parent": parentKey, "position": nodeLayout, "numLeafNodes": 1} 

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
    '''
    nx_use_graph = nx_graph.copy()

    for edge in nx_graph.edges():
        path = nx.shortest_path(nx_mst_graph, edge[0], edge[1])
        if len(path) - 1 > max_path_len:
            ##print "path greather than max.  It's ", len(path)
            nx_use_graph.remove_edge(edge[0], edge[1])
    '''

    ## it gets the communities as pairs, splitting up the previous communities into smaller communities on each iteration.
    ## How do I use that for a graph?

    ## draw edges between elements in each community recursively? 

    ## Have smallest elements point to combined group above them, until reaches top
    ## and then what?  Should be able to apply some kind of treemap to it

    # convert to tulip
    sys.stderr.write('converting to tulip\n')
    tlp_graph = tlp.newGraph()
    tlp_name_to_id = {}
    tlp_id_to_name = {}
    for node in nx_use_graph.nodes():
        id = tlp_graph.addNode()
        tlp_name_to_id[node] = id
        tlp_id_to_name[id] = node
    for edge in nx_use_graph.edges():
        tlp_graph.addEdge(tlp_name_to_id[edge[0]], tlp_name_to_id[edge[1]])



    # do layout -  TODO: MIGHT WANT TO USE THIS LAYOUT OR PASS IT BACK TO layout_tulip
    
    sys.stderr.write('doing layout\n')
    layout_alg = 'MMM Example Fast Layout (OGDF)'
    view_layout = tlp_graph.getLayoutProperty('viewLayout')
    tlp_graph.applyLayoutAlgorithm(layout_alg, view_layout)


    ##tlp_graph.delEdges(tlp_graph.getEdges(), True)
    ##for edge in nx_graph.edges():
    ##   tlp_graph.addEdge(tlp_name_to_id[edge[0]], tlp_name_to_id[edge[1]])


    # get a dictionnary filled with the default plugin parameters values
    # graph is an instance of the tlp.Graph class
    params = tlp.getDefaultPluginParameters('JSON Export', tlp_graph)

    # set any input parameter value if needed   
    # params['Beautify JSON string'] = ...

    success = tlp.exportGraph('JSON Export', tlp_graph, outputFile, params)
        

    '''
    for node in tlp_graph.getNodes():
        name = tlp_id_to_name[node]
        pos = '%f,%f!' % (scale * view_layout[node][0], scale * view_layout[node][1])
        ##dot_graph.get_node(name)[0].set_pos(pos)
        nh = gv.findnode(gv_graph, name)
        gv.setv(nh, 'pos', pos)

    # print new dot graph
    sys.stderr.write('writing\n')
    ##print dot_graph.to_string()
    gv.write(gv_graph, 'out.dot')
    '''
