import os, sys, re
from xml.dom.minidom import parse

# Globally round graphviz coordinates
decimalplacestoroundto = 2

verbose = True

# Width space given to each incoming/outgoing edge plus 1 unit on each end of a box of padding [][i0][i1]...[in][]
WIDTHPERPORT = 0.6

### Classes ###
class Point:
	def __init__(self, x, y):
		self.x = round(float(x), decimalplacestoroundto)
		self.y = round(float(y), decimalplacestoroundto)

# DotLayout contains this info: portnum, edgeid, nodeid
class DotLayout:
	def __init__(self, id, pos=None, width=None, height=None, points=None):
		self.id = id
		self.pos = pos
		if width is not None:
			self.width = round(float(width), decimalplacestoroundto)
		if height is not None:
			self.height = round(float(height), decimalplacestoroundto)
		self.points = points


### Dictionaries ###
# edge2linexml[levelid][dotedgestring] = line xml element
edge2linexml = {}

# node2xml[levelid][dotnodestring] = box/joint xml element
node2xml = {}

# numnodeinputports[dotnodeid] = number of input ports, used for port labeling since port ids are strings
numnodeinputports = {}
numnodeoutputports = {}

# portxcoords[boxid___P___portid] = x coordinate that incoming/outgoing ports
# should use - use this lookup to force them to have the exact same x value
# i.e. if incoming port "1" has x=23.54 make outgoing port "1" have x=23.54
portxcoords = {}

# boxdotheight[boxid] = Height input to dot to allow for extra vertical space
# Why not use 1.0? We have adjusted the box heights to allow for
# extra vertical space for boxes with lots of lines through them to provide space
# for incoming/outgoing edges, but we don't want the boxes themselves to have a
# large height, but the constant height of 1.0 so we have to adjust the y values
# accordingly
boxdotheight = {}

### Helper functions ###
# convert to string
def tostr(thing):
	return '%s' % thing

# substitute characters that dot doesn't like, output is a string dot will like
def sanitize(thing):
	return thing.replace('-','_DSH_').replace(' ','_SPC_').replace('.','_DOT_')
	
# replace characters that dot doesn't like, output is original unsanitized string
def desanitize(thing):
	return thing.replace('_DSH_','-').replace('_SPC_',' ').replace('_DOT_','.')

# get height of box used for dot to allow more vertical space based on number of boxlines passing thru
def getboxheight(lines):
	return lines * 0.75 + 0.75

# convert points (default for pos information) to inches (default for width, height information)
def pts2inches(pts):
	return float(pts) / 72.0

# convert inches (default for width, height information) to points (default for pos information) 
def inches2pts(inches):
	return float(inches) * 72.0

# append a <point x="" y=""> to given linexml
def xappendpt(allxml, linexml, pt):
	ptx = allxml.createElement('point')
	ptx.setAttribute('x', tostr(pt.x))
	ptx.setAttribute('y', tostr(pt.y))
	linexml.appendChild(ptx)

# Creates the input and output labels to be referenced like ports in the "record" style dot nodes
def createportlabels(inports, outports, id=None, verbose=False):
	label = '{{|'
	for port in range(inports):
		if verbose:
			label += '<i%s>i%s|' % (port, port)
		else:
			label += '<i%s>|' % port
	if id is not None:
		if verbose:
			label += '}|%s|{|' % id
		else:
			label += '}|{}|{|'
	else:
		label += '}|{|'
	for port in range(outports):
		if verbose:
			label += '<o%s>o%s|' % (port, port)
		else:
			label += '<o%s>|' % port
	label += '}}'
	return label

