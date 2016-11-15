import networkx as nx
import cPickle, json, os, sys
import _util

def add_layout_to_graph(G, node_layout):
    for node_id in G.nodes():
        node = G.node[node_id]
        if node.has_key('x') or node.has_key('y'):
            print 'Warning! Node %s already has layout info: [%s, %s]' % (node_id, node.get('x', ''), node.get('y', ''))
        node_id_ = node_id.replace(':', '_')
        layout_info = node_layout.get(node_id_)
        if not layout_info:
            print 'Warning! No layout info found for node %s' % node_id_
            continue
        try:
            this_x = float(layout_info[0])
            this_y = float(layout_info[1])
        except:
            print 'Warning! Non-float x/y values found for node %s = (%s, %s)' % (node_id_, layout_info[0], layout_info[1])
            continue
        node['x'] = this_x
        node['y'] = this_y
        min_x = G.graph.get('min_x', this_x)
        max_x = G.graph.get('max_x', this_x)
        min_y = G.graph.get('min_y', this_y)
        max_y = G.graph.get('max_y', this_y)
        if this_x < min_x or G.graph.get('min_x') is None:
            G.graph['min_x'] = this_x
        if this_x > max_x or G.graph.get('max_x') is None:
            G.graph['max_x'] = this_x
        if this_y < min_y or G.graph.get('min_y') is None:
            G.graph['min_y'] = this_y
        if this_y > max_y or G.graph.get('max_y') is None:
            G.graph['max_y'] = this_y
    print 'Bounds: [%s, %s, %s, %s]' % (G.graph['min_x'], G.graph['min_y'], G.graph['max_x'], G.graph['max_y'])
