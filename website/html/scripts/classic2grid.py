import sys
from xml.dom.minidom import parse, parseString
from layoutgrid import layoutboxes, layoutlines

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

# boardstubwidths[levelname][boardname][0][portnum] = incoming port width ('narrow' or 'wide')
# boardstubwidths[levelname][boardname][1][portnum] = outgoing port width ('narrow' or 'wide')
boardstubwidths = {}

# edgesets[edgeid][0] = edge set id
# edgesets[edgeid][1] = edge set port
edgesets = {}

# varidsetedges[varID-set] = array of edgeids
varidsetedges = {}

# levelvaridsetedges[lname][varID-set] = array of edgeids for the given level name
levelvaridsetedges = {}

# varid2varidset[varID] = varid-set id
varid2varidset = {}

# edgeidtovarid[edgeid] = varid
edgeidtovarid = {}

# extraedgesetlines[edgevaridsetid] = Array of extra lines generated from SUBBOARD nodes connecting to INCOMING/OUTGOING edges
extraedgesetlines = {}

# edgesetwidth[edgevaridsetid] = isWide (Boolean)
edgesetwidth = {}

# edgeseteditable[edgevaridsetid] = editable (Boolean)
edgeseteditable = {}

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
def addstubport(lname, bname, stubportnum, stubportwidth, inout):
	boards = boardstubwidths.get(lname)
	if boards is None:
		boards = {}
	board = boards.get(bname)
	if board is None:
		board = {}
	widths = board.get(inout)
	if widths is None:
		widths = {}
	widths[stubportnum] = stubportwidth
	board[inout] = widths
	boards[bname] = board
	boardstubwidths[lname] = boards

