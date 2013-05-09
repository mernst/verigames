import os, sys, re
from xml.dom.minidom import parse

### Dictionaries ###
coords = {}

# edge2line[levelid][dotedgestring] = line id
edge2line = {}

### Regex ###
dotre = re.compile(r'^\s*([^\s]*) \[pos="([^\s]*)", width=".*", height=".*"\];\s*$')

# Creates the input and output labels to be referenced like ports in the "record" style dot nodes
def createportlabels(ports, id=None):
	label = '{{|'
	for port in range(ports):
		label += '<i%s>i%s|' % (port, port)
	if id is not None:
		label += '}|%s|{|' % id
	else:
		label += '}|{|'
	for port in range(ports):
		label += '<o%s>o%s|' % (port, port)
	label += '}}'
	return label

### Main function ###
if len(sys.argv) != 2:
	print 'Usage: %s [name of grid XML to be laid out, omitting ".xml" extension]\nEx: To parse Test.xml run: %s Test' % (sys.argv[0], sys.argv[0])
	quit()
allxml = parse(sys.argv[1] + '.xml')
graphs = allxml.getElementsByTagName('graph')
if len(graphs) != 1:
	print 'Warning: expecting 1 graph, found %d, processing only the first graph' % len(graphs)
gx = graphs[0]

for lx in gx.getElementsByTagName('level'):
	lname = lx.attributes['id'].value
	edge2line[lname] = {}
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
	dotin += '    fontsize=25.0,\n'
#	dotin += '    width=0.5,\n'
#	dotin += '    height=1.0,\n'
	dotin += '    "fixed-size"=true,\n'
	dotin += '    shape=record\n'
	dotin += '  ];\n'
	for jx in lx.getElementsByTagName('joint'):
		jid = jx.attributes['id'].value
		jin = int(jx.attributes['inputs'].value)
		jout = int(jx.attributes['outputs'].value)
		jwidth = max(jin, jout)
		jlabel = createportlabels(jwidth)
		dotin += '  J_%s [width=%s,height=0.5,label="%s"];\n' % (jid, jwidth, jlabel)
	for bx in lx.getElementsByTagName('box'):
		bid = bx.attributes['id'].value
		blines = int(bx.attributes['lines'].value)
		blabel = createportlabels(blines, bid)
		dotin += '  B_%s [width=%s,height=1.0,label="%s"];\n' % (bid, blines, blabel)
	for linex in lx.getElementsByTagName('line'):
		lid = linex.attributes['id'].value
		if (len(linex.getElementsByTagName('fromjoint')) == 1) and (len(linex.getElementsByTagName('tobox')) == 1):
			fromid = 'J_%s' % linex.getElementsByTagName('fromjoint')[0].attributes['id'].value
			fromport = linex.getElementsByTagName('fromjoint')[0].attributes['port'].value
			toid = 'B_%s' % linex.getElementsByTagName('tobox')[0].attributes['id'].value
			toport = linex.getElementsByTagName('tobox')[0].attributes['port'].value
		elif (len(linex.getElementsByTagName('frombox')) == 1) and (len(linex.getElementsByTagName('tojoint')) == 1):
			fromid = 'B_%s' % linex.getElementsByTagName('frombox')[0].attributes['id'].value
			fromport = linex.getElementsByTagName('frombox')[0].attributes['port'].value
			toid = 'J_%s' % linex.getElementsByTagName('tojoint')[0].attributes['id'].value
			toport = linex.getElementsByTagName('tojoint')[0].attributes['port'].value
		else:
			print 'Warning: unsupported input/outputs for line id: %s' % lid
			continue
		edgeid = '%s:o%s -> %s:i%s' % (fromid, fromport, toid, toport)
		edge2line[lname][edgeid] = lid
		dotin += '  %s;\n' % (edgeid)
	dotin += '}'
print dotin
'''
for line in os.popen('echo \"' + dotin + '\" | dot -Grankdir=TB -N shape=box -Nfixed-size=true -Nheight=10 -Nwidth=5 -Gsplines=none -Gnodesep=10 -Granksep=10').xreadlines():
    res = dotre.match(line)
    if res:
        coords[res.group(1)] = [str(int(1.5 * float(nn))) for nn in res.group(2).split(',')]

for line in open(sys.argv[1]).xreadlines():
    res = xmlnodere.match(line)
    if res:
        id = res.group(2)
        xx, yy = coords[id]
        print res.group(1) + id + res.group(3) + xx + res.group(5) + yy + res.group(7)
    else:
        print line,
'''
