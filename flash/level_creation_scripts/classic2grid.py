import sys
from xml.dom import pulldom # used to put only one level at a time in memory (minidom can't handle extremely large worlds)
from xml.dom.minidom import parse, parseString, Document
from layoutgrid import layoutboxes, layoutlines
import logging

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

# boardstubwidths[boardname][0][portnum] = incoming port width ('narrow' or 'wide')
# boardstubwidths[boardname][1][portnum] = outgoing port width ('narrow' or 'wide')
boardstubwidths = {}

# stubboardxml[boardname] = Xml node containing stubboard, used to insert back into level referencing it
stubboardxml = {}

# stubboardlevels[bname] = name of level that board stub originally occurs in
stubboardlevels = {}

# edgesets[edgeid][0] = edge set id
# edgesets[edgeid][1] = edge set port
edgesets = {}

# varidsetedges[varID-set] = array of edgeids
varidsetedges = {}

# varidsetsxml[varID-setID] = xml of varidset
varidsetsxml = {}

# levelvaridsetedges[lname][varID-set] = array of edgeids for the given level name
levelvaridsetedges = {}

# varid2varidset[varID] = varid-set id
varid2varidset = {}

# edgeidtovarid[edgeid] = varid
edgeidtovarid = {}

# extraedgesetlines[edgevaridsetid] = Array of extra lines generated from SUBBOARD nodes connecting to INCOMING/OUTGOING edges
extraedgesetlines = {}

# varidsetwidth[edgevaridsetid] = isWide (Boolean)
varidsetwidth = {}

# varidseteditable[edgevaridsetid] = editable (Boolean)
varidseteditable = {}

# nodekinds[nodeid] = node kind
nodekinds = {}

# jointkinds[jointid] = node kind
jointkinds = {}

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
	if port is None:
		return None
	return port

# Safely add a stub port width to the boardstubwidths dictionary
def addstubport(bname, stubportnum, stubportwidth, inout):
	board = boardstubwidths.get(bname)
	if board is None:
		board = {}
	widths = board.get(inout)
	if widths is None:
		widths = {}
	widths[stubportnum] = stubportwidth
	board[inout] = widths
	boardstubwidths[bname] = board

# Safely get a stub port width from the boardstubwidths dictionary
def getstubwidth(bname, inout, portnum):
	board = boardstubwidths.get(bname)
	if board is None:
		return None
	widths = board.get(inout)
	if widths is None:
		return None
	width = widths.get(portnum)
	if width is None:
		return None
	return width


# Output joint id, XML for a given SUBBOARD node's input or output port
def port2joint(nid, kind, input, portnum, edgeid, otherlineid=None):
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
	out = '<joint id="%s" inputs="%s" outputs="%s" kind="%s"/>' % (jointid, inputs, outputs, kind)
	return [jointid, out]

# Create the line XML for a line leading from a joint to a box
def makeline2box(lineid, fromnid, fromport, varidsetid, setport):
	out =  '    <line id="%s">\n' % lineid
	out += '      <fromjoint id="%s" port="%s"/>\n' % (fromnid, fromport)
	out += '      <tobox id="%s" port="%s"/>\n' % (varidsetid, setport)
	out += '    </line>\n'
	return out

# Create the line XML for a line leading from a box to a joint
def makeline2joint(lineid, tonid, toport, varidsetid, setport):
	out = '    <line id="%s">\n' % lineid
	out += '      <frombox id="%s" port="%s"/>\n' % (varidsetid, setport)
	out += '      <tojoint id="%s" port="%s"/>\n' % (tonid, toport)
	out += '    </line>\n'
	return out