# read the awful dot format of attributes i.e. 'node_n1 [attrib1=this, attrib2="1,2,3", attrib3=somethingelse]'
# and return a dictionary of keys -> values
def parseattrib(attr):
	attr = attr.lstrip('[').rstrip(']')
	eqs = attr.split('=')
	attribs = {}
	if len(eqs) == 0:
		print "Couldn't process dot output: %s" % line
		return attribs
	akey = eqs[0]
	for i in range(1, len(eqs)):
		lastcomma = eqs[i].rfind(',')
		if i == len(eqs) - 1:
			# Hard code only the salient attributes that we want
			if (akey.lower() == 'pos') or (akey.lower() == 'width') or (akey.lower() == 'height') or (akey.lower() == 'bb'):
				attribs[akey] = eqs[i].strip().strip('"').lstrip('e,')
		elif lastcomma == -1:
			break
		else:
			# Hard code only the salient attributes that we want
			if (akey.lower() == 'pos') or (akey.lower() == 'width') or (akey.lower() == 'height') or (akey.lower() == 'bb'):
				attribs[akey] = eqs[i][:lastcomma].strip().strip('"').lstrip('e,')
			akey = eqs[i][(lastcomma+1):].strip()
			if len(akey) == 0:
				break
	return attribs

# get the bounding box for the graph as 2 element array of points
def parsebb(line):
	line = line.strip()
	lcurl = line.find('{')
	if lcurl > -1:
		line = line[(lcurl+1):].strip()
	if line.find('graph') == 0:
		lb = line.find('[')
	else:
		return None
	attr = line[lb:]
	attribs = parseattrib(attr)
	if attribs.get('bb'):
		pts = attribs.get('bb').split(',')
		if len(pts) == 4:
			x1 = pts2inches(float(pts[0]))
			y1 = pts2inches(float(pts[1]))
			x2 = pts2inches(float(pts[2]))
			y2 = pts2inches(float(pts[3]))
			return [Point(x1, y1), Point(x2, y2)]
	return None

# Parse the dot width/height/position/points information and return a DotLayout object
# line: individual line repesenting dot node or edge with position/width/height info
# returnonlyendpts: True to only parse the enpoints for edges, first and last connecting points
def parsedot(line, returnonlyendpts = True):
	line = line.strip().replace('e ','e').replace('+ ','+')
	if (line.find('digraph') == 0) or (line.find('graph') == 0) or (line.find('node') == 0) or (line.find('edge') == 0) or (line.find('}') == 0) or (line.find('{') == 0):
		return None
	lb = line.find('[')
	if lb == -1:
		print "Couldn't process dot output: %s" % line
		return None
	id = line[:lb].strip().replace('"','').replace(' ','').replace('->',' -> ')
	attr = line[lb:]
	attribs = parseattrib(attr)
	if attribs.get('pos'):
		pos = attribs.get('pos')
		if pos.count(',') > 1:
			# These are edge points, parse them individually
			pts = []
			allpointpairs = pos.split(' ')
			# grab first and last if only endpoints are desired
			if returnonlyendpts:
				firstpair = allpointpairs[0]
				lastpair = allpointpairs[-1]
				allpointpairs = [firstpair, lastpair]
			#print '> dot pts l %s' % id
			for pair in allpointpairs:
				if len(pair.split(',')) == 2:
					posx = float(pair.split(',')[0].strip())
					posy = float(pair.split(',')[1].strip())
					posx = pts2inches(posx)
					posy = pts2inches(posy)
					#print '  pt %s,%s' % (posx, posy)
					pts.append(Point(posx, posy))
				else:
					print 'Warning: couldnt process pts "%s" len()=%s pos "%s" for id: "%s"' % (pair, len(pair.split(',')), pos, id)
					continue
			return DotLayout(id, None, None, None, pts)
		elif pos.count(',') == 1:
			if len(pos.split(',')) == 2:
				posx = float(pos.split(',')[0].strip())
				posy = float(pos.split(',')[1].strip())
				posx = pts2inches(posx)
				posy = pts2inches(posy)
				pos = Point(posx, posy)
			else:
				print 'Warning: bad pos field found "%s" for id: %s' % (pos, id)
				return None
			if attribs.get('width'):
				width = float(attribs.get('width'))
			else:
				width = None
			if attribs.get('height'):
				height = float(attribs.get('height'))
			else:
				height = None
			return DotLayout(id, pos, width, height)
	print "Couldn't process dot output: %s" % line
	return None


