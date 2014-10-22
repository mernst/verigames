import sys

{
"id": "L13076_V4",
"layout": {
  "vars": {
     "var_78307":{"y":-5,"x":-5},
     "var_78333":{"y":-5,"x":20},
     "var_78337":{"y":20,"x":20},
     "var_78335":{"y":20,"x":-5},
	 "c_1":{"y":-5,"x":10},
     "c_2":{"y":10,"x":20},
     "c_3":{"y":20,"x":10},
     "c_4":{"y":10,"x":-5}
  }
}}

def convertFile(infileName, outfileName):

	infile = open(infileName, 'r')
	outfile = open(outfileName, 'w')
	rootname = infileName.split('/')
	name = rootname[len(rootname)-1].split('.')
	outfile.write("{\n\"id\": \"" + name[0] + "\",\n\"layout\": {\n\"vars\": {\n")
	addComma = False
	for line in infile:
		lineArray = line.split(' ')
		if "edge" in lineArray[0]:
			break
			
		if len(lineArray) > 4:
			if addComma:
				outfile.write(',\n')
			addComma = True
			varName = lineArray[1]
			if "v_" in varName:
				parts = varName.split('_')
				varName = "var_" + parts[1]
			outfile.write("\t\"" + varName + '":{"x":' + lineArray[2] + ',"y":' + lineArray[3] +'}')
		
	outfile.write("\n}\n}}")
### Command line interface ###
if __name__ == "__main__":
	if len(sys.argv) != 3:
		print ('\n\nUsage: %s input_file [output_file]\n\n'
		'  input_file: name of INPUT constraint .json to be laid out,\n'
		'    omitting ".json" extension\n\n'
		'  output_file: (optional) OUTPUT (Constraints/Layout) .json \n'
		'    file name prefix, if none provided use input_file name'
		'\n' % sys.argv[0])
		quit()

infileName = sys.argv[1]
outfileName = sys.argv[2]
	
convertFile(infileName, outfileName)
	