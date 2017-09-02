import sys

cnf_file = str(sys.argv[1])
target = open(cnf_file + '_processed.cnf', 'w')
cnf_file = cnf_file + '.cnf'



with open(cnf_file) as f:
    cnf_data = f.readlines()

for x in cnf_data:
    x = x.strip()
    x = ' '.join(x.split())
    target.write(x + '\n')
