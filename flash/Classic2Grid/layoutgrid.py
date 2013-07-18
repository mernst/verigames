import os, sys, re
from xml.dom.minidom import parse

# Globally round graphviz coordinates
decimalplacestoroundto = 2

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
	return thing.replace('-','_DSH_')
	
# replace characters that dot doesn't like, output is original unsanitized string
def desanitize(thing):
	return thing.replace('_DSH_','-')

# convert points (default for pos information) to inches (default for width, height information)
def pts2inches(pts):
	return float(pts) / 72.0

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
	print '2'
	return None

# Parse the dot width/height/position/points information and return a DotLayout object
def parsedot(line):
	line = line.strip()
	if (line.find('digraph') == 0) or (line.find('graph') == 0) or (line.find('node') == 0) or (line.find('edge') == 0) or (line.find('}') == 0) or (line.find('{') == 0):
		return None
	lb = line.find('[')
	if lb == -1:
		print "Couldn't process dot output: %s" % line
		return None
	id = line[:lb].strip()
	attr = line[lb:]
	attribs = parseattrib(attr)
	if attribs.get('pos'):
		pos = attribs.get('pos')
		if pos.count(',') > 1:
			# These are edge points, parse them individually - take only the first and last
			pts = []
			allpointpairs = pos.split(' ')
			firstpair = allpointpairs[0]
			lastpair = allpointpairs[-1]
			for pair in [firstpair, lastpair]:
				if len(pair.split(',')) == 2:
					posx = float(pair.split(',')[0].strip())
					posy = float(pair.split(',')[1].strip())
					posx = pts2inches(posx)
					posy = pts2inches(posy)
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


### Main function ###
def layout(infile, outfile, outputdotfiles):
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
		dotin += '    splines=spline\n'
		dotin += '  ];\n'
		dotin += '  node [\n'
		dotin += '    fontsize=14.0,\n'
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
			boxheight = blines / 4.0 + 0.75
			dotin += '  %s [width=%s,height=%s,label="%s"];\n' % (nodeid, (blines + 2) * WIDTHPERPORT, boxheight, blabel)
			boxdotheight[nodeid] = boxheight
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
		dotinfilename = '%s-%s-in.dot' % (outfile, lname)
		writedot = open(dotinfilename,'w')
		writedot.write(dotin)
		writedot.close()
		dotcmd = os.popen('dot ' + dotinfilename)
		dotoutput = dotcmd.read()
		dotcmd.close()
		if outputdotfiles:
			dotcmd = os.popen('dot -Teps -o%s-%s.eps %s' % (outfile, lname, dotinfilename))
			dotcmd.read()
			dotcmd.close()
			dotoutfilename = '%s-%s-out.dot' % (outfile, lname)
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
		
		linenum = 0
		for line in dotelms[:3]:
			bb = parsebb(line)
			if bb is not None:
				#print 'Bounding Box: %s,%s %s,%s' % (bb[0].x, bb[0].y, bb[1].x, bb[1].y)
				break
		if bb is None:
			print 'Warning: No bounding box found in graph. Creating dummy bb = 0,0 to 500,500'
			bb = [Point(0,0), Point(500,500)]
		maxy = bb[1].y
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
							layout.points[0].y += foundboxheight / 2.0 - 0.5
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
							layout.points[-1].y -= foundboxheight / 2.0 - 0.5
					else:
						print 'Warning: edge found that has no tobox or frombox id %s' % layout.id
					# Remove any current layout points, we only want the new layout points to be saved
					for oldptx in edgex.getElementsByTagName('point'):
						edgex.removeChild(oldptx)
					for pt in layout.points:
						ptx = allxml.createElement('point')
						ptx.setAttribute('x', tostr(pt.x))
						ptx.setAttribute('y', tostr(maxy - pt.y))
						edgex.appendChild(ptx)
				elif layout.pos is not None:
					# Output node position
					nodex = node2xml[lname].get(layout.id)
					if nodex is None:
						print 'Warning: no node found for id %s' % layout.id
						continue
					nodex.setAttribute('x', tostr(layout.pos.x))
					foundboxheight = boxdotheight.get(layout.id)
					if foundboxheight is not None:
						# Adjust y to account for difference in forcing height to = 1.0
						layout.pos.y -= foundboxheight / 2.0 - 0.5
						# Now force height to = 1.0
						foundboxheight = 1.0
					else:
						# Must be a joint, leave y and height alone
						foundboxheight = layout.height
					nodex.setAttribute('y', tostr(maxy - layout.pos.y))
					if 'width' in nodex.attributes.keys():
						nodex.removeAttribute('width')
					if 'height' in nodex.attributes.keys():
						nodex.removeAttribute('height')
					if layout.width is not None:
						nodex.setAttribute('width', tostr(layout.width))
					if layout.height is not None:
						nodex.setAttribute('height', tostr(foundboxheight))
				else:
					print 'Warning: bad layout created for line: %s' % line
	writelayout = open(outfile + '.xml','w')
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
	layout(infile, outfile, outputdotfiles)
