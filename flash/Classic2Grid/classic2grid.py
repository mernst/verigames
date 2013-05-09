import sys
from xml.dom.minidom import parse

### Classes ###
# Port contains this info: portnum, edgeid, nodeid
class Port:
	def __init__(self, port, edge, node):
		self.portnum = port
		self.edgeid = edge
		self.nodeid = node


### Dictionaries ###
# boardedges[levelname][boardname][0][portnum] = incoming port
# boardedges[levelname][boardname][1][portnum] = outgoing port
boardedges = {}

# edgesets[edgeid][0] = edge set id
# edgesets[edgeid][1] = edge set port
edgesets = {}

# numedgesetedges[edgesetid] = # of edgerefs in this edge-set
numedgesetedges = {}

# extraedgesetlines[edgesetid] = Array of extra lines generated from SUBBOARD nodes connecting to INCOMING/OUTGOING edges
extraedgesetlines = {}

# nodekinds[nodeid] = node kind
nodekinds = {}

### Helper functions ###
# Safely add an edge port to the boardedges dictionary
def addboardedge(lname, bname, inout, port):
	boards = boardedges.get(lname)
	if boards is None:
		boards = {}
	board = boards.get(bname)
	if board is None:
		board = {}
	ports = board.get(inout)
	if ports is None:
		ports = {}
	ports[port.portnum] = port
	board[inout] = ports
	boards[bname] = board
	boardedges[lname] = boards

# Safely get an edge port from the boardedges dictionary
def getboardedge(lname, bname, inout, portnum):
	boards = boardedges.get(lname)
	if boards is None:
		return None
	board = boards.get(bname)
	if board is None:
		return None
	ports = board.get(inout)
	if ports is None:
		return None
	port = ports.get(portnum)
	if ports is None:
		return None
	return port

# Output joint XML for a given SUBBOARD node's input or output port
def port2joint(nid, input, portnum, edgeid, otherlineid=None):
	suffix = '__OUT__'
	inputs = 0
	outputs = 0
	if input:
		inputs = 1
		suffix = '__IN__'
		if otherlineid:
			outputs = 1
	else:
		outputs = 1
		if otherlineid:
			inputs = 1
	jointid = nid + suffix + portnum
	out = '    <joint id="%s" inputs="%s" outputs="%s"/>\n' % (jointid, inputs, outputs)
	return out

# Create the line XML for a line leading from a joint to a box
def makeline2box(lineid, fromnid, fromport, setid, setport):
	out =  '    <line id="%s">\n' % lineid
	out += '      <fromjoint id="%s" port="%s"/>\n' % (fromnid, fromport)
	out += '      <tobox id="%s" port="%s"/>\n' % (setid, setport)
	out += '    </line>\n'
	return out

# Create the line XML for a line leading from a box to a joint
def makeline2joint(lineid, tonid, toport, setid, setport):
	out = '    <line id="%s">\n' % lineid
	out += '      <frombox id="%s" port="%s"/>\n' % (setid, setport)
	out += '      <tojoint id="%s" port="%s"/>\n' % (tonid, toport)
	out += '    </line>\n'
	return out

### Main function ###
if len(sys.argv) != 2:
	print 'Usage: %s [name of classic XML file to be parsed, omitting ".xml" extension]\nEx: To parse Test.xml run: %s Test' % (sys.argv[0], sys.argv[0])
	quit()
allxml = parse(sys.argv[1] + '.xml')
worlds = allxml.getElementsByTagName('world')
if len(worlds) != 1:
	print 'Warning: expecting 1 World, found %d, processing only the first World' % len(worlds)
wx = worlds[0]

# Step 1: Gather all board incoming/outgoing edges to fill boardedges dictionary
# TODO: this could be optimized to only process levels that occur as a SUBBOARD reference
for lx in wx.getElementsByTagName('level'):
	lname = lx.attributes['name'].value
	##print 'Level: %s' % lname
	for bx in lx.getElementsByTagName('board'):
		bname = bx.attributes['name'].value
		##print '  Board: %s' % bname
		for nx in bx.getElementsByTagName('node'):
			nid = nx.attributes['id'].value
			if nx.attributes['kind'].value.lower() == 'incoming':
				if len(nx.getElementsByTagName('output')) != 1:
					print 'Warning: found INCOMING node with # output tags !=1 node id: %s' % nid
					continue
				for px in nx.getElementsByTagName('output')[0].getElementsByTagName('port'):
					port = Port(px.attributes['num'].value, px.attributes['edge'].value, nid)
					addboardedge(lname, bname, 0, port)
			elif nx.attributes['kind'].value.lower() == 'outgoing':
				if len(nx.getElementsByTagName('input')) != 1:
					print 'Warning: found OUTGOING node with # input tags !=1 node id: %s' % nid
					continue
				for px in nx.getElementsByTagName('input')[0].getElementsByTagName('port'):
					port = Port(px.attributes['num'].value, px.attributes['edge'].value, nid)
					addboardedge(lname, bname, 1, port)