# Safely get a stub port width from the boardstubwidths dictionary
def getstubwidth(lname, bname, inout, portnum):
	boards = boardstubwidths.get(lname)
	if boards is None:
		return None
	board = boards.get(bname)
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
	allxml = parse(infile + '.xml')
	worlds = allxml.getElementsByTagName('world')
	if len(worlds) != 1:
		print 'Warning: expecting 1 World, found %d, processing only the first World' % len(worlds)
	wx = worlds[0]
	
	# Step 1a: Gather all varID-sets, varIDs, and edgeids associated with them
	# Initialize varidsetedges, varid2varidset
	for varsetx in wx.getElementsByTagName('varID-set'): #formerly traversing edge-sets, now varID-set
		varidvaridsetid = varsetx.attributes['id'].value
		# varidsetedges[varID-set] = array of edgeids
		varidsetedges[varidvaridsetid] = []
		for varidx in varsetx.getElementsByTagName('varID'):
			varid = varidx.attributes['id'].value
			# varid2varidset[varID] = varid-set id
			varid2varidset[varid] = varidvaridsetid
	# Step 1b: Gather all board incoming/outgoing edges to fill boardedges dictionary
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
		for bstubx in lx.getElementsByTagName('board-stub'):
			bname = bstubx.attributes['name'].value
			#print 'Found Stub board: %s' % bname
			for instubx in bstubx.getElementsByTagName('stub-input')[0].getElementsByTagName('stub-connection'):
				stubportnum = instubx.attributes['num'].value
				stubportwidth = instubx.attributes['width'].value
				addstubport(lname, bname, stubportnum, stubportwidth, 0)
				#print 'Found input num:%s width:%s' % (stubportnum, stubportwidth)
			for outstubx in bstubx.getElementsByTagName('stub-output')[0].getElementsByTagName('stub-connection'):
				stubportnum = outstubx.attributes['num'].value
				stubportwidth = outstubx.attributes['width'].value
				addstubport(lname, bname, stubportnum, stubportwidth, 1)
				#print 'Found output num:%s width:%s' % (stubportnum, stubportwidth)
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
	
	# Output string:
	out = '<?xml version="1.0" ?>\n'
	out += '<graph id="world">\n'
	constraintout = out
	for lx in wx.getElementsByTagName('level'):
		lname = lx.attributes['name'].value
		# Reset level-specific dictionaries
		edgesets = {} # these keeps track of the linked edges IN THIS LEVEL ONLY (used to create widgets)
		levelvaridsetedges[lname] = []
		# these should be unique across all levels: varidsetedges = {}
		# these should be unique across all levels: varid2varidset = {}
		# these should be unique across all levels: edgeidtovarid = {}
		nodekinds = {}
		jointkinds = {}
		numedgesetedges = {}
		extraedgesetlines = {}
		edgesetwidth = {}
		edgeseteditable = {}
		# Gather var ids for all edges, fill varidsetedges and levelvaridsetedges arrays
		for ex in lx.getElementsByTagName('edge'):
			edgeid = ex.attributes['id'].value
			varid = ex.attributes['variableID'].value
			edgeidtovarid[edgeid] = varid
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
			edgesets[edgeid].append(varidvaridsetid)
			edgesetwidth[varidvaridsetid] = 'narrow'
			edgeseteditable[varidvaridsetid] = False
	
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
							varidsetid = 'EXT__%s__XIN__%s' % (boardname, portnum)
							if levelvaridsetedges.get(varidsetid) is None:
								extrasubboardbids.append(varidsetid)
								totalexternalboardinputs += 1
								# Attempt to find stub width, if none default will be wide for subboard input
								edgesetwidth[varidsetid] = getstubwidth(lname, boardname, 0, portnum)
								if edgesetwidth[varidsetid] is None:
									edgesetwidth[varidsetid] = 'wide'
								else:
									totalstubinputs += 1
								edgeseteditable[varidsetid] = False
							#print 'Edge not found for %s.%s input port #%s. Made box: %s' % (lname, boardname, portnum, varidsetid)
						elif edgesets.get(edgeport.edgeid) is None:
							varidsetid = 'EXT__%s__XIN__%s' % (boardname, portnum)
							if levelvaridsetedges.get(varidsetid) is None:
								extrasubboardbids.append(varidsetid)
								totalexternalboardinputs += 1
								# Attempt to find stub width, if none default will be wide for subboard input
								edgesetwidth[varidsetid] = getstubwidth(lname, boardname, 0, portnum)
								if edgesetwidth[varidsetid] is None:
									edgesetwidth[varidsetid] = 'wide'
								else:
									totalstubinputs += 1
								edgeseteditable[varidsetid] = False
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
						jointarr = port2joint(nid, kind, True, px.attributes['num'].value, px.attributes['edge'].value, lineid)
						jointdict[jointarr[0]] = jointarr[1]
						jointkinds[jointarr[0]] = kind
					else:
						jointarr = port2joint(nid, kind, True, px.attributes['num'].value, px.attributes['edge'].value)
						jointdict[jointarr[0]] = jointarr[1]
						jointkinds[jointarr[0]] = kind
				# Process outputs, create new joint for each
				for px in nx.getElementsByTagName('output')[0].getElementsByTagName('port'):
					# If SUBBOARD, also create additional LINE (to be output later) from inner edge box to this joint
					if kind.lower() == 'subboard':
						boardname = nx.attributes['name'].value
						portnum = px.attributes['num'].value
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
								edgesetwidth[varidsetid] = getstubwidth(lname, boardname, 1, portnum)
								if edgesetwidth[varidsetid] is None:
									edgesetwidth[varidsetid] = 'narrow'
								else:
									totalstuboutputs += 1
								edgeseteditable[varidsetid] = False
							#print 'Edge not found for %s.%s output port #%s. Made box: %s' % (lname, boardname, portnum, varidsetid)
							tonid = nid + '__OUT__' + portnum
							lineid = '%s__IN__CPY' % px.attributes['edge'].value
							setport = len(levelvaridsetedges.get(varidsetid, [])) + len(extraedgesetlines.get(varidsetid, []))
							if extraedgesetlines.get(varidsetid) is None:
								extraedgesetlines[varidsetid] = []
							extraedgesetlines[varidsetid].append(lineid)
							extrasubboardlines += makeline2joint(lineid, tonid, '0', varidsetid, setport)
							jointarr = port2joint(nid, kind, False, px.attributes['num'].value, px.attributes['edge'].value, lineid)
							jointdict[jointarr[0]] = jointarr[1]
							jointkinds[jointarr[0]] = kind
						else:
							# For outgoing SUBBOARD ports where we have a subboard node, connect outer edges to inner OUTGOING joint
							# These will be processed later when edges are converted to lines
							suboutportsbyedgeid[px.attributes['edge'].value] = edgeport
					else:
						jointarr = port2joint(nid, kind, False, px.attributes['num'].value, px.attributes['edge'].value)
						jointdict[jointarr[0]] = jointarr[1]
						jointkinds[jointarr[0]] = kind
			else:
				numinputs = len(nx.getElementsByTagName('input')[0].getElementsByTagName('port'))
				numoutputs = len(nx.getElementsByTagName('output')[0].getElementsByTagName('port'))
				jointdict[nid] = '<joint id="%s" inputs="%s" outputs="%s" kind="%s"/>' % (nid, numinputs, numoutputs, kind)
				jointkinds[nid] = kind
		print 'Level: %s' % lname
		print 'Total external level inputs  (stubboards): %s (%s)' % (totalexternalboardinputs, totalstubinputs)
		print 'Total external level outputs (stubboards): %s (%s)' % (totalexternalboardoutputs, totalstuboutputs)
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
		print 'Total boxes: %s' % totalboxcount
		totallinecount = 0
		# 2c: Replace <edge> with __IN__ <line> and __OUT__ <line>
		numnodeinputs = {}  # numnodeinputs[nodeid]  = input  lines created for joint (used for port numbering)
		numnodeoutputs = {} # numnodeoutputs[nodeid] = output lines created for joint (used for port numbering)
		for ex in lx.getElementsByTagName('edge'):
			edgeid = ex.attributes['id'].value
			if edgesets.get(edgeid) is None:
				print 'Warning: could not find varID for edge id: %s' % edgeid
				continue
			varidsetid = edgesets.get(edgeid)[0]
			setport = edgesets.get(edgeid)[1]
			# Update varID-set isWide and editable
			edgewidth = ex.attributes['width'].value
			if edgewidth.lower() == 'wide':
				edgesetwidth[varidsetid] = edgewidth.lower()
			edgeeditable = ex.attributes['editable'].value
			if (edgeeditable.lower() == 'true') or (edgeeditable.lower() == 't'):
				edgeseteditable[varidsetid] = True
			# Create line from top node (joint) to varID-set (box)
			fromlineid = edgeid + '__IN__'
			fromnodex = ex.getElementsByTagName('from')[0].getElementsByTagName('noderef')[0]
			fromnid = fromnodex.attributes['id'].value
			fromport = numnodeoutputs.get(fromnid)
			if fromport is None:
				fromport = 0
			else:
				fromport += 1
			numnodeoutputs[fromnid] = fromport
			fromoriginalport = fromnodex.attributes['port'].value
			fromkind = nodekinds.get(fromnid)
			if fromkind is None:
				print 'Warning: could not find node kind for node id: %s' % fromnid
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
						print 'Warning: could not find OUTGOING joint:%s' % outgoingjointarr[0]
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
				print 'Warning: could not find node kind for node id: %s' % tonid
				continue
			if (tokind.lower() == 'subboard') or (tokind.lower() == 'incoming') or (tokind.lower() == 'outgoing'):
				tonid = "%s__IN__%s" % (tonodex.attributes['id'].value, tooriginalport)
				toport = '0'
			linesout += makeline2joint(tolineid, tonid, toport, varidsetid, setport)
		print 'Total lines: %s' % totallinecount
		# Create one string from jointdict
		jointsout = ''
		for jointid in jointdict:
			jointsout += '    %s\n' % jointdict[jointid]
		# Output all the level xml in prefered order
		out += '  <level id="%s">\n' % lname
		out += boxesout
		out += extrasubboardboxes
		out += jointsout
		out += linesout
		out += extrasubboardlines
		out += '  </level>\n'
		# Output constaints file
		constraintout += '  <level id="%s">\n' % lname
		for varidsetid in edgesetwidth:
			editablestr = '%s' % edgeseteditable.get(varidsetid, 'narrow')
			constraintout += '    <box id="%s" width="%s" editable="%s"/>\n' % (varidsetid, edgesetwidth[varidsetid], editablestr.lower())
		constraintout += '  </level>\n'
	out += '</graph>'
	constraintout += '</graph>'
	writegrid = open(outfile + 'Layout.xml','w')
	writegrid.write(out)
	writegrid.close()
	writeconstr = open(outfile + 'Constraints.xml','w')
	writeconstr.write(constraintout)
	writeconstr.close()
	layoutboxes(outfile + 'Layout', outfile + 'Layout', False)
	#layoutlines(outfile + 'Layout', outfile + 'Layout', False) ## still too slow at the moment

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