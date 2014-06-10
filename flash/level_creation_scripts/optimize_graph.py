import json, sys, os
from load_constraints_graph import *

def optimize_graph(infilename, outfilename):
	version, default_var_type, scoring, nodes, edges, groups, assignments = load_constraints_graph(infilename)
	group_indx = 0
	groups = {}
	node2group = {}
	n_edges_reduced = 0
	pass_num = 1
	while pass_num == 1 or n_edges_reduced > 0:
		n_edges_reduced = 0
		removed_edges = {}
		for edge_id in edges:
			edge = edges[edge_id]
			from_node = edge.fromnode
			to_node = edge.tonode
			if not from_node.isconstant and from_node.noutputs == 1 and not to_node.isconstant and to_node.ninputs == 1:
				# Case 1: Two nodes connected by one edge with no other edges coming in/out (respectively)
				# Remove the edge that joins them and group them together into one node
				from_group = node2group.get(from_node.id)
				if from_node.id[:4] == 'grp_':
					from_group = from_node
				to_group = node2group.get(to_node.id)
				if to_node.id[:4] == 'grp_':
					to_group = to_node
				if from_group is None and to_group is None:
					# Create new group
					group = Node('grp_%s' % group_indx, False)
					group_indx += 1
					groups[group.id] = group
					for input_id in from_node.inputs:
						group.addinput(from_node.inputs[input_id]) # this will also update the edge to reference this group node
					for output_id in to_node.outputs:
						group.addoutput(to_node.outputs[output_id]) # this will also update the edge to reference this group node
					node2group[from_node.id] = group
					node2group[to_node.id] = group
					group.grouped_nodes[from_node.id] = from_node
					group.grouped_nodes[to_node.id] = to_node
					if nodes.get(from_node.id) is not None:
						del nodes[from_node.id]
					if nodes.get(to_node.id) is not None:
						del nodes[to_node.id]
				elif from_group is None:
					# Move from_node into to_group
					group = to_group
					group.ninputs = 0
					group.inputs = {}
					for input_id in from_node.inputs:
						group.addinput(from_node.inputs[input_id]) # this will also update the edge to reference this group node
					node2group[from_node.id] = group
					group.grouped_nodes[from_node.id] = from_node
					if nodes.get(from_node.id) is not None:
						del nodes[from_node.id]
				elif to_group is None:
					# Move to_node into from_group
					group = from_group
					group.noutputs = 0
					group.outputs = {}
					for output_id in to_node.outputs:
						group.addoutput(to_node.outputs[output_id]) # this will also update the edge to reference this group node
					node2group[to_node.id] = group
					group.grouped_nodes[to_node.id] = to_node
					if nodes.get(to_node.id) is not None:
						del nodes[to_node.id]
				else:
					# Merge from_group into to_group
					group = to_group
					for grouped_node_id in from_group.grouped_nodes:
						to_group.grouped_nodes[grouped_node_id] = from_group.grouped_nodes[grouped_node_id]
						node2group[grouped_node_id] = to_group
					from_group.grouped_nodes = {}
					group.ninputs = 0
					group.inputs = {}
					for input_id in from_group.inputs:
						group.addinput(from_group.inputs[input_id]) # this will also update the edge to reference this group node
					if groups.get(from_group.id) is not None:
						del groups[from_group.id]
				n_edges_reduced += 1
				removed_edges[edge_id] = True
		# Remove edges from dict
		for edge_id in removed_edges:
			del edges[edge_id]
		print 'Pass %s removed %s edges' % (pass_num, n_edges_reduced)
		pass_num += 1
	with open('%s_OPT.json' % outfilename, 'w') as fout:
		fout.write('{"version": %s,\n' % version)
		# fout.write('"default_var_type": %s,\n' % default_var_type)
		# fout.write('"scoring": %s,\n' % json.dumps(scoring))
		# fout.write('"assignments": %s,\n' % json.dumps(assignments))
		# fout.write('"variables": {},\n')
		# fout.write('"id": "%s",\n' % infilename)
		fout.write('"groups": {\n')
		first = True
		for group_id in groups:
			if not first:
				fout.write(',\n')
			first = False
			fout.write('"%s": [' % groups[group_id].outputvarsimple())
			first_n = True
			for grouped_node_id in groups[group_id].grouped_nodes:
				if not first_n:
					fout.write(',')
				if grouped_node_id[:5] == 'type_':
					fout.write('"type:%s"' % grouped_node_id[5])
				else:
					fout.write('"%s"' % grouped_node_id.replace('_', ':'))
				first_n = False
			fout.write(']')
		fout.write('},\n')
		fout.write('"constraints": [\n')
		first = True
		for edge_id in edges:
			if not first:
				fout.write(',\n')
			first = False
			fout.write('"%s <= %s"' % (edges[edge_id].fromnode.outputvarsimple(), edges[edge_id].tonode.outputvarsimple()))
		fout.write(']}')


### Command line interface ###
if __name__ == "__main__":
	if len(sys.argv) != 2 and len(sys.argv) != 3:
		print ('\n\nUsage: %s input_file [output_file]\n\n'
		'  input_file: name of INPUT constraint .json to be optimized,\n'
		'    omitting ".json" extension\n\n'
		'  output_file: (optional) OUTPUT .json \n'
		'    file name prefix, if none provided use input_file name'
		'\n' % sys.argv[0])
		quit()
	infile = sys.argv[1]
	if len(sys.argv) == 2:
		outfile = sys.argv[1]
	optimize_graph(infile, outfile)