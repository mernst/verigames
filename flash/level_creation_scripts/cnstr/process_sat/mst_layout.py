import sys
from tulip import tlp
import networkx as nx
##import pydot
##import gv

'''
# process args
filename = sys.argv[1]
scale = 1
max_path_len = max(1, int(sys.argv[2]))


# load in dot file
sys.stderr.write('loading dot file\n')
##dot_graph = pydot.graph_from_dot_file(filename)
gv_graph = gv.read(filename)


# convert dot graph to networkx graph
sys.stderr.write('building graph\n')
nx_graph = nx.Graph()
##for node in dot_graph.get_nodes():
##    nx_graph.add_node(node.get_name())
##for edge in dot_graph.get_edges():
##    nx_graph.add_edge(edge.get_source(), edge.get_destination())
nh = gv.firstnode(gv_graph)
while nh:
    nx_graph.add_node(gv.nameof(nh))
    nh = gv.nextnode(gv_graph, nh)
eh = gv.firstedge(gv_graph)
while eh:
    nx_graph.add_edge(gv.nameof(gv.tailof(eh)), gv.nameof(gv.headof(eh)))
    eh = gv.nextedge(gv_graph, eh)
'''

def run_it(tlp_graph, max_path_len, outputFile):
    nx_graph = nx.Graph()

    for edge in tlp_graph.getEdges():
        nx_graph.add_edge(tlp_graph.source(edge), tlp_graph.target(edge))

    nx_use_graph = nx_graph
    #nx_graph.add_node(1)

    # get mst
    if max_path_len == 0:
        sys.stderr.write('skipping mst\n')
        nx_use_graph = nx_graph

    else:
        sys.stderr.write('computing mst\n')
        nx_mst_graph = nx.minimum_spanning_tree(nx_graph)

        nx_use_graph = nx_graph.copy()

        for edge in nx_graph.edges():
            path = nx.shortest_path(nx_mst_graph, edge[0], edge[1])
            if len(path) - 1 > max_path_len:
                ##print "path greather than max.  It's ", len(path)
                nx_use_graph.remove_edge(edge[0], edge[1])


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
