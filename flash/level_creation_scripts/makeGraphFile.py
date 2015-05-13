import sys

{"id": "L13076_V4",
"version": 1,
"default": "type:1",
"scoring": {"variables": {"type:0": 0, "type:1": 1}, "constraints": 100},
"variables":{
},
"constraints":[
	"var:78307 <= c:1",
	"c:1 <= var:78333",
    "var:78333 <= c:2",
	"c:2 <= var:78337",
    "var:78337 <= c:3",
	"c:3 <= var:78335",
    "var:78335 <= c:4",
	"c:4 <= var:78307"
 ]
}

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False
		
#for cnf files, need to make a wcnf version
def convertCNFFile(infileName, outfileName):

	infile = open(infileName, 'r')
	outfile = open(outfileName, 'w')
	rootname = infileName.split('/')
	name = rootname[len(rootname)-1].split('.')
	outfile.write("{\n\"id\": \"" + name[0] + "\",\"version\": 1,\n\"default\": \"type:1\",\n\"scoring\": {\"variables\": {\"type:0\": 0, \"type:1\": 1}, \"constraints\": 100},\n\"variables\":{\n},\n\"constraints\":[\n")
	
	addComma = False
	lineCount = 1
	for line in infile:
		lineArray = line.split(' ')
		if is_number(lineArray[0]):

			for	x in range(0, len(lineArray)-1):
				if addComma:
					outfile.write(',\n')
				addComma = True		
				if int(lineArray[x]) > 0:
					outfile.write("\"c:" + str(lineCount) + " <= var:" + lineArray[x] + "\"")
				else:
					outfile.write("\"var:" + str(-int(lineArray[x])) + " <= c:" + str(lineCount) + "\"")
			lineCount = lineCount + 1

	print str(lineCount)
	outfile.write("\n]\n}")
	
#for cnf files, need to make a wcnf version
def convertWCNFFile(infileName, outfileName):

	infile = open(infileName, 'r')
	outfile = open(outfileName, 'w')
	rootname = infileName.split('/')
	name = rootname[len(rootname)-1].split('.')
	outfile.write("{\n\"id\": \"" + name[0] + "\",\"version\": 1,\n\"default\": \"type:1\",\n\"scoring\": {\"variables\": {\"type:0\": 0, \"type:1\": 1}, \"constraints\": 100},\n\"variables\":{\n},\n\"constraints\":[\n")
	
	addComma = False
	lineCount = 1
	for line in infile:

		lineArray = line.split(' ')
		if is_number(lineArray[0]):
			for	x in range(1, len(lineArray)-1):
				val = lineArray[x].strip()
				if val is not "":
					if addComma:
						outfile.write(',\n')
					addComma = True		
					if int(val) > 0:
						outfile.write("\"c:" + str(lineCount) + " <= var:" + val + "\"")
					else:
						outfile.write("\"var:" + str(-int(val)) + " <= c:" + str(lineCount) + "\"")
			lineCount = lineCount + 1

				
	outfile.write("\n]\n}")
	
### Command line interface ###
if __name__ == "__main__":
	if len(sys.argv) != 3:
		print ('\n\nUsage: %s input_file output_file\n\n'
		'  input_file: name of INPUT constraint .json to be laid out,\n'
		'    omitting ".json" extension\n\n'
		'  output_file:  OUTPUT (Constraints/Layout) .json \n'
		'    file name prefix, if none provided use input_file name'
		'\n' % sys.argv[0])
		quit()

infileName = sys.argv[1]
outfileName = sys.argv[2]

if "wcnf" in infileName:	
	convertWCNFFile(infileName, outfileName)
else:
	convertCNFFile(infileName, outfileName)
	