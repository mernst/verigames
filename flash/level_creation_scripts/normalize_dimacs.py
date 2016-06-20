# this script is intended to convert DIMACS files that have clauses
# spread across multiple lines into ones that have each clause on a
# single line

import sys


cur_clause = []
clause_count = 0
header = None

for line in sys.stdin.xreadlines():
    line = line.strip()
    
    if len(line) == 0:
        continue

    if line[0] == '%':
        continue

    if line[0] == 'c':
        sys.stdout.write(line + '\n')
        continue

    if line[0] == 'p':
        header = line
        sys.stdout.write(line + '\n')
        continue

    for item in [int(x) for x in line.split()]:
        if item == 0:
            if len(cur_clause) != 0:
                sys.stdout.write(' '.join([str(x) for x in cur_clause]) + ' 0\n')
                clause_count += 1
                cur_clause = []
        else:
            cur_clause.append(item)

if len(cur_clause) != 0:
    sys.stderr.write('note: unterminated clause output\n')
    sys.stdout.write(' '.join([str(x) for x in cur_clause]) + ' 0\n')
    clause_count += 1
    cur_clause = []

if header:
    sys.stderr.write('header: ' + header + '\n')
else:
    sys.stderr.write('note: no header found\n')

sys.stderr.write('clauses output: ' + str(clause_count) + '\n')