### Layout the box positions by positioning ports as "labels" ###
def layoutboxes(infile, outfile, outputdotfiles):
	allxml = parse(infile + '.xml')
	graphs = allxml.getElementsByTagName('graph')
	if len(graphs) != 1:
		print 'Warning: expecting 1 graph, found %d, processing only the first graph' % len(graphs)
	gx = graphs[0]
	for lx in gx.getElementsByTagName('level'):
		lname = lx.attributes['id'].value
		edge2linexml[lname] = {}
		node2xml[lname] = {}
		portxcoords = {}
		boxdotheight = {}
		numnodeinputports = {}
		numnodeoutputports = {}
		#print 'Laying out Level: %s' % lname
		dotin =  'digraph %s {\n' % lname
		dotin += '  size ="50,50";' # 50 inches by 50 inches to help display large graphs in pdf
		dotin += '  graph [\n'
		dotin += '    rankdir=TB,\n'
		dotin += '    nodesep=1.0,\n'
		dotin += '    ranksep=1.0,\n'
		dotin += '    splines=polyline\n'
		dotin += '  ];\n'
		dotin += '  node [\n'
		dotin += '    fontsize=6.0,\n'
	#	dotin += '    width=0.5,\n'
	#	dotin += '    height=1.0,\n'
		dotin += '    fixedsize=true,\n'
		dotin += '    shape=record\n'
		dotin += '  ];\n'
		dotin += '  edge [\n'
		dotin += '    arrowhead=none,\n'
		dotin += '    arrowtail=none\n'
		dotin += '  ];\n'
		for jx in lx.getElementsByTagName('joint'):
			jid = jx.attributes['id'].value
			jin = int(jx.attributes['inputs'].value)
			jout = int(jx.attributes['outputs'].value)
			jwidth = max(jin, jout)
			jlabel = createportlabels(jin, jout, None, verbose)
			nodeid = 'J_%s' % sanitize(jid)
			dotin += '  %s [width=%s,height=0.5,label="%s"];\n' % (nodeid, jwidth * WIDTHPERPORT, jlabel)
			node2xml[lname][nodeid] = jx
		for bx in lx.getElementsByTagName('box'):
			bid = bx.attributes['id'].value
			blines = int(bx.attributes['lines'].value)
			blabel = createportlabels(blines, blines, bid, verbose)
			nodeid = 'B_%s' % sanitize(bid)
			boxheight = getboxheight(blines)
			dotin += '  %s [width=%s,height=%s,label="%s"];\n' % (nodeid, (blines + 2) * WIDTHPERPORT, boxheight, blabel)
			boxdotheight[bid] = boxheight
			node2xml[lname][nodeid] = bx
		for linex in lx.getElementsByTagName('line'):
			lid = linex.attributes['id'].value
			if (len(linex.getElementsByTagName('fromjoint')) == 1) and (len(linex.getElementsByTagName('tobox')) == 1):
				fromid = 'J_%s' % sanitize(linex.getElementsByTagName('fromjoint')[0].attributes['id'].value)
				fromport = linex.getElementsByTagName('fromjoint')[0].attributes['port'].value
				fromportnum = numnodeoutputports.get(fromid)
				if fromportnum is None:
					fromportnum = 0
					numnodeoutputports[fromid] = 0
				numnodeoutputports[fromid] += 1
				toid = 'B_%s' % sanitize(linex.getElementsByTagName('tobox')[0].attributes['id'].value)
				toport = linex.getElementsByTagName('tobox')[0].attributes['port'].value
				toportnum = numnodeinputports.get(toid)
				if toportnum is None:
					toportnum = 0
					numnodeinputports[toid] = 0
				numnodeinputports[toid] += 1
			elif (len(linex.getElementsByTagName('frombox')) == 1) and (len(linex.getElementsByTagName('tojoint')) == 1):
				fromid = 'B_%s' % sanitize(linex.getElementsByTagName('frombox')[0].attributes['id'].value)
				fromport = linex.getElementsByTagName('frombox')[0].attributes['port'].value
				fromportnum = numnodeoutputports.get(fromid)
				if fromportnum is None:
					fromportnum = 0
					numnodeoutputports[fromid] = 0
				numnodeoutputports[fromid] += 1
				toid = 'J_%s' % sanitize(linex.getElementsByTagName('tojoint')[0].attributes['id'].value)
				toport = linex.getElementsByTagName('tojoint')[0].attributes['port'].value
				toportnum = numnodeinputports.get(toid)
				if toportnum is None:
					toportnum = 0
					numnodeinputports[toid] = 0
				numnodeinputports[toid] += 1
			else:
				print 'Warning: unsupported input/outputs for line id: %s' % lid
				continue
			edgeid = '%s:o%s -> %s:i%s' % (fromid, fromportnum, toid, toportnum)
			edge2linexml[lname][edgeid] = linex
			dotin += '  %s ;\n' % (edgeid)
		dotin += '}'
		dotinfilename = '%s-%s-BOXES-in.dot' % (outfile, lname)
		writedot = open(dotinfilename,'w')
		writedot.write(dotin)
		writedot.close()
		dotcmd = os.popen('dot -y ' + dotinfilename)
		dotoutput = dotcmd.read()
		dotcmd.close()
		if outputdotfiles:
			dotcmd = os.popen('dot -y -Teps -o%s-%s-BOXES.eps %s' % (outfile, lname, dotinfilename))
			dotcmd.read()
			dotcmd.close()
			dotcmd = os.popen('dot -y -Tpdf -o%s-%s-BOXES.pdf %s' % (outfile, lname, dotinfilename))
			dotcmd.read()
			dotcmd.close()
			dotoutfilename = '%s-%s-BOXES-out.dot' % (outfile, lname)
			writedot = open(dotoutfilename,'w')
			writedot.write(dotoutput)
			writedot.close()
		else:
			os.remove(dotinfilename)
		dotoutput = ' '.join(dotoutput.split()) #get rid of any runs of spaces, newlines, etc
		# Get rid of dot's "continue on next line" character '\' while preserving pos="N,N N,N" formatting
		dotoutput = dotoutput.replace(', \\', ',').replace('\\ ,', ',').replace(' \\ ', ' ').replace('\\', '')
		# Put pairs together that may have been separated
		dotoutput = dotoutput.replace(' , ', ',').replace(', ', ',').replace(' ,', ',')
		dotelms = dotoutput.split(";") #split each element on its own line
		
		for line in dotelms:
			layout = parsedot(line)
			if layout is not None:
				if layout.id is None:
					print 'Warning: invalid layout created for line %s' % line
				if layout.points is not None:
					# Output edge points
					edgex = edge2linexml[lname].get(layout.id)
					if edgex is None:
						print 'Warning: no line xml found for id %s' % layout.id
						continue
					if len(layout.points) != 2:
						print 'Warning: expecting exactly two points for line id %s' % layout.id
						continue
					foundstartx = None
					foundendx = None
					if edgex.getElementsByTagName('frombox'):
						portid = '%s___P___%s' % (edgex.getElementsByTagName('frombox')[0].attributes['id'].value, edgex.getElementsByTagName('frombox')[0].attributes['port'].value)
						foundstartx = portxcoords.get(portid)
						if foundstartx is not None:
							layout.points[0].x = foundstartx
						else:
							portxcoords[portid] = layout.points[0].x
						foundboxheight = boxdotheight.get(edgex.getElementsByTagName('frombox')[0].attributes['id'].value)
						if foundboxheight is not None:
							# Adjust outgoing line height by boxheight to force box to have a height of 1.0
							layout.points[0].y -= foundboxheight / 2.0 - 0.5
						else:
							print 'no box height for: %s' % layout.id
						# Add points staggered from the outputs so that all box outputs are at different y values
						try:
							newpty = getboxheight(float(edgex.getElementsByTagName('frombox')[0].attributes['port'].value)) / 2.0
						except exception:
							newpty = getboxheight(0) / 2.0
						startx = layout.points[0].x
						starty = layout.points[0].y
						endx = layout.points[-1].x
						endy = layout.points[-1].y
						layout.points.insert(1, Point(startx, starty + newpty))
						layout.points.insert(2, Point(endx, endy - getboxheight(0) / 2.0))
					elif edgex.getElementsByTagName('tobox'):
						portid = '%s___P___%s' % (edgex.getElementsByTagName('tobox')[0].attributes['id'].value, edgex.getElementsByTagName('tobox')[0].attributes['port'].value)
						foundendx = portxcoords.get(portid)
						if foundendx is not None:
							layout.points[-1].x = foundendx
						else:
							portxcoords[portid] = layout.points[-1].x
						foundboxheight = boxdotheight.get(edgex.getElementsByTagName('tobox')[0].attributes['id'].value)
						if foundboxheight is not None:
							# Adjust incoming line height by boxheight to force box to have a height of 1.0
							layout.points[-1].y += foundboxheight / 2.0 - 0.5
						else:
							print 'no box height for: %s' % layout.id
						# Add points staggered from the outputs so that all box outputs are at different y values
						try:
							newpty = getboxheight(float(edgex.getElementsByTagName('tobox')[0].attributes['port'].value)) / 2.0
						except exception:
							newpty = getboxheight(0) / 2.0
						startx = layout.points[0].x
						starty = layout.points[0].y
						endx = layout.points[-1].x
						endy = layout.points[-1].y
						layout.points.insert(1, Point(startx, starty + getboxheight(0) / 2.0))
						layout.points.insert(2, Point(endx, endy - newpty))
					else:
						print 'Warning: edge found that has no tobox or frombox id %s' % layout.id
					# Remove any current layout points, we only want the new layout points to be saved
					for oldptx in edgex.getElementsByTagName('point'):
						edgex.removeChild(oldptx)
					prevpt = None
					for pt in layout.points:
						# If changing x and y, put two points in between @ avg of x
						if prevpt is not None:
							if not (prevpt.x == pt.x) and not (prevpt.y == pt.y):
								pt1 = Point(0.5*(prevpt.x + pt.x), prevpt.y)
								pt2 = Point(0.5*(prevpt.x + pt.x), pt.y)
								xappendpt(allxml, edgex, pt1)
								xappendpt(allxml, edgex, pt2)
						xappendpt(allxml, edgex, pt)
						prevpt = pt
				elif layout.pos is not None:# Output node position
					nodex = node2xml[lname].get(layout.id)
					if nodex is None:
						print 'Warning: no node found for id %s' % layout.id
						continue
					bid = nodex.attributes['id'].value;
					if 'x' in nodex.attributes.keys():
						nodex.removeAttribute('x')
					nodex.setAttribute('x', tostr(layout.pos.x))
					foundboxheight = boxdotheight.get(bid)
					if foundboxheight is not None:
						# Adjust y to account for difference in forcing height to = 1.0
						#layout.pos.y -= foundboxheight / 2.0 - 0.5
						# Now force height to = 1.0
						foundboxheight = 1.0
					else:
						# Must be a joint, leave y and height alone
						foundboxheight = layout.height
					if 'y' in nodex.attributes.keys():
						nodex.removeAttribute('y')
					nodex.setAttribute('y', tostr(layout.pos.y))
					if 'width' in nodex.attributes.keys():
						nodex.removeAttribute('width')
					if 'height' in nodex.attributes.keys():
						nodex.removeAttribute('height')
					if layout.width is not None:
						nodex.setAttribute('width', tostr(layout.width))
					if foundboxheight is not None:
						nodex.setAttribute('height', tostr(foundboxheight))
				else:
					print 'Warning: bad layout created for line: %s' % line
	writelayout = open(outfile + '.xml','w')
	writelayout.write(gx.toxml())
	writelayout.close()