# Step 2: Convert line by line to Grid XML:
#	a) <node> becomes <joint>
#		* ids are all the same EXCEPT for SUBBOARD, INCOMING, OUTGOING
#		* These special <node>s generate one <joint> per
#		* input port and output port and connect to
#		* the corresponding incoming edge and outgoing
#		* edge that we've already gathered in the 
#		* boardedges dictionary.
#		* The corresponding ids looks like this:
#		* inputs: 'n751__IN__0', 'n751__IN__1', etc
#		* outputs: 'n751__IN__0', 'n751__IN__1', etc
#		* where n751 is the original node id for the
#		* SUBBOARD node
#   b) <edge-set> becomes <box> (same id used)
#	c) <edge> becomes 2 separate <line>s
#		* The <line> corresponding to the <edge> input
#		* with id = e1 (going from n1 to n2) would be:
#		*   <line id='e1__IN__'>
#		*     <fromjoint id='n1' port='0'/>
#		*     <tobox id='Application10' port='0'/> <!-- Links this line to the box (edge-set) id this pipe belongs to at port N -->
#		*   </line>
#		*   <line id='e1__OUT__'>
#		*     <frombox id='Application10' port='0'/> <!-- This should match port N above! -->
#		*     <tojoint id='n2' port='0'/>
#		*   </line>

# Output string:
out = '<?xml version="1.0" ?>\n'
out += '<graph id="world">\n'

