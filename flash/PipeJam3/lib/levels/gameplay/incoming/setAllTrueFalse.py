import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("cnffile")
parser.add_argument('--f', action='store_true')
parser.add_argument('--t', action='store_true')

args = parser.parse_args()
cnf_file = args.cnffile

if args.f:
    set_to = False
else:
    set_to = True

with open(cnf_file) as f:
    cnf_data = f.readlines()

num_vars = 0
num_clauses = 0
variables = []
num_sat_when_true = 0
num_sat_when_false = 0
for x in cnf_data:
    x = x.strip()
    data = x.split()
    if x[0] == 'c' or x[0] == '0':
        continue
    if x[0] == 'p':
        num_vars = int(data[2])
        num_clauses = int(data[3])
        if set_to == False:
            variables = [False] * num_vars
        else:
            variables = [True] * num_vars
    else:
        if data[-1] == '0':
            del data[-1]
        clause_when_false = False
        clause_when_true = False
        for v in data:
            #print data
            v = int(v)
            if v < 0:
                #clause = clause or not(set_to)
                clause_when_false = clause_when_false or True
                clause_when_true = clause_when_true or False
            else:
                #clause = clause or set_to
                clause_when_false = clause_when_false or False
                clause_when_true = clause_when_true or True
        print data, ' ', clause_when_true, ' ', clause_when_false
        if clause_when_true:
            num_sat_when_true += 1
        if clause_when_false:
            num_sat_when_false += 1

print "Num satisfied when true: ", num_sat_when_true
print "Num satisfied when false: ", num_sat_when_false
print "% clauses satisfied when all true: ", ((num_sat_when_true * 100) / num_clauses)
print "% clauses satisfied when all false: ", ((num_sat_when_false * 100) / num_clauses)
