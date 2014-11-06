import networkx as nx
import cPickle, json, sys, os
import _util

def run(graphs_infile, game_files_directory, version, qids_start, node_limit):
    
    Gs = cPickle.load(open(graphs_infile, 'rb'))

    constraints_name = os.path.basename(graphs_infile).split('.')[0]
    
    if not os.path.isdir(game_files_directory):
        raise RuntimeError('game_files_directory is not a directory/does not exist: %s' % game_files_directory)

    current_qid = qids_start
    for Gi, G in enumerate(sorted(Gs)):
        n_vars = len([n for n in G.nodes() if n.startswith('var')])

        # Limit the number of nodes in a graph (if less than limit, don't produce dot file)
        if n_vars < node_limit:
            continue

        if not G.graph.has_key('id'):
            G.graph['id'] = 'p_%06d_%08d' % (n_vars, Gi)

        outfilename = game_files_directory + ('/%s.json' % G.graph['id'])
        out = open(outfilename, 'w')
        out.write('''
{
  "id": "%s",
  "qid": %s,
  "version": "%s",
  "default": "type:1",
  "scoring": {
    "variables": {"type:0": 0, "type:1": 0},
    "constraints": 1
  },
  "variables":{},
  "constraints":[
    ''' % (G.graph['id'], current_qid, version))
        comma = ''
        for edge_parts in G.edges():
            from_n = edge_parts[0].replace('clause', 'c')
            to_n = edge_parts[1].replace('clause', 'c')
            out.write('%s"%s <= %s"' % (comma, from_n, to_n))
            comma = ',\n    '
        out.write(']\n}')
        out.close()

        asg_outfilename = game_files_directory + ('/%sAssignments.json' % G.graph['id'])
        out = open(asg_outfilename, 'w')
        out.write('''
{
  "id": "%s",
  "qid": %s,
  "assignments":{
  }
}''' % (G.graph['id'], current_qid))
        out.close()

        layout_outfilename = game_files_directory + ('/%sLayout.json' % G.graph['id'])
        out = open(layout_outfilename, 'w')
        out.write('''
{
  "id": "%s",
  "layout": {
    "vars": {
      ''' % G.graph['id'])
        comma = ''
        for node_id in G.nodes():
            node = G.node[node_id]
            if node.get('x') is None or node.get('y') is None:
                print 'Warning! Node found without layout info: %s' % node_id
                continue
            node_id_ = node_id.replace(':', '_').replace('clause_', 'c_')
            out.write('%s"%s":{"x":%s,"y":%s}' % (comma, node_id_, node.get('x'), node.get('y')))
            comma = ',\n      '
        out.write('\n     }\n  }\n}')
        out.close()
        current_qid += 1



### Command line interface ###
if __name__ == "__main__":
    if len(sys.argv) != 6:
        print 'Usage: %s graphs_infile game_files_directory version qids_start node_limit' % sys.argv[0]
        quit()
    graphs_infile = sys.argv[1]
    game_files_directory = sys.argv[2]
    version = sys.argv[3]
    qids_start = sys.argv[4]
    node_limit = sys.argv[5]
    run(infile, outfile)