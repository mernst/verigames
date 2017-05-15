import networkx as nx
import cPickle, json, os, sys
import _util, layout_util
#import mst_layout
#import partition
#import exportTulipJson
#import fastCommunityPartition
import bottomUpLayout
import collections

NODE_SIZE = 5.0

def layout_with_tulip(Gs, constraintMapFile, outputFile):
    from tulip import tlp
    i = 1;
    for G in Gs:
        _util.print_step('Laying out %s...' % G.graph.get('id', ''))

        # set up tulip graph
        tlp_graph = tlp.newGraph()
        tlp_name_to_id = {}
        tlp_id_to_name = {}
        tlp_id_to_order = {}
        tlp_order_to_id = {}
        numNodes = 0
        for node in G.nodes():
            id = tlp_graph.addNode()
            tlp_name_to_id[node] = id
            tlp_id_to_name[id] = node

            tlp_id_to_order[id] = i
            tlp_order_to_id[i] = id
            numNodes += 1
        print("in between")

        for edge in G.edges():
            tlp_graph.addEdge(tlp_name_to_id[edge[0]], tlp_name_to_id[edge[1]])

        if numNodes > 50000:
            algorithmToUse =  'Fast Multipole Embedder (OGDF)'
        else:
            algorithmToUse = 'FM^3 (OGDF)'      
        ## Pick algorithm based on size. 

        # do layout
        view_size = tlp_graph.getSizeProperty('viewSize')
        print("going through all nodes")
        for n in tlp_graph.getNodes():
            view_size[n] = tlp.Size(NODE_SIZE, NODE_SIZE, 1)

        view_layout = tlp_graph.getLayoutProperty('viewLayout')

        params = tlp.getDefaultPluginParameters(algorithmToUse, tlp_graph)

        ## TO TRY for 'Fast Multipole Embedder (OGDF)'
        ##params['default node size'] = 5
        #params['number of iterations'] = 20
        #params['number of coefficients'] = 2

        params['New initial placement'] = False

        for len_scale in [1, 2, 4, 6, 8, 10, 12, 14, 16]:
            print("laying out with scale: ", len_scale)

            params['Unit edge length'] = NODE_SIZE * len_scale
            tlp_graph.applyLayoutAlgorithm(algorithmToUse, view_layout, params)

            pre_positions = {}
            for node in tlp_graph.getNodes():
                pre_positions[node] = (view_layout[node][0], view_layout[node][1])

            tlp_graph.applyLayoutAlgorithm('Fast Overlap Removal', view_layout)

            change_accum = 0.0
            change_count = 0
            for node in tlp_graph.getNodes():
                pre = pre_positions[node]
                post = (view_layout[node][0], view_layout[node][1])
                change_accum += (pre[0] - post[0]) ** 2 + (pre[1] - post[1]) ** 2
                change_count += 1
            change_ave = (change_accum / change_count) ** 0.5

            print '****************************** -- ', change_ave
            if change_ave <= 0.5 * NODE_SIZE:
                break;


        bottomUpLayout.layout(tlp_graph, constraintMapFile, view_layout, tlp_id_to_name, tlp_name_to_id, outputFile  + '.json') 
        '''
        # update original graph
        node_layout = {}
        for node in tlp_graph.getNodes():
            name = tlp_id_to_name[node]
            node_layout[name.replace(':', '_')] = (view_layout[node][0], view_layout[node][1])

        layout_util.add_layout_to_graph(G, node_layout)

        
        # get a dictionnary filled with the default plugin parameters values
        # graph is an instance of the tlp.Graph class
        params = tlp.getDefaultPluginParameters('JSON Export', tlp_graph)

        # set any input parameter value if needed   
        # params['Beautify JSON string'] = ...

        success = tlp.exportGraph('JSON Export', tlp_graph, outputFile + str(i) + '.json', params)
        '''
        i = i + 1
        

def run(infile, constraintMapFile, outfile, skip_if_trivial, node_min, node_max, show_labels):
    _util.print_step('loading')

    with open(infile, 'rb') as read_in:
        Gs = cPickle.load(read_in)

    _util.print_step('laying out')

    layout_with_tulip(Gs, constraintMapFile, outfile)

    _util.print_step('saving')
    
    with open(infile, 'wb') as write_out:
        cPickle.dump(Gs, write_out, cPickle.HIGHEST_PROTOCOL)

    _util.print_step(None)


### Command line interface ###
if __name__ == "__main__":
    if len(sys.argv) != 6:
        print 'Usage: %s infile outfile show_labels[0/1] node_min node_max' % sys.argv[0]
        quit()
    infile = sys.argv[1]
    outfile = sys.argv[2]
    show_labels = sys.argv[3]
    node_min = sys.argv[4]
    node_max = sys.argv[5]
    run(infile, outfile, True, show_labels, node_min, node_max)
