import networkx as nx
import cPickle, json, os, sys
import _util, layout_util


def layout_with_tulip(Gs):
    from tulip import tlp

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

        # do layout
        view_size = tlp_graph.getSizeProperty('viewSize')
        for n in tlp_graph.getNodes():
            view_size[n] = tlp.Size(3, 3, 1)

        view_layout = tlp_graph.getLayoutProperty('viewLayout')
        tlp_graph.applyLayoutAlgorithm('Fast Multipole Embedder (OGDF)', view_layout)
        tlp_graph.applyLayoutAlgorithm('Fast Overlap Removal', view_layout)

        # update original graph
        node_layout = {}
        for node in tlp_graph.getNodes():
            name = tlp_id_to_name[node]
            node_layout[name.replace(':', '_')] = (view_layout[node][0], view_layout[node][1])

        layout_util.add_layout_to_graph(G, node_layout)
        

def run(infile, outfile, skip_if_trivial, node_min, node_max, show_labels):
    _util.print_step('loading')

    with open(infile, 'rb') as read_in:
        Gs = cPickle.load(read_in)

    _util.print_step('laying out')

    layout_with_tulip(Gs)

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
