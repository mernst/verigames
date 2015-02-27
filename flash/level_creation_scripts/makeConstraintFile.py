import sys, os

{
"version": 1,
"constraints":[
{
"sub": "var:46",
"constraint":"subtype",
"sup":"var:1231"
}
 ]
}

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False
		
def convertFile(infileName, outfileName):
	try:
		if "wcnf" in infileName:
			startIndex = 1
		else:
			startIndex = 0
			
		infile = open(infileName, 'r')
		outfile = open(outfileName, 'w')
		rootname = infileName.split('/')
		name = rootname[len(rootname)-1].split('.')
		outfile.write("{\n\"version\": \"2\",\n\"constraints\":[\n")
		print outfileName
		addComma = False
		lineCount = 1
		for line in infile:
			lineArray = line.split(' ')
			if is_number(lineArray[0]) and len(lineArray) >startIndex+1:
				c1 = int(lineArray[startIndex])
				c2 = int(lineArray[startIndex+1])
				reverse = False
				case = 1
				if c1 < 0 and c2 > 0:
					sub = -c1
					sup = c2
				elif c1 > 0 and c2 < 0:
					sup = c1
					sub = -c2
				else:
					reverse = True
					if c1 < 0:
						sub = -c1
						sup = -c2
						case = 2
					else:
						sub = c1
						sup = c2
						case = 3
						
				if addComma is True:
						outfile.write(',\n')
				if case == 1:
					outfile.write('{\n')	
					outfile.write("\"sub\": \"var:" + str(sub) + "\",\n")
					outfile.write('"constraint":"subtype",\n')
					outfile.write("\"sup\": \"var:" + str(sup) + "\"\n")
					outfile.write('}\n')
					if reverse:
						if addComma is True:
							outfile.write(',\n')
						outfile.write('{\n')
						outfile.write("\"sub\": \"var:" + str(sup) + "\",\n")
						outfile.write('"constraint":"subtype",\n')
						outfile.write("\"sup\": \"var:" + str(sub) + "\"\n")
						outfile.write('}\n')
				elif case == 2:
					outfile.write('{\n')	
					outfile.write("\"sub\": \"var:" + str(sub) + "\",\n")
					outfile.write('"constraint":"lessthan",\n')
					outfile.write("\"sup\": \"var:" + str(sup) + "\"\n")
					outfile.write('}\n')
				else:
					outfile.write('{\n')	
					outfile.write("\"sub\": \"var:" + str(sup) + "\",\n")
					outfile.write('"constraint":"greaterthan",\n')
					outfile.write("\"sup\": \"var:" + str(sub) + "\"\n")
					outfile.write('}\n')
					
				lineCount = lineCount + 1
				addComma = True
			elif 'p' in lineArray[0]:
				numNodes = int(lineArray[2])
				numClauses = int(lineArray[3])

		print str(lineCount)
		outfile.write("\n]\n}")
		outfile.close()
	except Exception, e:
		print e
### Command line interface ###
if __name__ == "__main__":
	if len(sys.argv) != 3:
		print ('\n\nUsage: %s input_file_or_directory output_file_or_directory\n\n'
		'  input_file: name of INPUT cnf/wncf or directory containing such\n'
		'  output_file: name of  OUTPUT cnf/wncf or directory \n'
		'    the type (file/directory) should match the input'
		'\n' % sys.argv[0])
		quit()

infileName = sys.argv[1]
outfileName = sys.argv[2]

if os.path.isdir(infileName):
	if infileName[-1:] is not '/' and infileName[-1:] is not '\\':
		infileName = infileName + '/'
	if os.path.isdir(outfileName):
		if outfileName[-1:] is not '/' and outfileName[-1:] is not '\\':
			outfileName = outfileName + '/'
		cmd = os.popen('ls %s*' % infileName)
		for filename in cmd:
			filename = filename.strip()
			if '.wcnf' in filename or '.cnf' in filename:
				print filename
				filerootIndex = filename.rfind('/')
				fileExtensionIndex = filename.rfind('.')
				fileroot = filename[filerootIndex+1:fileExtensionIndex]
				convertFile(filename, outfileName + fileroot + '.json')
	else:
		print 'if argv[1] is a directory, argv[2] should be too'
		
else:
	convertFile(infileName, outfileName)

	