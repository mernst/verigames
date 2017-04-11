import sys

def initInfo():
    return ('{\n\t"constraints": [\n')

# if a line starts with p, check that it contains 'cnf'
def readPLine(vals):
    if('cnf' not in vals):
        print 'Cannot handle formats other than cnf'
        quit()
        
def addListItems(list):
    string = ''
    for i in range (0, len(list)):
        if list[i] == '0':
            break;
        else:
            string += '"var:' + list[i] + '", '
    string = string[:-2] + '],\n'
    return string 
        
if len(sys.argv) != 3:
    print 'Must have desired target and output name (omitting ".json") as args'
    quit()
    
# gets the lines of the input as a list
with open(sys.argv[1]) as f:
    content = f.readlines()
    
result = initInfo()
comments = []

for line in content:
    # get the individual items in the line as a list
    values = line.split()

    if len(values) == 0:
        continue

    if values[0] == 'c':
        # remember comments
        comment = line[1:].rstrip()
        if len(comment) > 0 and comment[0] == ' ':
            comment = comment[1:]
        comments.append(comment)

    elif values[0] == 'p':
        # check if the line starts with a p
        readPLine(values)

    else:
        # the first line of each
        result += '\t\t{\n\t\t\t"constraint": "clause",\n'
            
        pos = []
        neg = []

        # for each item in the list of items
        for i in range (0, len(values)):
            ##if (len(values) == 2):
                ##print 'Invalid format'
                ##quit()
            
            if (int(values[i]) > 0):
                pos.append(values[i])
            else: 
                (neg.append(str(abs(int(values[i])))))
                
        result += '\t\t\t"pos": ['
        result += addListItems(pos)
        
        result += '\t\t\t"neg": ['
        result += addListItems(neg)
        
        result = result[:-2] + '\n'
        
        result += '\t\t},\n'
                    
result = result[:-2] + '\n\t],\n'

if len(comments) != 0:
    result += '\t"comments": [\n'
    for ii, comment in enumerate(comments):
        result += '\t\t"' + comment.replace('"', '\'') + '"'
        if ii + 1 != len(comments):
            result += ','
        result += '\n'
    result += '\t],\n'

result += '\t"version": "2"\n'
result += '}\n'

text_file = open(sys.argv[2] + ".json", "w")
text_file.write(result)
text_file.close()
