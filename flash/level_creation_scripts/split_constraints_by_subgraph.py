import os
from load_constraints_graph import *
from operator import itemgetter

def split_constraints_by_subgraph(infilename, outfilename):
	nodes, edges, assignments = load_constraints_graph(infilename)
	print 'Splitting into subgraphs...'
	touched_nodes = {}
	subgraphs = []
	for nodeid in nodes:
		if touched_nodes.get(nodeid) is not None:
			continue
		current_graph = {'nodes': {},  'edges': {}, 'adjustable_nodes': 0}
		node = nodes.get(nodeid)
		subgraph_node_queue = [node]
		while len(subgraph_node_queue) > 0:
			next_node = subgraph_node_queue.pop()
			if touched_nodes.get(next_node.id) is not None:
				continue
			touched_nodes[next_node.id] = True
			current_graph['nodes'][next_node.id] = next_node
			if not next_node.isconstant:
				current_graph['adjustable_nodes'] += 1
			for edge_id in next_node.inputs:
				next_node_edge = next_node.inputs[edge_id]
				current_graph['edges'][edge_id] = next_node_edge
				subgraph_node_queue.append(next_node_edge.fromnode)
			for edge_id in next_node.outputs:
				next_node_edge = next_node.outputs[edge_id]
				current_graph['edges'][edge_id] = next_node_edge
				subgraph_node_queue.append(next_node_edge.tonode)
		print 'Gathered subgraph with %s adjustable nodes' % current_graph['adjustable_nodes']
		subgraphs.append(current_graph)
	print 'Split into %s subgraphs.' % len(subgraphs)
	# Sort by number of adjustable nodes (least -> most)
	sorted_subgraphs = sorted(subgraphs, key=itemgetter('adjustable_nodes'))
	# Output graphs
	# Create subgraphs directory (if none exists)
	dir = os.path.dirname('%s_subgraphs/' % infilename)
	if not os.path.exists(dir):
		os.makedirs(dir)
	nlevels = len(sorted_subgraphs)
	digits = '%s' % len('%s' % nlevels)
	for i, subgraph in enumerate(sorted_subgraphs):
		levelid = ('L%0' + digits + 'd_V%s') % (i, subgraph['adjustable_nodes'])
		# TODO: write subgraph constraints json
		with open('%s/%sAssignments.json' % (dir, levelid),'w') as writeasg:
			writeasg.write('{"id": "%s",\n' % levelid)
			writeasg.write('"assignments":{\n')
			firstline = True
			for varid in assignments:
				if firstline == True:
					firstline = False
				else:
					writeasg.write(',\n')
				writeasg.write('"%s":%s' % (varid, json.dumps(assignments[varid], separators=(',', ':')))) # separators: no whitespace
			writeasg.write('}\n}')
	
### Command line interface ###
if __name__ == "__main__":
	if len(sys.argv) != 2 and len(sys.argv) != 3:
		print ('\n\nUsage: %s input_file [output_file]\n\n'
		'  input_file: name of INPUT constraint .json to be laid out,\n'
		'    omitting ".json" extension\n\n'
		'  output_file: (optional) OUTPUT constraints subgraph .json files \n'
		'    file name prefix, if none provided use input_file name'
		'\n' % sys.argv[0])
		quit()
	infile = sys.argv[1]
	if len(sys.argv) == 2:
		outfile = sys.argv[1]
	split_constraints_by_subgraph(infile, outfile)