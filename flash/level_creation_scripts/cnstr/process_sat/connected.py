import networkx as nx
import cPickle, json, os, sys
import _util



def run(infile, outfile):
    _util.print_step('loading')

    Gs = cPickle.load(open(infile, 'rb'))

    _util.print_step('computing weakly connected components')

    new_Gs = []
    for G in Gs:
        gen = nx.weakly_connected_component_subgraphs(G)
        for ge in gen:
            new_Gs.append(ge)
    Gs = new_Gs

    if False:
        new_Gs = []
        for G in Gs:
            if G.number_of_nodes() >= 15000:
                new_Gs.append(G)
                break
        Gs = new_Gs

    if True:
        szs = []

        for G in Gs:
            var_count = 0
            for node in G.nodes():
                if node.startswith('var:'):
                    var_count += 1
            szs.append((var_count))

        szs = sorted(szs)

        for sz in szs:
            print sz
        print '', len(Gs)

    _util.print_step('saving')

    cPickle.dump(Gs, open(outfile, 'wb'), cPickle.HIGHEST_PROTOCOL)

    _util.print_step(None)


### Command line interface ###
if __name__ == "__main__":
    infile = sys.argv[1]
    outfile = sys.argv[2]
    run(infile, outfile)