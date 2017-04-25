import sys
#import itertools
import math
import json, os
##import layout_tulip


botLeft = [0,0] ## bot left corner
topRight = [10, 10] ## top right - have to base on avg screen eventually

## root starts as Group0 from partition.py

## Each nodegroup in nodeGroupMap has botleft and topright corner of square now.  And the single nodes have positions inside the square of parent group

def Treemap(root, botLeft, topRight, axis, color, nodeGroupMap):
    nodeRoot = nodeGroupMap[root]

    ## Paint Rectangle(P, Q, color)
    nodeGroupMap[root]["botLeft"] = botLeft  ## size is for actual size of circular node?  We do want size for nodegroups if they're currently visible as abstraction
    nodeGroupMap[root]["topRight"] = topRight
    #nodeGroupMap[root]["position"] = mid point

    ## could calculate size based on min of width and height, and do like 2/3 of that or something
    ## think about whether if we have really narrow slits in one directon but very long in another, that'll create very small circles - is that bad? 

    if nodeRoot.has_key("children"):
        width = topRight[axis] - botLeft[axis]

        ## how to change color

        for child in nodeRoot["children"]:
            nodeChild = NodeGroupMap[child] 
            topRight[axis] = botLeft[axis] + (nodeChild["numLeafNodes"]/nodeRoot["numLeafNodes"]) * width ## might want all children not just numLeafNodes
            Treemap(child, botLeft, topRight, (axis + 1) % 2, color, nodeGroupMap)
            botLeft[axis] = topRight[axis];