### Layout lines by turning line endpoints from previous layout ### 
### into nodes with fixed positions and using splines = ortho   ###
def layoutlines(infile, outfile, outputdotfiles):
	allxml = parse(infile + '.xml')
	graphs = allxml.getElementsByTagName('graph')
	if len(graphs) != 1:
		print 'Warning: expecting 1 graph, found %d, processing only the first graph' % len(graphs)
	gx = graphs[0]
	for lx in gx.getElementsByTagName('level'):
		lname = lx.attributes['id'].value
		edge2linexml[lname] = {}
		node2xml[lname] = {}
		portxcoords = {}
		boxdotheight = {}
		numnodeinputports = {}
		numnodeoutputports = {}
		#print 'Laying out Level: %s' % lname
		dotin =  'digraph %s {\n' % lname
		dotin += '  size ="50,50";' # 50 inches by 50 inches to help display large graphs in pdf
		dotin += '  graph [\n'
		dotin += '    splines=ortho\n'
		#dotin += '    rankdir=TB\n'
		dotin += '  ];\n'
		dotin += '  node [\n'
		dotin += '    label="",\n'
		dotin += '    xlabel="\\N",\n'
		dotin += '    width=0.001,\n'
		dotin += '    height=0.001,\n'
		dotin += '    shape=point,\n'
		dotin += '    pin=true\n'
		dotin += '  ];\n'
		dotin += '  edge [\n'
		dotin += '    penwidth=15,\n'
		dotin += '    arrowhead=none,\n'
		dotin += '    arrowtail=none\n'
		dotin += '  ];\n'
		dotnodein = ''
		dotedgein = ''
		for jx in lx.getElementsByTagName('joint'):
			if jx.attributes.get('x') is None:
				continue
			jid = jx.attributes['id'].value
			jxcoord = inches2pts(jx.attributes['x'].value)
			jycoord = inches2pts(jx.attributes['y'].value)
			jwidth = float(jx.attributes['width'].value)
			jheight = float(jx.attributes['height'].value)
			nodeid = 'J_%s' % sanitize(jid)
			dotin += '  %s [pos="%s,%s",width=%s,height=%s,shape=box,fixedsize=true];\n' % (jid, jxcoord, jycoord, jwidth, jheight)
		for bx in lx.getElementsByTagName('box'):
			if bx.attributes.get('x') is None:
				continue
			bid = bx.attributes['id'].value
			bxcoord = inches2pts(bx.attributes['x'].value)
			bycoord = inches2pts(bx.attributes['y'].value)
			bwidth = float(bx.attributes['width'].value)
			bheight = float(bx.attributes['height'].value)
			nodeid = 'B_%s' % sanitize(bid)
			dotin += '  %s [pos="%s,%s",width=%s,height=%s,shape=box,fixedsize=true];\n' % (bid, bxcoord, bycoord, bwidth, bheight)
		for linex in lx.getElementsByTagName('line'):
			lid = linex.attributes['id'].value
			dotbegnodeid = '%s_BEG' % lid
			dotendnodeid = '%s_END' % lid
			edgeptsx = linex.getElementsByTagName('point')
			if (edgeptsx is None) or (len(edgeptsx) < 4):
				print 'Warning: layoutlines() expecting lines with at least four layout points, skipping line %s' % lid
			else:
				begx = inches2pts(edgeptsx[1].attributes['x'].value)
				begy = inches2pts(edgeptsx[1].attributes['y'].value)
				endx = inches2pts(edgeptsx[-2].attributes['x'].value)
				endy = inches2pts(edgeptsx[-2].attributes['y'].value)
				dotnodein += '  %s [pos="%s,%s"];\n' % (dotbegnodeid, begx, begy)
				dotnodein += '  %s [pos="%s,%s"];\n' % (dotendnodeid, endx, endy)
				dotedgeid = '%s -> %s' % (dotbegnodeid, dotendnodeid)
				edge2linexml[lname][dotedgeid] = linex
				dotedgein += '  %s ;\n' % (dotedgeid)
		dotin += dotnodein
		dotin += dotedgein
		dotin += '}'
		dotinfilename = '%s-%s-LINES-in.dot' % (outfile, lname)
		writedot = open(dotinfilename,'w')
		writedot.write(dotin)
		writedot.close()
		dotcmd = os.popen('neato -n ' + dotinfilename)
		dotoutput = dotcmd.read()
		dotcmd.close()
		if outputdotfiles:
			dotcmd = os.popen('neato -n -Teps -o%s-%s-LINES.eps %s' % (outfile, lname, dotinfilename))
			dotcmd.read()
			dotcmd.close()
			dotcmd = os.popen('neato -n -Tpdf -o%s-%s-LINES.pdf %s' % (outfile, lname, dotinfilename))
			dotcmd.read()
			dotcmd.close()
			dotoutfilename = '%s-%s-LINES-out.dot' % (outfile, lname)
			writedot = open(dotoutfilename,'w')
			writedot.write(dotoutput)
			writedot.close()
		else:
			os.remove(dotinfilename)
		dotoutput = ' '.join(dotoutput.split()) #get rid of any runs of spaces, newlines, etc
		# Get rid of dot's "continue on next line" character '\' while preserving pos="N,N N,N" formatting
		dotoutput = dotoutput.replace(', \\', ',').replace('\\ ,', ',').replace(' \\ ', ' ').replace('\\', '')
		# Put pairs together that may have been separated
		dotoutput = dotoutput.replace(' , ', ',').replace(', ', ',').replace(' ,', ',')
		dotelms = dotoutput.split(";") #split each element on its own line
		for line in dotelms:
			layout = parsedot(line, False)
			if layout is not None:
				if layout.id is None:
					print 'Warning: invalid layout created for line %s' % line
				if layout.points is not None:
					# Output edge points
					edgex = edge2linexml[lname].get(layout.id)
					if edgex is None:
						print 'Warning: no line xml found for id %s' % layout.id
						continue
					lid = edgex.attributes['id'].value
					edgeptsx = edgex.getElementsByTagName('point')
					if (edgeptsx is None) or (len(edgeptsx) < 4):
						print 'Warning: layoutlines() expecting lines with at least four layout points, skipping line %s' % lid
						continue
					# Take first two and last two points from original xml and add them back into layout
					# Since we have just finished laying out from pts[1] -> pts[-2]
					begx0 = float(edgeptsx[0].attributes['x'].value)
					begy0 = float(edgeptsx[0].attributes['y'].value)
					begx1 = float(edgeptsx[1].attributes['x'].value)
					begy1 = float(edgeptsx[1].attributes['y'].value)
					endx1 = float(edgeptsx[-2].attributes['x'].value)
					endy1 = float(edgeptsx[-2].attributes['y'].value)
					endx0 = float(edgeptsx[-1].attributes['x'].value)
					endy0 = float(edgeptsx[-1].attributes['y'].value)
					# We need the original begx1,begy1 and endx1,endy1 points to match the endpoints
					# returned by dot contained in the layout.points array so subtract the
					# starting points offsets and scale by end.x-start.x and end.y-start.y
					layoutxdist = layout.points[-1].x - layout.points[0].x
					if layoutxdist == 0:
						layoutscalex = 1
					else:
						layoutscalex = (endx1 - begx1) / layoutxdist
					layoutydist = layout.points[-1].y - layout.points[0].y
					if layoutydist == 0:
						layoutscaley = 1
					else:
						layoutscaley = (endy1 - begy1) / layoutydist
					newpts = []
					# Add back original start point
					newpts.append(Point(begx0, begy0))
					# Skip points where they are very close together
					for i in range(len(layout.points)):
						pt = layout.points[i]
						if i == 0:
							prevpt = newpts[0]
						else:
							prevpt = layout.points[i-1]
						if i == len(layout.points) - 1:
							nextpt = Point(endx0, endy0)
						else:
							nextpt = layout.points[i+1]
						# If we haven't changed sufficiently in either x or y, assign to same value and don't add this point to xml
						TOL = 0.1 # if two coords are within this value, treat them as being the same
						skip = False
						if (abs(pt.x - prevpt.x) < TOL):
							pt.x = prevpt.x
							if (abs(pt.x - nextpt.x) < TOL) and (abs(nextpt.x - prevpt.x) < TOL):
								nextpt.x = prevpt.x
								skip = True
						if (abs(pt.y - prevpt.y) < TOL):
							pt.y = prevpt.y
							if (abs(pt.y - nextpt.y) < TOL) and (abs(nextpt.y - prevpt.y) < TOL):
								nextpt.y = prevpt.y
								skip = True
						# don't skip endpoints
						if (i > 0) and (i < len(layout.points) - 1) and skip:
							continue
						newpts.append(Point((pt.x - layout.points[0].x)*layoutscalex + begx1, (pt.y - layout.points[0].y)*layoutscaley + begy1));
					# Add original endpoint
					newpts.append(Point(endx0, endy0))
					# If we have changed the endx value due to rounding the skipped points, change back
					newpts[-2].x = newpts[-1].x
					# Remove current layout points, output new ones
					for oldptx in edgex.getElementsByTagName('point'):
						edgex.removeChild(oldptx)
					prevpt = None
					#print '>output l %s' % lid
					for pt in newpts:
						# If changing x and y, put two points in between @ avg of x
						if prevpt is not None:
							if not (prevpt.x == pt.x) and not (prevpt.y == pt.y):
								pt1 = Point(0.5*(prevpt.x + pt.x), prevpt.y)
								pt2 = Point(0.5*(prevpt.x + pt.x), pt.y)
								#print '  add xpt %s,%s' % (pt1.x, pt1.y)
								#print '  add xpt %s,%s' % (pt2.x, pt2.y)
								xappendpt(allxml, edgex, pt1)
								xappendpt(allxml, edgex, pt2)
						xappendpt(allxml, edgex, pt)
						#print ' add pt %s,%s' % (pt.x, pt.y)
						prevpt = pt
	writelayout = open(outfile + '.xml', 'w')
	writelayout.write(gx.toxml())
	writelayout.close()

### Command line interface ###
if __name__ == "__main__":
	if (len(sys.argv) < 2) or (len(sys.argv) > 4):
		print ('\n\nUsage: %s input_file [output_file] [-o]\n\n  input_file: name of INPUT grid XML to be laid out, '
		'omitting ".xml" extension\n  output_file: (optional) OUTPUT xml/dot file name prefix, if none overwrite '
		'input xml file\n  -o (optional) to write dot layout input and output files including pdf of graph for '
		'each level\n\n\nEx: To parse Test.xml and output TestGraph.xml run: %s Test TestGraph\n') % (sys.argv[0], sys.argv[0])
		quit()
	verbose = True # fixedsize=True should mean that labeling nodes and ports shouldn't affect node sizes
	outputdotfiles = False
	for myarg in sys.argv:
		if myarg == '-o':
			outputdotfiles = True
	infile = sys.argv[1]
	if len(sys.argv) == 2:
		outfile = sys.argv[1]
	else:
		outfile = sys.argv[2]
	layoutboxes(infile, outfile, outputdotfiles)
	#layoutlines(infile, outfile, outputdotfiles) ## too slow at the moment
