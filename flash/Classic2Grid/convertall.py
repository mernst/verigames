import sys, os, classic2grid, layoutgrid

inputpath = './input/'
outputpath = './output/'
cmd = os.popen('ls %s*.xml' % inputpath)
for filename in cmd.xreadlines():
	filein = filename.strip().rstrip('.xml')
	fileout = outputpath + filename.strip().lstrip(inputpath).rstrip('.xml')
	print 'Converting %s  -->  %s ...' % (filein, fileout)
	classic2grid.classic2grid(filein, fileout)
	print 'Laying out %s ...' % fileout
	layoutgrid.layout(fileout, fileout, True)
cmd.close()