### Main function ###
def classic2grid(infile, outfile):
	logging.basicConfig(filename=('%s.info.log' % infile), level=logging.INFO)
	logging.basicConfig(filename=('%s.warnings.log' % infile), level=logging.WARNING)
	
	world = pulldom.parse('%s.xml' % infile)
	num = 0
	print('Gathering level subboards/varid-sets from XML.'),
	for event, node in world:
		if event != pulldom.START_ELEMENT:
			continue
		if node.tagName == 'level':
			num += 1
			if num % 10 == 0:
				print('.'),
				print('%s' % node.getAttribute('name')),
			try:
				world.expandNode(node)
				parseLevelBoardCalls(node)
			except Exception as e:
				logging.warning('Failed on level: %s -- %s' % (node.getAttribute('name'), e))
		elif node.tagName == 'varID-set':
			world.expandNode(node)
			parseVarIdSetXML(node)
	print ''
	print 'Gathered %s levels' % num
	
	print('Parsing level XML to grid.'),
	num = 0
	world2 = pulldom.parse('%s.xml' % infile)
	for event, node in world2:
		if event != pulldom.START_ELEMENT:
			continue
		if node.tagName == 'level':
			num += 1
			if num % 10 == 0:
				print('.'),
				print('%s' % node.getAttribute('name')),
			try:
				world2.expandNode(node)
				parseLevel(node)
			except Exception as e:
				logging.warning('Failed on level: %s -- %s' % (node.getAttribute('name'), e))
	print 'Output %s levels' % num
	print 'Outputting global constraints file: %sConstraints.xml ...' % outfile
	# Output constaints file portion for this level
	constraintout =  '<?xml version="1.0" ?>\n'
	constraintout += '<graph id="world" version="3">\n'
	for varidsetid in varidsetwidth:
		editablestr = '%s' % varidseteditable.get(varidsetid, 'false')
		constraintout += '    <box id="%s" width="%s" editable="%s"/>\n' % (varidsetid, varidsetwidth[varidsetid], editablestr.lower())
	constraintout += '</graph>'
	writeconstr = open(outfile + 'Constraints.xml','w')
	writeconstr.write(constraintout)
	writeconstr.close()
	#layoutboxes(outfile + 'Layout', outfile + 'Layout', True)
	#layoutlines(outfile + 'Layout', outfile + 'Layout', False) ## still too slow at the moment

def parseVarIdSetXML(varsetx):
	# Step 1a: Gather all varID-sets, varIDs, and edgeids associated with them
	# Initialize varidsetedges, varid2varidset
	varidvaridsetid = varsetx.attributes['id'].value
	if varidsetsxml.get(varidvaridsetid) is not None:
		logging.warning('!!! Warning! Multiple varidsets found with same id: %s' % varidvaridsetid)
	varidsetsxml[varidvaridsetid] = '%s' % varsetx.toxml()
	# varidsetedges[varID-set] = array of edgeids
	varidsetedges[varidvaridsetid] = []
	for varidx in varsetx.getElementsByTagName('varID'):
		varid = '%s' % varidx.attributes['id'].value
		# varid2varidset[varID] = varid-set id
		varid2varidset[varid] = varidvaridsetid
		
def parseLevelBoardCalls(lx):
	# Step 1b: Gather all board incoming/outgoing edges to fill boardedges dictionary
	# TODO: this could be optimized to only process levels that occur as a SUBBOARD reference
	lname = '%s' % lx.attributes['name'].value
	logging.info('parseLevelBoardCalls() Level: %s' % lname)
	for bx in lx.getElementsByTagName('board'):
		bname = '%s' % bx.attributes['name'].value
		for nx in bx.getElementsByTagName('node'):
			nid = '%s' % nx.attributes['id'].value
			if nx.attributes['kind'].value.lower() == 'incoming':
				if len(nx.getElementsByTagName('output')) != 1:
					logging.warning('Warning: found INCOMING node with # output tags !=1 node id: %s' % nid)
					continue
				for px in nx.getElementsByTagName('output')[0].getElementsByTagName('port'):
					port = Port('%s' % px.attributes['num'].value, '%s' % px.attributes['edge'].value, nid)
					addboardedge(lname, bname, 0, port)
			elif nx.attributes['kind'].value.lower() == 'outgoing':
				if len(nx.getElementsByTagName('input')) != 1:
					logging.warning('Warning: found OUTGOING node with # input tags !=1 node id: %s' % nid)
					continue
				for px in nx.getElementsByTagName('input')[0].getElementsByTagName('port'):
					port = Port('%s' % px.attributes['num'].value, '%s' % px.attributes['edge'].value, nid)
					addboardedge(lname, bname, 1, port)
	for bstubx in lx.getElementsByTagName('board-stub'):
		bname = '%s' % bstubx.attributes['name'].value
		if stubboardxml.get(bname) is not None:
			logging.warning('!!!Warning: found multiple boards with the same name: %s' % bname)
		stubboardxml[bname] = '%s' % bstubx.toxml()
		stubboardlevels[bname] = lname
		for instubx in bstubx.getElementsByTagName('stub-input')[0].getElementsByTagName('stub-connection'):
			stubportnum = '%s' % instubx.attributes['num'].value
			stubportwidth = '%s' % instubx.attributes['width'].value
			addstubport(bname, stubportnum, stubportwidth, 0)
			#print 'Found input num:%s width:%s' % (stubportnum, stubportwidth)
		for outstubx in bstubx.getElementsByTagName('stub-output')[0].getElementsByTagName('stub-connection'):
			stubportnum = '%s' % outstubx.attributes['num'].value
			stubportwidth = '%s' % outstubx.attributes['width'].value
			addstubport(bname, stubportnum, stubportwidth, 1)
			#print 'Found output num:%s width:%s' % (stubportnum, stubportwidth)
			
