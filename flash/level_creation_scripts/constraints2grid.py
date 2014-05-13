import json, sys, os
from load_constraints_graph import *

# Width space given to each incoming/outgoing edge plus 1 unit on each end of a box of padding [][i0][i1]...[in][]
WIDTHPERPORT = 0.6
DECIMAL_PLACES = 2 # round all layout values to X decimal places
PAD_FACTOR = 2.0 # sfdp/prism tend to create tight layouts, this will multiply the width and height of the node by X to create more padding around nodes
class Point:
	def __init__(self, x, y):
		self.x = round(float(x), DECIMAL_PLACES)
		self.y = round(float(y), DECIMAL_PLACES)

def getportx(node, portnum):
	return node.pt.x - 0.5 * node.width + (1.5 + portnum) * WIDTHPERPORT

# get height of box used for dot to allow more vertical space based on number of boxlines passing thru
def getstaggeredlineheight(lineindex):
	return (lineindex * 0.75 + 0.75) / 2.0

def get_bonus(var_scoring, graph_scoring=None):
	type0_bonus = None
	type1_bonus = None
	if var_scoring is not None:
		type0_bonus = var_scoring.get('type:0')
		type1_bonus = var_scoring.get('type:1')
	if type0_bonus is None:
		if graph_scoring is not None and graph_scoring.get('type:0') is not None:
			type0_bonus = graph_scoring.get('type:0')
		else:
			type0_bonus = 0.0
	if type1_bonus is None:
		if graph_scoring is not None and graph_scoring.get('type:1') is not None:
			type1_bonus = graph_scoring.get('type:1')
		else:
			type1_bonus = 0.0
	if type0_bonus > type1_bonus:
		type0_bonus = type0_bonus - type1_bonus
		type1_bonus = 0.0
	elif type1_bonus > type0_bonus:
		type1_bonus = type1_bonus - type0_bonus
		type0_bonus = 0.0
	return type0_bonus, type1_bonus

