import networkx as nx
import cPickle, json, os, sys
import _util, layout_util
import mst_layout
import partition

NODE_SIZE = 5.0

def layout_with_tulip(Gs, outputFile):
    from tulip import tlp
    i = 1;
    for G in Gs:
        _util.print_step('Laying out %s...' % G.graph.get('id', ''))

        # set up tulip graph
        tlp_graph = tlp.newGraph()
        tlp_name_to_id = {}
        tlp_id_to_name = {}
        for node in G.nodes():
            id = tlp_graph.addNode()
            tlp_name_to_id[node] = id
            tlp_id_to_name[id] = node
        for edge in G.edges():
            tlp_graph.addEdge(tlp_name_to_id[edge[0]], tlp_name_to_id[edge[1]])

        ##tlp_graph = mst_layout.run_it(tlp_graph, 1, outputFile + str(i) + '.json')
        ##tlp_graph = partition.partition_it(tlp_graph, tlp_id_to_name, outputFile  + '.json')  # + str(i) + add tulip to name if you want
        
        ## will need a way to take cluster info from partition.py so that you can have that incorporated into layout.
        ## might be best to use this low level layout as guideline, and then c# code adjusts everything to make sure it makes sense


        # do layout
        view_size = tlp_graph.getSizeProperty('viewSize')
        for n in tlp_graph.getNodes():
            view_size[n] = tlp.Size(NODE_SIZE, NODE_SIZE, 1)

        view_layout = tlp_graph.getLayoutProperty('viewLayout')

        params = tlp.getDefaultPluginParameters('FM^3 (OGDF)', tlp_graph)
        params['New initial placement'] = False

        for len_scale in [1, 2, 4, 6, 8, 10, 12, 14, 16]:
            params['Unit edge length'] = NODE_SIZE * len_scale
            tlp_graph.applyLayoutAlgorithm('FM^3 (OGDF)', view_layout, params)

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

        # update original graph
        node_layout = {}
        for node in tlp_graph.getNodes():
            name = tlp_id_to_name[node]
            node_layout[name.replace(':', '_')] = (view_layout[node][0], view_layout[node][1])

        layout_util.add_layout_to_graph(G, node_layout)

        tlp_graph = partition.partition_it(tlp_graph, view_layout, tlp_id_to_name, tlp_name_to_id, outputFile  + '.json')  # + str(i) + add tulip to name if you want

        '''
        # get a dictionnary filled with the default plugin parameters values
        # graph is an instance of the tlp.Graph class
        params = tlp.getDefaultPluginParameters('JSON Export', tlp_graph)

        # set any input parameter value if needed   
        # params['Beautify JSON string'] = ...

        success = tlp.exportGraph('JSON Export', tlp_graph, outputFile + str(i) + '.json', params)
        '''
        i = i + 1
        

def run(infile, outfile, skip_if_trivial, node_min, node_max, show_labels):
    _util.print_step('loading')

    with open(infile, 'rb') as read_in:
        Gs = cPickle.load(read_in)

    _util.print_step('laying out')

    layout_with_tulip(Gs, outfile)

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