def parseLevel(lx):
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
	#   b) <varID-set> becomes <box> (same id used)
	#	c) <edge> becomes 2 separate <line>s
	#		* The <line> corresponding to the <edge> input
	#		* with id = e1 (going from n1 to n2) would be:
	#		*   <line id='e1__IN__'>
	#		*     <fromjoint id='n1' port='0'/>
	#		*     <tobox id='Application10' port='0'/> <!-- Links this line to the box (varID-set) id this pipe belongs to at port N -->
	#		*   </line>
	#		*   <line id='e1__OUT__'>
	#		*     <frombox id='Application10' port='0'/> <!-- This should match port N above! -->
	#		*     <tojoint id='n2' port='0'/>
	#		*   </line>
	lname = '%s' % lx.attributes['name'].value
	# Reset level-specific dictionaries
	edgesets = {} # these keeps track of the linked edges IN THIS LEVEL ONLY (used to create widgets)
	levelvaridsetedges = {}
	# these should be unique across all levels: varidsetedges = {}
	# these should be unique across all levels: varid2varidset = {}
	# these should be unique across all levels: edgeidtovarid = {}
	nodekinds = {}
	jointkinds = {}
	numedgesetedges = {}
	extraedgesetlines = {}
	# Gather var ids for all edges, fill varidsetedges and levelvaridsetedges arrays
	for ex in lx.getElementsByTagName('edge'):
		edgeid = '%s' % ex.attributes['id'].value
		varid = '%s' % ex.attributes['variableID'].value
		edgeidtovarid[edgeid] = varid
		try:
			if int(varid) < 0:
				varidvaridsetid = 'NEG_%s' % edgeid
			else:
				varidvaridsetid = varid2varidset.get(varid)
		except ValueError:
			varidvaridsetid = varid2varidset.get(varid)
		if varidvaridsetid is None:
			varidvaridsetid = '%s_varIDset' % varid
			varid2varidset[varid] = varidvaridsetid
		if varidsetedges.get(varidvaridsetid) is None:
			varidsetedges[varidvaridsetid] = []
		if levelvaridsetedges.get(varidvaridsetid) is None:
			levelvaridsetedges[varidvaridsetid] = []
		varidsetedges[varidvaridsetid].append(edgeid)
		levelvaridsetedges[varidvaridsetid].append(edgeid)
		edgesetport = len(levelvaridsetedges[varidvaridsetid]) - 1
		edgesets[edgeid] = []
		edgesets[edgeid].append(varidvaridsetid)
		edgesets[edgeid].append(edgesetport)
		#varidsetwidth[varidvaridsetid] = 'narrow'
		#varidseteditable[varidvaridsetid] = 'false'

	# Node ids for SUBBOARDS, INCOMING, and OUTGOING nodes that correspond to multiple joints (instead of exactly one)
	# 2a: Replace <node> with <joint>, making one <joint> per in/out for SUBBOARD, INCOMING, OUTGOING nodes
	# for subboards, also create lines between subboard joint and inner incoming/outgoing edges within the board
	# for off-level subboards, create an extra "dummy" box per input and output connecting to joint
	extrasubboardlines = ''
	extrasubboardbids = [] # keep track of set ids created for missing (external) subboard calls
	jointdict = {}
	suboutportsbyedgeid = {}
	totalexternalboardinputs = 0
	totalexternalboardoutputs = 0
	totalstubinputs = 0
	totalstuboutputs = 0
	levelsubboardcalls = {}
	for nx in lx.getElementsByTagName('node'):
		nid = '%s' % nx.attributes['id'].value
		kind = '%s' % nx.attributes['kind'].value
		nodekinds[nid] = kind
		if (kind.lower() == 'subboard') or (kind.lower() == 'incoming') or (kind.lower() == 'outgoing'):
			# Process inputs, create new joint for each
			for px in nx.getElementsByTagName('input')[0].getElementsByTagName('port'):
				# If SUBBOARD, also create additional LINE (to be output later) from this joint to inner edge box
				if kind.lower() == 'subboard':
					boardname = '%s' % nx.attributes['name'].value
					levelsubboardcalls[boardname] = True
					portnum = '%s' % px.attributes['num'].value
					edgeport = getboardedge(lname, boardname, 0, portnum)
					if edgeport is None:
						varidsetid = 'EXT__%s__XIN__%s' % (boardname, portnum)
						if levelvaridsetedges.get(varidsetid) is None:
							extrasubboardbids.append(varidsetid)
							totalexternalboardinputs += 1
							# Attempt to find stub width, if none default will be wide for subboard input
							varidsetwidth[varidsetid] = getstubwidth(boardname, 0, portnum)
							if varidsetwidth[varidsetid] is None:
								varidsetwidth[varidsetid] = 'wide'
							else:
								totalstubinputs += 1
							varidseteditable[varidsetid] = 'false'
						#print 'Edge not found for %s.%s input port #%s. Made box: %s' % (lname, boardname, portnum, varidsetid)
					elif edgesets.get(edgeport.edgeid) is None:
						varidsetid = 'EXT__%s__XIN__%s' % (boardname, portnum)
						if levelvaridsetedges.get(varidsetid) is None:
							extrasubboardbids.append(varidsetid)
							totalexternalboardinputs += 1
							# Attempt to find stub width, if none default will be wide for subboard input
							varidsetwidth[varidsetid] = getstubwidth(boardname, 0, portnum)
							if varidsetwidth[varidsetid] is None:
								varidsetwidth[varidsetid] = 'wide'
							else:
								totalstubinputs += 1
							varidseteditable[varidsetid] = 'false'
						#print 'Edge set not found for edge: %s. Made box: %s' % (edgeport.edgeid, varidsetid)
					else:
						varidsetid = edgesets.get(edgeport.edgeid)[0]
					fromnid = nid + '__IN__' + portnum
					lineid = '%s__OUT__CPY' % px.attributes['edge'].value
					setport = len(levelvaridsetedges.get(varidsetid, [])) + len(extraedgesetlines.get(varidsetid, []))
					if extraedgesetlines.get(varidsetid) is None:
						extraedgesetlines[varidsetid] = []
					extraedgesetlines[varidsetid].append(lineid)
					extrasubboardlines += makeline2box(lineid, fromnid, '0', varidsetid, setport)
					jointarr = port2joint(nid, kind, True, '%s' % px.attributes['num'].value, '%s' % px.attributes['edge'].value, lineid)
					jointdict[jointarr[0]] = jointarr[1]
					jointkinds[jointarr[0]] = kind
				else:
					jointarr = port2joint(nid, kind, True, '%s' % px.attributes['num'].value, '%s' % px.attributes['edge'].value)
					jointdict[jointarr[0]] = jointarr[1]
					jointkinds[jointarr[0]] = kind
			# Process outputs, create new joint for each
			for px in nx.getElementsByTagName('output')[0].getElementsByTagName('port'):
				# If SUBBOARD, also create additional LINE (to be output later) from inner edge box to this joint
				if kind.lower() == 'subboard':
					boardname = nx.attributes['name'].value
					portnum = '%s' % px.attributes['num'].value
					edgeport = getboardedge(lname, boardname, 1, portnum)
					edgesetarr = None
					if edgeport is not None:
						edgesetarr = edgesets.get(edgeport.edgeid)
					if edgesetarr is None:
						varidsetid = 'EXT__%s__XOUT__%s' % (boardname, portnum)
						if levelvaridsetedges.get(varidsetid) is None:
							extrasubboardbids.append(varidsetid)
							totalexternalboardoutputs += 1
							# Attempt to find stub width, if none default will be narrow for subboard output
							varidsetwidth[varidsetid] = getstubwidth(boardname, 1, portnum)
							if varidsetwidth[varidsetid] is None:
								varidsetwidth[varidsetid] = 'narrow'
							else:
								totalstuboutputs += 1
							varidseteditable[varidsetid] = 'false'
						#print 'Edge not found for %s.%s output port #%s. Made box: %s' % (lname, boardname, portnum, varidsetid)
						tonid = nid + '__OUT__' + portnum
						lineid = '%s__IN__CPY' % px.attributes['edge'].value
						setport = len(levelvaridsetedges.get(varidsetid, [])) + len(extraedgesetlines.get(varidsetid, []))
						if extraedgesetlines.get(varidsetid) is None:
							extraedgesetlines[varidsetid] = []
						extraedgesetlines[varidsetid].append(lineid)
						extrasubboardlines += makeline2joint(lineid, tonid, '0', varidsetid, setport)
						jointarr = port2joint(nid, kind, False, '%s' % px.attributes['num'].value, '%s' % px.attributes['edge'].value, lineid)
						jointdict[jointarr[0]] = jointarr[1]
						jointkinds[jointarr[0]] = kind
					else:
						# For outgoing SUBBOARD ports where we have a subboard node, connect outer edges to inner OUTGOING joint
						# These will be processed later when edges are converted to lines
						suboutportsbyedgeid[px.attributes['edge'].value] = edgeport
				else:
					jointarr = port2joint(nid, kind, False, '%s' % px.attributes['num'].value, '%s' % px.attributes['edge'].value)
					jointdict[jointarr[0]] = jointarr[1]
					jointkinds[jointarr[0]] = kind
		else:
			numinputs = len(nx.getElementsByTagName('input')[0].getElementsByTagName('port'))
			numoutputs = len(nx.getElementsByTagName('output')[0].getElementsByTagName('port'))
			jointdict[nid] = '<joint id="%s" inputs="%s" outputs="%s" kind="%s"/>' % (nid, numinputs, numoutputs, kind)
			jointkinds[nid] = kind
	logging.info('Level: %s' % lname)
	logging.info('Total external level inputs  (stubboards): %s (%s)' % (totalexternalboardinputs, totalstubinputs))
	logging.info('Total external level outputs (stubboards): %s (%s)' % (totalexternalboardoutputs, totalstuboutputs))
	# 2b: Replace <varID-set> with <box> and gather the associated edge ids for edgesets dictionary
	boxesout = ''
	totalboxcount = 0
	# for esx in lx.getElementsByTagName('varID-set'): # Can't use this because variable ids that are only linked to themselves are excluded
		# edgevaridsetid = esx.attributes['id'].value
	for edgevaridsetid in levelvaridsetedges:
		# The box will have X number of lines coming from the original edges of the edge set
		# PLUS any lines coming from other edge sets that connect thru SUBBOARD nodes
		extraports = len(extraedgesetlines.get(edgevaridsetid, []))
		edgesetports = len(levelvaridsetedges.get(edgevaridsetid, [])) + extraports
		boxesout += '    <box id="%s" lines="%s"/>\n' % (edgevaridsetid, edgesetports)
		totalboxcount += 1
	# Process extra boxes created from any external subboards
	extrasubboardboxes = ''
	for edgevaridsetid in extrasubboardbids:
		extraports = len(extraedgesetlines.get(edgevaridsetid, []))
		edgesetports = len(levelvaridsetedges.get(edgevaridsetid, [])) + extraports
		extrasubboardboxes += '    <box id="%s" lines="%s"/>\n' % (edgevaridsetid, edgesetports)
		totalboxcount += 1
	linesout = ''
	logging.info('Total boxes: %s' % totalboxcount)
	totallinecount = 0
	# 2c: Replace <edge> with __IN__ <line> and __OUT__ <line>
	numnodeinputs = {}  # numnodeinputs[nodeid]  = input  lines created for joint (used for port numbering)
	numnodeoutputs = {} # numnodeoutputs[nodeid] = output lines created for joint (used for port numbering)
	for ex in lx.getElementsByTagName('edge'):
		edgeid = '%s' % ex.attributes['id'].value
		if edgesets.get(edgeid) is None:
			logging.warning('Warning: could not find varID for edge id: %s' % edgeid)
			continue
		varidsetid = edgesets.get(edgeid)[0]
		setport = edgesets.get(edgeid)[1]
		# Update varID-set isWide and editable
		edgewidth = '%s' % ex.attributes['width'].value
		widthfound = varidsetwidth.get(varidsetid)
		if widthfound is None:
			if edgewidth.lower() == 'wide':
				varidsetwidth[varidsetid] = edgewidth.lower()
			else:
				varidsetwidth[varidsetid] = 'narrow'
		elif widthfound != edgewidth.lower():
			logging.warning('!!! Warning: conflicting edge widths found for varissetid: %s' % varidsetid)
		edgeeditable = '%s' % ex.attributes['editable'].value
		
		editablefound = varidseteditable.get(varidsetid)
		if editablefound is None:
			if (edgeeditable.lower() == 'true') or (edgeeditable.lower() == 't'):
				varidseteditable[varidsetid] = 'true'
			else:
				varidseteditable[varidsetid] = 'false'
		elif editablefound != edgeeditable:
			logging.warning('!!! Warning: conflicting edge editable found for varissetid: %s' % varidsetid)
		# Create line from top node (joint) to varID-set (box)
		fromlineid = edgeid + '__IN__'
		fromnodex = ex.getElementsByTagName('from')[0].getElementsByTagName('noderef')[0]
		fromnid = '%s' % fromnodex.attributes['id'].value
		fromport = numnodeoutputs.get(fromnid)
		if fromport is None:
			fromport = 0
		else:
			fromport += 1
		numnodeoutputs[fromnid] = fromport
		fromoriginalport = '%s' % fromnodex.attributes['port'].value
		fromkind = nodekinds.get(fromnid)
		if fromkind is None:
			logging.warning('Warning: could not find node kind for node id: %s' % fromnid)
			continue
		if (fromkind.lower() == 'subboard') or (fromkind.lower() == 'incoming') or (fromkind.lower() == 'outgoing'):
			# Find out if we need to connect this edge to the OUTGOING joint of the subboard
			subport = suboutportsbyedgeid.get(edgeid)
			if subport is not None:
				# Create an outgoing port at the OUTGOING joint
				outgoingjointarr = port2joint(subport.nodeid, fromkind, True, subport.portnum, subport.edgeid)
				if jointdict.get(outgoingjointarr[0]):
					outgoingjointxml = parseString(jointdict.get(outgoingjointarr[0]))
					outgoingjointxml = outgoingjointxml.getElementsByTagName('joint')[0]
					newportnum = int(outgoingjointxml.attributes['outputs'].value)
					outgoingjointxml.setAttribute('outputs', '%s' % (newportnum+1))
					jointdict[outgoingjointarr[0]] = '%s' % outgoingjointxml.toxml()
					jointkinds[outgoingjointarr[0]] = fromkind
					jointarr = port2joint(subport.nodeid, fromkind, True, subport.portnum, subport.edgeid)
					fromnid = jointarr[0]
					fromport = newportnum
				else:
					logging.warning('Warning: could not find OUTGOING joint:%s' % outgoingjointarr[0])
					continue
			else:
				fromnid = "%s__OUT__%s" % (fromnodex.attributes['id'].value, fromoriginalport)
				fromport = '0'
		linesout += makeline2box(fromlineid, fromnid, fromport, varidsetid, setport)
		totallinecount += 1
		# Create line from varID-set (box) to bottom node (joint)
		tolineid = edgeid + '__OUT__'
		tonodex = ex.getElementsByTagName('to')[0].getElementsByTagName('noderef')[0]
		tonid = tonodex.attributes['id'].value
		toport = numnodeinputs.get(tonid)
		if toport is None:
			toport = 0
		else:
			toport += 1
		numnodeinputs[tonid] = toport
		tooriginalport = tonodex.attributes['port'].value
		tokind = nodekinds.get(tonid)
		if tokind is None:
			logging.warning('Warning: could not find node kind for node id: %s' % tonid)
			continue
		if (tokind.lower() == 'subboard') or (tokind.lower() == 'incoming') or (tokind.lower() == 'outgoing'):
			tonid = "%s__IN__%s" % (tonodex.attributes['id'].value, tooriginalport)
			toport = '0'
		linesout += makeline2joint(tolineid, tonid, toport, varidsetid, setport)
	logging.info('Total lines: %s' % totallinecount)
	# For individual level XML, output relevant variable ids and stub boards at the top:
	newlevelxml =  '<?xml version="1.0" encoding="UTF-8"?>\n'
	newlevelxml += '<!DOCTYPE world SYSTEM "http://types.cs.washington.edu/verigames/world.dtd">\n'
	newlevelxml += '<world version="3">\n'
	newlevelxml += ' <linked-varIDs>\n'
	for levelvaridset in levelvaridsetedges:
		varsetxml = varidsetsxml.get(levelvaridset)
		if varsetxml is None: # not in original world xml
			continue
		newlevelxml += '  %s\n' % varsetxml
	newlevelxml += ' </linked-varIDs>\n'
	boardsx = lx.getElementsByTagName('boards')[0]
	for boardcall in levelsubboardcalls:
		levelfound = stubboardlevels.get(boardcall)
		if levelfound is None: # if not a stub
			continue
		if levelfound == lname: # if already a stub in this level, move on
			continue
		stubxstr = stubboardxml.get(boardcall)
		#print 'Adding stubboard %s to level: %s' % (boardcall, lname)
		if stubxstr is None:
			continue
		stubx = parseString(stubxstr)
		boardsx.appendChild(stubx.documentElement)
	newlevelxml += lx.toxml() + "\n"
	newlevelxml += '</world>'
	writelevel = open('%s.xml' % lname, 'w')
	writelevel.write(newlevelxml)
	writelevel.close()
	
	# Create one string from jointdict
	jointsout = ''
	for jointid in jointdict:
		jointsout += '    %s\n' % jointdict[jointid]
	# Output all the level layout xml in prefered order
	layoutout =  '<?xml version="1.0" ?>\n'
	layoutout += '<graph id="world" version="3">\n'
	layoutout += '  <level id="%s">\n' % lname
	layoutout += boxesout
	layoutout += extrasubboardboxes
	layoutout += jointsout
	layoutout += linesout
	layoutout += extrasubboardlines
	layoutout += '  </level>\n'
	layoutout += '</graph>'
	writegrid = open(lname + 'Layout.xml', 'w')
	writegrid.write(layoutout)
	writegrid.close()

### Command line interface ###
if __name__ == "__main__":
	if (len(sys.argv) < 2) or (len(sys.argv) > 3):
		print ('\n\nUsage: %s input_file [output_file]\n\n  input_file: name of classic XML '
			'file to be parsed, omitting ".xml" extension\n  output_files_prefix: (optional) name '
			'of prefix for XML files to be output, omitting ".xml" extension if none given write to input_file'
			'+ "Layout.xml" and input_file + "Constraints.xml"\n\nEx: To parse Test.xml run: '
			'%s Test TestOut \n  -- this will create TestOutLayout.xml and TestOutConstraints.xml\n') % (sys.argv[0], sys.argv[0])
		quit()
	if len(sys.argv) == 3:
		outfile = sys.argv[2]
	else:
		outfile = sys.argv[1]
	infile = sys.argv[1]
	classic2grid(infile, outfile)