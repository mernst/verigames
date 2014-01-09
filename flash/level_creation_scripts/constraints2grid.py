import ijson, json, re, sys, os

# Width space given to each incoming/outgoing edge plus 1 unit on each end of a box of padding [][i0][i1]...[in][]
WIDTHPERPORT = 0.6
NODE_HEIGHT = 1.0
DECIMAL_PLACES = 2 # round all layout values to X decimal places

class Point:
	def __init__(self, x, y):
		self.x = round(float(x), DECIMAL_PLACES)
		self.y = round(float(y), DECIMAL_PLACES)

class Node:
	def __init__(self, id):
		self.id = id
		self.inputs = {}
		self.outputs = {}
		self.ninputs = 0
		self.noutputs = 0
		self.sortedinputs = None
		self.sortedoutputs = None
		self.pt = None
		self.width = None
		self.height = NODE_HEIGHT
		self.type_value = None
		self.keyfor_value = None
		self.default_value = None

	def addinput(self, edge):
		if self.inputs.get(edge.id) is None:
			self.ninputs += 1
			self.inputs[edge.id] = edge
			edge.tonode = self
	
	def addoutput(self, edge):
		if self.outputs.get(edge.id) is None:
			self.noutputs += 1
			self.outputs[edge.id] = edge
			edge.fromnode = self
	
	def sortedges(self):
		sortedin = []
		for edgeid in self.inputs:
			edge = self.inputs[edgeid]
			if edge.fromnode is None:
				print 'Error: disconnected edge found. Edge id: %s' % edgeid
				continue
			if edge.fromnode.pt is None:
				print 'Error: non-laid-out node found after graphviz call. Node id: %s' % edge.fromnode.id
				continue
			sortedin.append((edge.fromnode.pt.x, edge.id))
		sortedin = sorted(sortedin)
		self.sortedinputs = [self.inputs.get(n[1]) for n in sortedin]
		p = 0
		for edge in self.sortedinputs:
			edge.toport = p
			p += 1
		sortedout = []
		for edgeid in self.outputs:
			edge = self.outputs[edgeid]
			if edge.tonode is None:
				print 'Error: disconnected edge found. Edge id: %s' % edgeid
				continue
			if edge.tonode.pt is None:
				print 'Error: non-laid-out node found after graphviz call. Node id: %s' % edge.tonode.id
				continue
			sortedout.append((edge.tonode.pt.x, edge.id))
		sortedout = sorted(sortedout)
		self.sortedoutputs = [self.outputs.get(n[1]) for n in sortedout]
		p = 0
		for edge in self.sortedoutputs:
			edge.fromport = p
			p += 1

class Edge:
	def __init__(self, id):
		self.id = id
		self.pts = None
		self.fromnode = None
		self.tonode = None
		self.fromport = None
		self.toport = None
	
# Convert constraints (lhs and rhs) to nodes and edges suitable to graphviz
# For constants (type:0 or type:1) add suffix = var_## so that they are unique nodes
# Input: lhname:lhid <= rhname:rhid, i.e. type:0 <= var:23 ('type, '0', 'var', '23')
def constr2graph(lhname, lhid, rhname, rhid, nodedict, edgedict):
	if lhname == 'var' and rhname == 'type':
		lhs = '%s_%s' % (lhname, lhid)
		rhs = '%s_%s__%s' % (rhname, rhid, lhs)
	elif rhname == 'var' and lhname == 'type':
		rhs = '%s_%s' % (rhname, rhid)
		lhs = '%s_%s__%s' % (lhname, lhid, rhs)
	elif lhname == 'var' and rhname == 'var':
		lhs = '%s_%s' % (lhname, lhid)
		rhs = '%s_%s' % (rhname, rhid)
	else:
		print 'Warning! Unexpected constraint type (not var/var or var/type) = "%s". Ignoring...' % value
		return None
	# Get (or create) nodes
	fromnode = nodedict.get(lhs)
	if fromnode is None:
		fromnode = Node(lhs)
		nodedict[lhs] = fromnode
	tonode = nodedict.get(rhs)
	if tonode is None:
		tonode = Node(rhs)
		nodedict[rhs] = tonode
	# Get (or create) edge
	id = '%s -> %s' % (lhs, rhs)
	edge = edgedict.get(id)
	if edge is None:
		edge = Edge(id)
		edgedict[id] = edge
	# Connect edge to nodes
	fromnode.addoutput(edge)
	tonode.addinput(edge)

