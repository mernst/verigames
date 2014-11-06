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
        node['x'] = layout_info[0]
        node['y'] = layout_info[1]

def layout_with_sfdp(dot_filename, Gs):
    with os.popen('sfdp -y -Tplain -o%s.out %s' % (dot_filename, dot_filename)) as sfdpcmd:
        _util.print_step('Laying out %s' % dot_filename)
        sfdpcmd.read()
    node_layout = {}
    with open('%s.out' % dot_filename) as dot_output:
        for line in dot_output:
            data = line.split(' ')
            if not data or len(data) < 4 or data[0] != 'node':
                continue
            if node_layout.get(data[1]):
                print 'Warning! Multiple layouts found for %s in %s.out' % (data[1], dot_filename)
            try:
                node_layout[data[1]] = [float(data[2]), float(data[3])]
            except Exception as e:
                print 'Warning! Error parsing layout for %s in %s:\n\n%s' % (data[1], dot_filename, e)
    for G in Gs:
        add_layout_to_graph(G, node_layout)
            

def layout_with_fruchterman_reingold(Gs):
    for G in Gs:
        _util.print_step('Laying out %s...' % G.graph.get('id', ''))
        node_layout = nx.fruchterman_reingold_layout(G)
        add_layout_to_graph(G, node_layout)
        

def run(infile, outfile, node_limit=0, SHOW_LABELS=False):
    _util.print_step('loading')

    out_is_folder = os.path.isdir(outfile)

    Gs = cPickle.load(open(infile, 'rb'))

    _util.print_step('outputting')

    total_conf = 0
    total_del = 0

    if SHOW_LABELS:
        label_txt = 'fontcolor="#888888"'
    else:
        label_txt = 'label=""'
    header = '''
digraph G {
  graph [ overlap="scalexy" penwidth="0.2" outputorder=edgesfirst size=10 sep="0.1" ]
  node [ shape="circle" style="filled" width="0.2" height="0.2" %s ]
    ''' % label_txt

    footer = '''
  { rank=source; type_1 }
  { rank=sink; type_0 }
}
'''

    if not out_is_folder:
        outfilename = outfile
        output = open(outfile, 'w')
        output.write(header)

    laid_out_Gs = []

    for Gi, G in enumerate(sorted(Gs)):
        to_del = {}
        n_vars = len([n for n in G.nodes() if n.startswith('var')])
        for node in G.nodes():
            if G.node[node].has_key('pseudo'):
                to_del[node] = True

        # Limit the number of nodes in a graph (if less than limit, don't produce dot file)
        if n_vars < node_limit:
            continue
        if n_vars > 20000:
            continue

        if not G.graph.has_key('id'):
            G.graph['id'] = 'p_%06d_%08d' % (n_vars, Gi)
        # Individual files per graph
        if out_is_folder:
            outfilename = outfile + ('/%s.dot' % G.graph['id'])
            _util.print_step('Writing %s' % outfilename)
            output = open(outfilename, 'w')
            output.write(header)

        total_del += len(to_del)
        for td in to_del.iterkeys():
            G.remove_node(td)

        edges = {}
        nodes_conf = {}
        edges_dbl = {}
        edges_conf = {}

        for edge in G.edges():
            back = (edge[1], edge[0])
            if edges.has_key(back):
                edges_dbl[back] = True
            else:
                edges[edge] = True

        if False: # enable to compute conflicts, will need node.value's first
            for edge in edges.iterkeys():
                double = edges_dbl.has_key(edge)

                if double:
                    if G.node[edge[0]]['value'] != G.node[edge[1]]['value']:
                        edges_conf[edge] = True
                        nodes_conf[edge[0]] = True
                        nodes_conf[edge[1]] = True
                else:
                    if G.node[edge[0]]['value'] == 'type:1' and G.node[edge[1]]['value'] == 'type:0':
                        edges_conf[edge] = True
                        nodes_conf[edge[0]] = True
                        nodes_conf[edge[1]] = True


        total_conf += len(edges_conf)

        if not out_is_folder:
            output.write('  subgraph {\n')

        for node in sorted(G.nodes()):
            conflict = nodes_conf.has_key(node)

            output.write('    ')
            output.write(node.replace(':', '_'))
            output.write(' [')

            if node.startswith('type:'):
                output.write(' shape="square"')

            if G.node[node].has_key('over'):
                output.write(' style="filled,dashed"')
            elif G.node[node].has_key('under'):
                output.write(' style="filled,dotted"')

            if False:#conflict:
                val = G.node[node]['value']
                if val == 'type:0':
                    output.write(' fillcolor="#ff8888"')
                elif val == 'type:1':
                    output.write(' fillcolor="#ff4444"')
                else:
                    raise RuntimeError('Unrecognized type ' + val)

                output.write(' color="#ff0000"')
                #output.write(' width="2.5"')
                #output.write(' height="2.5"')
            elif False: # values supplied
                val = G.node[node]['value']
                if val == 'type:0':
                    output.write(' fillcolor="#ffffff"')
                elif val == 'type:1':
                    output.write(' fillcolor="#444444"')
                else:
                    raise RuntimeError('Unrecognized type ' + val)

            output.write(' ]\n')

        for edge in sorted(edges.iterkeys()):
            double = edges_dbl.has_key(edge)
            conflict = edges_conf.has_key(edge)

            output.write('    ')
            output.write(edge[0].replace(':', '_'))
            output.write(' -> ')
            output.write(edge[1].replace(':', '_'))
            output.write(' [')
            if double:
                print 'Double found! This should have been removed in the input_cnstr stage...'
                output.write(' dir="both"')
            if conflict:
                output.write(' color="#ff0000"')
                output.write(' penwidth="5.0"')
                
            output.write(' ]\n')

        if out_is_folder:
            output.write(footer)
            output.close()
            layout_with_sfdp(outfilename, [G])
            #layout_with_fruchterman_reingold([G])
        else:
            output.write('  }\n')
            laid_out_Gs.append(G)

    if not out_is_folder:
        output.write(footer)
        output.close()
        layout_with_sfdp(outfilename, laid_out_Gs)

    cPickle.dump(Gs, open(infile, 'wb'), cPickle.HIGHEST_PROTOCOL)

    print 'conflicts', total_conf

    _util.print_step(None)


### Command line interface ###
if __name__ == "__main__":
    if len(sys.argv) != 5:
        print 'Usage: %s infile outfile show_labels[0/1] node_limit' % sys.argv[0]
        quit()
    infile = sys.argv[1]
    outfile = sys.argv[2]
    show_labels = sys.argv[3]
    node_limit = sys.argv[4]
    run(infile, outfile, show_labels, node_limit)