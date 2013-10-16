import sys, os

inputpath = sys.argv[1]

cmd = os.popen('ls %s*.xml' % inputpath)
for filename in cmd:
	fileout = filename.lstrip(inputpath).rstrip('.xml')
	sys.stdout.write('%s %s' % (inputpath, fileout))
	os.popen('zip %s.zip %s' % (inputpath, filename))
	