def getportx(node, portnum):
	return node.pt.x - 0.5 * node.width + (1.5 + portnum) * WIDTHPERPORT

# get height of box used for dot to allow more vertical space based on number of boxlines passing thru
def getstaggeredlineheight(lineindex):
	return (lineindex * 0.75 + 0.75) / 2.0

# Main method to create layout, assignments files from constraint input json
def constraints2grid(infilename, outfilename):
	regex1 = re.compile("(var|type):(.*) ?(<|=)= ?(var|type):(.*)", re.IGNORECASE)
	regex2 = re.compile("(var|type):(.*)", re.IGNORECASE)
	nodes = {}
	edges = {}
	assignments = {}
	parser = ijson.parse(open(infilename + '.json', 'r'))
	current_var = None
	current_asg = None
	for prefix, event, value in parser:
		#print 'prefix: %s event: %s value: %s' % (prefix, event, value)
		if (prefix, event) == ('constraints', 'start_array'):
			pass
		# Begin contraint array item processing
		# Format 1: "var:10 <= type:0"
		elif (prefix, event) == ('constraints.item', 'string'):
			try:
				matches = regex1.search(value).groups()
				lhname = matches[0].strip()
				lhid = matches[1].strip()
				rhname = matches[3].strip()
				rhid = matches[4].strip()
				constr_oper = matches[2].strip()
				constr2graph(lhname, lhid, rhname, rhid, nodes, edges)
				if constr_oper == '=':
					# For equality, add constraint in the other direction as well
					constr2graph(rhname, rhid, lhname, lhid, nodes, edges)
			except Exception as e:
				print 'Error parsing constraint: %s -> %s' % (value, e)
				continue
		# Format 2:  { "constraint": "subtype", "lhs": "var:1", "rhs": "var:2", "score": 100 }
		elif (prefix, event) == ('constraints.item', 'start_map'):
			constr2 = {} # open dict for storing constraint info
		elif (prefix, event) == ('constraints.item.lhs', 'string'):
			constr2['lhs'] = value
		elif (prefix, event) == ('constraints.item.rhs', 'string'):
			constr2['rhs'] = value
		elif (prefix, event) == ('constraints.item.constraint', 'string'):
			constr2['constr_oper'] = value
			if value != 'subtype' and value != 'equality':
				print 'Warning! Unsupported constraint type found: %s' % value
		elif (prefix, event) == ('constraints.item', 'end_map'):
			lhs = constr2.get('lhs')
			rhs = constr2.get('rhs')
			constr_oper = constr2.get('constr_oper')
			if lhs is not None and rhs is not None and constr_oper is not None:
				try:
					matches = regex2.search(lhs).groups()
					lhname = matches[0].strip()
					lhid = matches[1].strip()
					matches = regex2.search(rhs).groups()
					rhname = matches[0].strip()
					rhid = matches[1].strip()
				except Exception as e:
					print 'Error parsing constraint: %s %s %s -> %s' % (lhs, constr_oper, rhs, e)
					constr2 = None
					continue
				constr2graph(lhname, lhid, rhname, rhid, nodes, edges)
				if constr_oper == 'equality':
					# For equality, add constraint in the other direction as well
					constr2graph(rhname, rhid, lhname, lhid, nodes, edges)
			else:
				print 'Error parsing constraint: %s %s %s' % (lhs, constr_oper, rhs)
			constr2 = None
		# End Format 2
		elif (prefix, event) == ('constraints', 'end_array'):
			pass
		# End constraint array item processing
		# Begin variables processing
		elif (prefix, event) == ('variables', 'start_map'):
			current_var = None
		elif (prefix, event) == ('variables', 'map_key'):
			current_var = value
		elif current_var is not None:
			if (prefix, event) == ('variables.%s' % current_var, 'start_map'):
				if assignments.get(current_var) is not None:
					print 'Warning: multiple assignments found for same var: "%s"' % current_var
				assignments[current_var] = {}
			elif (prefix, event) == ('variables.%s.keyfor_value' % current_var, 'start_array'):
				if assignments[current_var].get('keyfor_value') is not None:
					print 'Warning: multiple keyfor_value arrays found for var: "%s"' % current_var
				assignments[current_var]['keyfor_value'] = []
			elif (prefix, event) == ('variables.%s.keyfor_value.item' % current_var, 'string'):
				assignments[current_var]['keyfor_value'].append(value)
			elif (prefix, event) == ('variables.%s.type_value' % current_var, 'string'):
				assignments[current_var]['type_value'] = value
			elif (prefix, event) == ('variables.%s' % current_var, 'end_map'):
				current_var = None
		elif (prefix, event) == ('variables', 'end_map'):
			current_var = None
		# End variables processing
		# Begin assignments processing
		elif (prefix, event) == ('assignments', 'start_map'):
			current_asg = None
		elif (prefix, event) == ('assignments', 'map_key'):
			current_asg = value
		elif current_asg is not None:
			if (prefix, event) == ('assignments.%s' % current_asg, 'start_map'):
				if assignments.get(current_asg) is not None:
					print 'Warning: multiple assignments found for same var: "%s"' % current_asg
				assignments[current_asg] = {}
			elif (prefix, event) == ('assignments.%s.keyfor_value' % current_asg, 'start_array'):
				if assignments[current_asg].get('keyfor_value') is not None:
					print 'Warning: multiple keyfor_value arrays found for var: "%s"' % current_asg
				assignments[current_asg]['keyfor_value'] = []
			elif (prefix, event) == ('assignments.%s.keyfor_value.item' % current_asg, 'string'):
				assignments[current_asg]['keyfor_value'].append(value)
			elif (prefix, event) == ('assignments.%s.type_value' % current_asg, 'string'):
				assignments[current_asg]['type_value'] = value
			elif (prefix, event) == ('assignments.%s' % current_asg, 'end_map'):
				current_asg = None
		elif (prefix, event) == ('assignments', 'end_map'):
			current_asg = None
		# End assignments processing
	# Create graphviz input file
	graphin =  'digraph G {\n'
	graphin += '  size="50,50";\n'
	graphin += '  graph [\n'
	graphin += '    splines=line\n'
	graphin += '  ];\n'
	graphin += '  node [\n'
	graphin += '    fontsize=6.0,\n'
	graphin += '	fixedsize=true,\n'
	graphin += '	height=1.0,\n'
	graphin += '	shape=rect\n'
	graphin += '  ];\n'

	# Nodes
	for nodeid in nodes:
		node = nodes[nodeid]
		node.width = round(float((max(node.ninputs, node.noutputs) + 2) * WIDTHPERPORT), DECIMAL_PLACES)
		graphin += '%s [width=%s];\n' % (node.id, node.width)
	# Edges
	for edgeid in edges:
		graphin += '%s;\n' % edgeid
	graphin += '}'
	with open(outfilename + '-IN.txt','w') as writegraph:
		writegraph.write(graphin)
	# Layout with graphviz
	with os.popen('sfdp -y -Tplain -o%s-OUT.txt -Tpdf -o%s-OUT.pdf %s-IN.txt' % (outfilename, outfilename, outfilename)) as sfdpcmd:
		sfdpcmd.read()
	# Layout node positions from output
	nodelayout = {}
	layoutf =  '{"layout": {\n'
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
	with open(outfilename + 'Layout.json','w') as writelayout:
		writelayout.write(layoutf)
	with open(outfilename + 'Assignments.json','w') as writeasg:
		writeasg.write('{"assignments":{\n')
		firstline = True
		for varid in assignments:
			if firstline == True:
				firstline = False
			else:
				writeasg.write(',\n')
			writeasg.write('{"%s":%s}' % (varid, json.dumps(assignments[varid], separators=(',', ':')))) # separators: no whitespace
		writeasg.write('\n}}')
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