# Main method to create layout, assignments files from constraint input json
def constraints2grid(infilename, outfilename, remove_graphviz_files=True):
	version, default_var_type, scoring, nodes, edges, assignments = load_constraints_graph(infilename)
	if scoring is None:
		scoring = {}
	n_vars = 0
	for n in nodes:
		if not nodes[n].isconstant:
			n_vars += 1
	# Determine starting score
	print 'Calculating starting score...'
	starting_score = 0
	default_constraint_pts = scoring.get('constraints', 0)
	default_var_value = 0
	if default_var_type == "type:1":
		default_var_value = 1
	weighted_dimacs_lines = []
	unweighted_dimacs_lines = []
	next_weighted_sat_var_index = 1
	next_unweighted_sat_var_index = 1
	weighted_var_keys = '' # list vars in order to correspond to var indexes in sat file
	unweighted_var_keys = ''
	next_weighted_sat_conjunc_index = 1
	next_unweighted_sat_conjunc_index = 1
	weighted_sat_var_dict = {}
	unweighted_sat_var_dict = {}
	# Calc nodes scores/output weighted SAT
	scored_nodes = {}
	for node_id in nodes:
		if scored_nodes.get(node_id, False):
			continue
		if nodes[node_id].isconstant:
			continue # no points for constants
		type0_bonus, type1_bonus = get_bonus(nodes[node_id].score, scoring.get('variables'))
		if type0_bonus > 0.0 or type1_bonus > 0.0:
			sat_index = weighted_sat_var_dict.get(node_id)
			if sat_index is None:
				sat_index = next_weighted_sat_var_index
				weighted_sat_var_dict[node_id] = sat_index
				weighted_var_keys += ' %s' % node_id[4:]
				next_weighted_sat_var_index += 1
			if type0_bonus > type1_bonus:
				bonus = type0_bonus
				sign = -1
			else:
				bonus = type1_bonus
				sign = 1
			weighted_dimacs_lines.append('%s %s 0\n' % (bonus, sign*sat_index))
			next_weighted_sat_conjunc_index += 1
		node_score = nodes[node_id].get_current_score(graph_var_default=default_var_value, graph_scoring=scoring)
		starting_score += node_score
		scored_nodes[node_id] = True
	# Calc constraints scores/output weighted SAT
	scored_edges = {}
	# For equalities we need two conjunctions (one of which must always be true) both for X pts so we end
	# up overcounting points by X for each equality contraint, keep track of this offset to add back after scoring
	equality_pts_offset = 0
	always_true_pts_offset = 0
	jams = 0
	for edge_id in edges:
		if scored_edges.get(edge_id, False):
			continue
		constr_points = default_constraint_pts
		if edges[edge_id].score is not None:
			constr_points = edges[edge_id].score
		lhs = edges[edge_id].fromnode
		rhs = edges[edge_id].tonode
		if lhs.isconstant and rhs.isconstant:
			# degenerate case
			continue
		weighted_lhs_sat_index = weighted_sat_var_dict.get(edges[edge_id].fromnode.id)
		if not lhs.isconstant and weighted_lhs_sat_index is None:
			weighted_lhs_sat_index = next_weighted_sat_var_index
			weighted_sat_var_dict[edges[edge_id].fromnode.id] = weighted_lhs_sat_index
			weighted_var_keys += ' %s' % edges[edge_id].fromnode.id[4:]
			next_weighted_sat_var_index += 1
		unweighted_lhs_sat_index = unweighted_sat_var_dict.get(edges[edge_id].fromnode.id)
		if not lhs.isconstant and unweighted_lhs_sat_index is None:
			unweighted_lhs_sat_index = next_unweighted_sat_var_index
			unweighted_sat_var_dict[edges[edge_id].fromnode.id] = unweighted_lhs_sat_index
			unweighted_var_keys += ' %s' % edges[edge_id].fromnode.id[4:]
			next_unweighted_sat_var_index += 1
		weighted_rhs_sat_index = weighted_sat_var_dict.get(edges[edge_id].tonode.id)
		if not rhs.isconstant and weighted_rhs_sat_index is None:
			weighted_rhs_sat_index = next_weighted_sat_var_index
			weighted_sat_var_dict[edges[edge_id].tonode.id] = weighted_rhs_sat_index
			weighted_var_keys += ' %s' % edges[edge_id].tonode.id[4:]
			next_weighted_sat_var_index += 1
		unweighted_rhs_sat_index = unweighted_sat_var_dict.get(edges[edge_id].tonode.id)
		if not rhs.isconstant and unweighted_rhs_sat_index is None:
			unweighted_rhs_sat_index = next_unweighted_sat_var_index
			unweighted_sat_var_dict[edges[edge_id].tonode.id] = unweighted_rhs_sat_index
			unweighted_var_keys += ' %s' % edges[edge_id].tonode.id[4:]
			next_unweighted_sat_var_index += 1
		if lhs.isconstant:
			if lhs.type_value == TYPE_0:
				if edges[edge_id].equality_constraint_twin is not None:
					# True if 0 == var
					weighted_dimacs_lines.append('%s -%s 0\n' % (constr_points, weighted_rhs_sat_index))
					next_weighted_sat_conjunc_index += 1
					unweighted_dimacs_lines.append('-%s 0\n' % unweighted_rhs_sat_index)
					next_unweighted_sat_conjunc_index += 1
				else:
					# Always true (0 <= var), generate no contraint
					always_true_pts_offset += constr_points
			elif lhs.type_value == TYPE_1:
				# True if var == 1 (1 <= var)
				weighted_dimacs_lines.append('%s %s 0\n' % (constr_points, weighted_rhs_sat_index))
				next_weighted_sat_conjunc_index += 1
				unweighted_dimacs_lines.append('%s 0\n' % unweighted_rhs_sat_index)
				next_unweighted_sat_conjunc_index += 1
			else:
				raise Exception('Constant found with unrecognized value: %s, %s' % (lhs.id, lhs.type_value))
		elif rhs.isconstant:
			if rhs.type_value == TYPE_0:
				# True if var == 0 (var <= 0)
				weighted_dimacs_lines.append('%s -%s 0\n' % (constr_points, weighted_lhs_sat_index))
				next_weighted_sat_conjunc_index += 1
				unweighted_dimacs_lines.append('-%s 0\n' % unweighted_lhs_sat_index)
				next_unweighted_sat_conjunc_index += 1
			elif rhs.type_value == TYPE_1:
				if edges[edge_id].equality_constraint_twin is not None:
					# True if var == 1
					weighted_dimacs_lines.append('%s %s 0\n' % (constr_points, weighted_lhs_sat_index))
					next_weighted_sat_conjunc_index += 1
					unweighted_dimacs_lines.append('%s 0\n' % unweighted_lhs_sat_index)
					next_unweighted_sat_conjunc_index += 1
				else:
					# Always true (var <= 1), generate no contraint
					always_true_pts_offset += constr_points
			else:
				raise Exception('Constant found with unrecognized value: %s, %s' % (rhs.id, rhs.type_value))
		else:
			# Generate constraint for a <= b: (!a or b)
			weighted_dimacs_lines.append('%s -%s %s 0\n' % (constr_points, weighted_lhs_sat_index, weighted_rhs_sat_index))
			next_weighted_sat_conjunc_index += 1
			unweighted_dimacs_lines.append('-%s %s 0\n' % (unweighted_lhs_sat_index, unweighted_rhs_sat_index))
			next_unweighted_sat_conjunc_index += 1
			if edges[edge_id].equality_constraint_twin is not None:
				# For equality, generate other constraint at the given score as well
				# Constraint: (!b or a)
				weighted_dimacs_lines.append('%s -%s %s 0\n' % (constr_points, weighted_rhs_sat_index, weighted_lhs_sat_index))
				next_weighted_sat_conjunc_index += 1
				unweighted_dimacs_lines.append('-%s %s 0\n' % (unweighted_rhs_sat_index, unweighted_lhs_sat_index))
				next_unweighted_sat_conjunc_index += 1
				equality_pts_offset -= constr_points
		constraint_score = edges[edge_id].get_current_score(graph_var_default=default_var_value, graph_scoring=scoring)
		starting_score += constraint_score
		if not edges[edge_id].get_currently_satisfied(default_var_value):
			jams += 1
		scored_edges[edge_id] = True
		if edges[edge_id].equality_constraint_twin is not None:
			scored_edges[edges[edge_id].equality_constraint_twin.id] = True
	print 'Found %s jams' % jams
	print 'Starting score: %s' % starting_score
	asg_filename = outfilename + 'Assignments.json'
	print 'Writing assignments file: %s' % asg_filename
	with open(asg_filename, 'w') as writeasg:
		writeasg.write('{"id": "%s",\n' % infilename)
		writeasg.write('"starting_score": %s,\n' % starting_score)
		writeasg.write('"starting_jams": %s,\n' % jams)
		writeasg.write('"assignments":{\n')
		firstline = True
		for varid in assignments:
			if firstline == True:
				firstline = False
			else:
				writeasg.write(',\n')
			writeasg.write('"%s":%s' % (varid, json.dumps(assignments[varid], separators=(',', ':')))) # separators: no whitespace
		writeasg.write('}\n}')
	# Create weighted wcnfs files for graphs with < 100 vars
	if jams == 0 or n_vars < 100:
		dimacs_filename = outfilename + '.wcnf'
		print 'Writing dimacs weighted sat file: %s' % dimacs_filename
		with open(dimacs_filename,'w') as writesat:
			writesat.write('c keys%s\n' % weighted_var_keys)
			writesat.write('c offset %s\n' % (equality_pts_offset + always_true_pts_offset))
			writesat.write('p wcnf %s %s\n' % (next_weighted_sat_var_index - 1, next_weighted_sat_conjunc_index - 1))
			for line in weighted_dimacs_lines:
				writesat.write('%s' % line)
	else:
		print 'Creating graphviz file...'
		# Create graphviz input file
		graphin =  'digraph G {\n'
		graphin += '  graph [\n'
		graphin += '    overlap="prism500",\n'
		graphin += '    splines="line"\n'
		graphin += '  ];\n'
		graphin += '  node [\n'
		graphin += '    label="",\n'
		graphin += '	fixedsize=true,\n'
		graphin += '	shape="rect"\n'
		graphin += '  ];\n'
		print 'Adding graphviz nodes...'
		# Nodes
		for nodeid in nodes:
			node = nodes[nodeid]
			node.width = round(float((max(1, node.ninputs + node.noutputs) + 2) * WIDTHPERPORT), DECIMAL_PLACES)
			calcheight = round(getstaggeredlineheight(node.ninputs) + getstaggeredlineheight(node.noutputs) + 1.0, DECIMAL_PLACES)
			graphin += '%s [width=%s,height=%s];\n' % (node.id, PAD_FACTOR*node.width, PAD_FACTOR*calcheight)
		print 'Adding graphviz edges...'
		# Edges
		for edgeid in edges:
			graphin += '%s;\n' % edgeid
		graphin += '}'
		with open(outfilename + '-IN.txt','w') as writegraph:
			writegraph.write(graphin)
		print 'Laying out with graphviz (sfdp)...'
		# Layout with graphviz
		with os.popen('sfdp -y -Tplain -o%s-OUT.txt %s-IN.txt' % (outfilename, outfilename)) as sfdpcmd:
			sfdpcmd.read()
		# Layout node positions from output
		print 'Reading in graphviz layout...'
		nodelayout = {}
		layoutf =  '{\n'
		layoutf += '"id": "%s",\n' % infilename
		layoutf += '"layout": {\n'
		layoutf += '  "vars": {\n'
		with open(outfilename + '-OUT.txt','r') as readgraph:
			firstline = True
			for line in readgraph:
				if len(line) < 4:
					continue
				if line[:4] == 'node':
					vals = line.split(' ')
					try:
						id = vals[1]
						node = nodes.get(id)
						if node is None:
							print 'Error parsing graphviz output node line: %s, couldn''t find node: %s' % (line, id)
						x = float(vals[2])
						y = float(vals[3])
						node.pt = Point(x, y)
						if nodelayout.get(node.id) is not None:
							print 'Warning! Multiple node lines found with same id: %s' % node.id
						nodelayout[node.id] = {'x': node.pt.x, 'y': node.pt.y, 'w':node.width, 'h': node.height}
						if firstline:
							firstline = False
						else:
							layoutf += ',\n'
						layoutf += '    "%s":%s' % (node.id, json.dumps(nodelayout[node.id], separators=(',', ':'))) # separators: no whitespace
					except Exception as e:
						print 'Error parsing graphviz output node line: %s -> %s' % (line, e)
					#print 'node id:%s x,y: %s,%s' % (id, x, y)
		layoutf += '\n  },\n' # end vars {}
		layoutf += '  "constraints": {\n'
		print 'Calculating final edge layout...'
		# Sort node inputs/outputs according to x positions
		for nodeid in nodes:
			node = nodes[nodeid]
			node.sortedges()
		edgelayout = {}
		firstline = True

		# Layout edges using node positions (ignore graphviz output)
		for nodeid in nodes:
			node = nodes[nodeid]
			alledges = node.sortedinputs + node.sortedoutputs# [1,2,3] + [4,5,6] = [1,2,3,4,5,6]
			for edge in alledges:
				if edgelayout.get(edge.id) is not None:
					# Already laid out, continue
					continue
				edge.pts = []
				startx = getportx(edge.fromnode, edge.fromport)
				starty = edge.fromnode.pt.y + 0.5 * edge.fromnode.height
				endx = getportx(edge.tonode, edge.toport)
				endy = edge.tonode.pt.y - 0.5 * edge.tonode.height
				edge.pts.append(Point(startx, starty))
				dy = getstaggeredlineheight(edge.fromport)
				edge.pts.append(Point(startx, starty + dy))
				edge.pts.append(Point(0.5 * (startx + endx), starty + dy))
				dy = getstaggeredlineheight(edge.toport)
				edge.pts.append(Point(0.5 * (startx + endx), endy - dy))
				edge.pts.append(Point(endx, endy - dy))
				edge.pts.append(Point(endx, endy))
				ptsjson = []
				for pt in edge.pts:
					ptsjson.append({"x":pt.x,"y":pt.y})
				edgelayout[edge.id] = {"pts": ptsjson}
				if firstline:
					firstline = False
				else:
					layoutf += ',\n'
				layoutf += '    "%s":%s' % (edge.id, json.dumps(edgelayout[edge.id], separators=(',', ':'))) # separators: no whitespace
		layoutf += '\n  }\n' # end constraints {}
		layoutf += '}}' # end layout {} file {}
		layout_filename = outfilename + 'Layout.json'
		if remove_graphviz_files:
			os.remove(outfilename + '-OUT.txt')
			os.remove(outfilename + '-IN.txt')
		print 'Writing layout file: %s' % layout_filename
		with open(layout_filename, 'w') as writelayout:
			writelayout.write(layoutf)
		dimacs_filename = outfilename + '.cnf'
		print 'Writing dimacs unweighted sat file: %s' % dimacs_filename
		with open(dimacs_filename, 'w') as writesat:
			writesat.write('c keys%s\n' % unweighted_var_keys)
			writesat.write('c offset %s\n' % (equality_pts_offset + always_true_pts_offset))
			writesat.write('p cnf %s %s\n' % (next_unweighted_sat_var_index - 1, next_unweighted_sat_conjunc_index - 1))
			for line in unweighted_dimacs_lines:
				writesat.write(line)
	print '------------'

### Command line interface ###
if __name__ == "__main__":
	if len(sys.argv) != 2 and len(sys.argv) != 3:
		print ('\n\nUsage: %s input_file [output_file]\n\n'
		'  input_file: name of INPUT constraint .json to be laid out,\n'
		'    omitting ".json" extension\n\n'
		'  output_file: (optional) OUTPUT (Constraints/Layout) .json \n'
		'    file name prefix, if none provided use input_file name'
		'\n' % sys.argv[0])
		quit()
	infile = sys.argv[1]
	if len(sys.argv) == 2:
		outfile = sys.argv[1]
	constraints2grid(infile, outfile)