for lx in wx.getElementsByTagName('level'):
	# Reset level-specific dictionaries
	edgesets = {}
	nodekinds = {}
	numedgesetedges = {}
	extraedgesetlines = {}
	# Node ids for SUBBOARDS, INCOMING, and OUTGOING nodes that correspond to multiple joints (instead of exactly one)
	lname = lx.attributes['name'].value
	out += '  <level id="Application">\n'
	# Gather the associated edge ids for edgesets dictionary
	for esx in lx.getElementsByTagName('edge-set'):
		edgesetid = esx.attributes['id'].value
		edgesetport = 0
		for ex in esx.getElementsByTagName('edgeref'):
			edgeid = ex.attributes['id'].value
			edgesets[edgeid] = []
			edgesets[edgeid].append(edgesetid)
			edgesets[edgeid].append(edgesetport)
			edgesetport += 1
		numedgesetedges[edgesetid] = edgesetport
	# 2a: Replace <node> with <joint>, making one <joint> per in/out for SUBBOARD, INCOMING, OUTGOING nodes
	# for subboards, also create lines between subboard joint and inner incoming/outgoing edges within the board
	extrasubboardlines = ""
	for nx in lx.getElementsByTagName('node'):
		nid = nx.attributes['id'].value
		kind = nx.attributes['kind'].value
		nodekinds[nid] = kind
		if (kind.lower() == 'subboard') or (kind.lower() == 'incoming') or (kind.lower() == 'outgoing'):
			# Process inputs, create new joint for each
			for px in nx.getElementsByTagName('input')[0].getElementsByTagName('port'):
				# If SUBBOARD, also create additional LINE (to be output later) from this joint to inner edge box
				if kind.lower() == 'subboard':
					boardname = nx.attributes['name'].value
					portnum = px.attributes['num'].value
					edgeport = getboardedge(lname, boardname, 0, portnum)
					if edgeport is None:
						print 'Edge not found for %s.%s input port #%s' % (lname, boardname, portnum)
						continue
					if edgesets.get(edgeport.edgeid) is None:
						print 'Edge set not found for edge: %s' % edgeport.edgeid
						continue
					setid = edgesets.get(edgeport.edgeid)[0]
					fromnid = nid + '__IN__' + portnum
					lineid = '%s___%s' % (fromnid, setid)
					if extraedgesetlines.get(setid) is None:
						extraedgesetlines[setid] = []
					setport = numedgesetedges[setid] + len(extraedgesetlines.get(setid))
					extraedgesetlines[setid].append(lineid)
					extrasubboardlines += makeline2box(lineid, fromnid, '0', setid, setport)
					out += port2joint(nid, True, px.attributes['num'].value, px.attributes['edge'].value, lineid)
				else:
					out += port2joint(nid, True, px.attributes['num'].value, px.attributes['edge'].value)
			# Process outputs, create new joint for each
			for px in nx.getElementsByTagName('output')[0].getElementsByTagName('port'):
				# If SUBBOARD, also create additional LINE (to be output later) from inner edge box to this joint
				if kind.lower() == 'subboard':
					boardname = nx.attributes['name'].value
					portnum = px.attributes['num'].value
					edgeport = getboardedge(lname, boardname, 1, portnum)
					if edgeport is None:
						print 'Edge not found for %s.%s output port #%s' % (lname, boardname, portnum)
						continue
					if edgesets.get(edgeport.edgeid) is None:
						print 'Edge set not found for edge: %s' % edgeport.edgeid
						continue
					setid = edgesets.get(edgeport.edgeid)[0]
					tonid = nid + '__OUT__' + portnum
					lineid = '%s___%s' % (setid, tonid)
					if extraedgesetlines.get(setid) is None:
						extraedgesetlines[setid] = []
					setport = numedgesetedges[setid] + len(extraedgesetlines.get(setid))
					extraedgesetlines[setid].append(lineid)
					extrasubboardlines += makeline2joint(lineid, tonid, '0', setid, setport)
					out += port2joint(nid, False, px.attributes['num'].value, px.attributes['edge'].value, lineid)
				else:
					out += port2joint(nid, False, px.attributes['num'].value, px.attributes['edge'].value)
		else:
			numinputs = len(nx.getElementsByTagName('input')[0].getElementsByTagName('port'))
			numoutputs = len(nx.getElementsByTagName('output')[0].getElementsByTagName('port'))
			out += '    <joint id="%s" inputs="%s" outputs="%s"/>\n' % (nid, numinputs, numoutputs)
	# 2b: Replace <edge-set> with <box> and gather the associated edge ids for edgesets dictionary
	for esx in lx.getElementsByTagName('edge-set'):
		edgesetid = esx.attributes['id'].value
		# The box will have X number of lines coming from the original edges of the edge set
		# PLUS any lines coming from other edge sets that connect thru SUBBOARD nodes
		extraports = 0
		if extraedgesetlines.get(edgesetid) is not None:
			extraports = len(extraedgesetlines.get(edgesetid))
		edgesetports = numedgesetedges[edgesetid] + extraports
		out += '    <box id="%s" lines="%s"/>\n' % (edgesetid, edgesetports)
	# 2c: Replace <edge> with __IN__ <line> and __OUT__ <line>
	for ex in lx.getElementsByTagName('edge'):
		edgeid = ex.attributes['id'].value
		if edgesets.get(edgeid) is None:
			print 'Warning: could not find edge-set for edge id: %s' % edgeid
			continue
		setid = edgesets.get(edgeid)[0]
		setport = edgesets.get(edgeid)[1]
		# Create line from top node (joint) to edge-set (box)
		fromlineid = edgeid + '__IN__'
		fromnodex = ex.getElementsByTagName('from')[0].getElementsByTagName('noderef')[0]
		fromnid = fromnodex.attributes['id'].value
		fromport = fromnodex.attributes['port'].value
		fromkind = nodekinds.get(fromnid)
		if fromkind is None:
			print 'Warning: could not find node kind for node id: %s' % fromnid
			continue
		if (fromkind.lower() == 'subboard') or (fromkind.lower() == 'incoming') or (fromkind.lower() == 'outgoing'):
			fromnid = fromnodex.attributes['id'].value + "__OUT__" + fromport
			fromport = '0'
		out += makeline2box(fromlineid, fromnid, fromport, setid, setport)
		# Create line from edge-set (box) to bottom node (joint)
		tolineid = edgeid + '__OUT__'
		tonodex = ex.getElementsByTagName('to')[0].getElementsByTagName('noderef')[0]
		tonid = tonodex.attributes['id'].value
		toport = tonodex.attributes['port'].value
		tokind = nodekinds.get(tonid)
		if tokind is None:
			print 'Warning: could not find node kind for node id: %s' % tonid
			continue
		if (tokind.lower() == 'subboard') or (tokind.lower() == 'incoming') or (tokind.lower() == 'outgoing'):
			tonid = tonodex.attributes['id'].value + "__IN__" + toport
			toport = '0'
		out += makeline2joint(tolineid, tonid, toport, setid, setport)
	# Output any additional subboard lines that we've been holding onto
	out += extrasubboardlines
	out += '  </level>\n'
out += '</graph>'
print out



#getboardedge(lev, bor, ind, portnum)