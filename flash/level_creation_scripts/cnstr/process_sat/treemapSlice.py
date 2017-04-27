import sys
#import itertools
import math
import random
import json, os
##import layout_tulip


minSize = 1
## have to base points on avg screen or unity coordinates eventually

## root starts as Group0 from partition.py

## Each nodegroup in nodeGroupMap has botleft and topright corner of square now.  And the single nodes have positions inside the square of parent group
## groups have positions and size too, but they're just centered in their rectangle, while single nodes can be wherever inside the rectangle

def treemap(root, botLeft, topRight, axis, color, nodeGroupMap):

    ##rootBotLeft = botLeft[:]
    ##rootTopRight = topRight[:]

    nodeRoot = nodeGroupMap[root]
    width = topRight[axis] - botLeft[axis]

    ## think about whether if we have really narrow slits in one directon but very long in another, that'll create very small circles - test it out and see.

    if not nodeRoot.has_key("children"):
        nodeGroupMap[root]["width"] = minSize
        nodeGroupMap[root]["height"] = minSize
        nodeGroupMap[root]["position"] = [random.randint(botLeft[0], topRight[0]), random.randint(botLeft[1], topRight[1])]

    else:
        nodeGroupMap[root]["width"] =  topRight[0] - botLeft[0] ## worry about height being smaller later.  Experiment with percentage of width or height
        nodeGroupMap[root]["height"] =  topRight[1] - botLeft[1]
        nodeGroupMap[root]["position"] = [(topRight[0] + botLeft[0])/2, (topRight[1] + botLeft[1])/2]
        nodeGroupMap[root]["botLeft"] = botLeft  ## size is for actual size of circular node.  We do want size for nodegroups if they're currently visible as abstraction
        nodeGroupMap[root]["topRight"] = topRight
        print("root", root, " TOPRIGHT: ", topRight, " BOTLEFT: ", botLeft, "WIDTH", width, " AXIS:", axis, " POS: ", nodeGroupMap[root]["position"])

        ## how to change color


        width = topRight[(axis + 1) % 2] - botLeft[(axis + 1) % 2]


        for child in nodeRoot["children"]:
            nodeChild = nodeGroupMap[child] 

            print("root ", nodeChild, "ratio: ", (nodeChild["numLeafNodes"]/float(nodeRoot["numLeafNodes"])), "width", width)
            topRight[(axis + 1) % 2] = int(botLeft[(axis + 1) % 2] + (nodeChild["numLeafNodes"]/float(nodeRoot["numLeafNodes"])) * width) ## might want all children not just numLeafNodes
            
            childBotLeft = botLeft[:]
            childTopRight = topRight[:]

            treemap(child, childBotLeft, childTopRight, (axis + 1) % 2, color, nodeGroupMap)
            botLeft[(axis + 1) % 2] = topRight[(axis + 1) % 2];

    return nodeGroupMap
