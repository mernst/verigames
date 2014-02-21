import json, sys, os
from load_constraints_graph import *

# Width space given to each incoming/outgoing edge plus 1 unit on each end of a box of padding [][i0][i1]...[in][]
WIDTHPERPORT = 0.6
DECIMAL_PLACES = 2 # round all layout values to X decimal places

class Point:
	def __init__(self, x, y):
		self.x = round(float(x), DECIMAL_PLACES)
		self.y = round(float(y), DECIMAL_PLACES)

def getportx(node, portnum):
	return node.pt.x - 0.5 * node.width + (1.5 + portnum) * WIDTHPERPORT

# get height of box used for dot to allow more vertical space based on number of boxlines passing thru
def getstaggeredlineheight(lineindex):
	return (lineindex * 0.75 + 0.75) / 2.0

# Main method to create layout, assignments files from constraint input json
def constraints2grid(infilename, outfilename):
	version, scoring, nodes, edges, assignments = load_constraints_graph(infilename)
	print 'Creating graphviz file...'
	# Create graphviz input file
	graphin =  'digraph G {\n'
	graphin += '  graph [\n'
	graphin += '    overlap="scalexy",\n'
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
		graphin += '%s [width=%s,height=%s];\n' % (node.id, node.width, calcheight)
	print 'Adding graphviz edges...'
	# Edges
	for edgeid in edges:
		graphin += '%s;\n' % edgeid
	graphin += '}'
	with open(outfilename + '-IN.txt','w') as writegraph:
		writegraph.write(graphin)
	print 'Layout with graphviz (sfdp)...'
	# Layout with graphviz
	with os.popen('sfdp -y -Tplain -o%s-OUT.txt %s-IN.txt' % (outfilename, outfilename)) as sfdpcmd:
		sfdpcmd.read()
	# Layout node positions from output
	print 'Read in graphviz layout...'
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
	print 'Calculate final edge layout...'
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
	print 'Write layout file: %sLayout.json' % outfilename
	with open(outfilename + 'Layout.json','w') as writelayout:
		writelayout.write(layoutf)
	print 'Write assignments file: %sAssignments.json' % outfilename
	with open(outfilename + 'Assignments.json','w') as writeasg:
		writeasg.write('{"id": "%s",\n' % infilename)
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
		'  output_file: (optional) OUTPUT (Constraints/Layout) .json \n'
		'    file name prefix, if none provided use input_file name'
		'\n' % sys.argv[0])
		quit()
	infile = sys.argv[1]
	if len(sys.argv) == 2:
		outfile = sys.argv[1]
	constraints2grid(infile, outfile)