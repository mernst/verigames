# this script is intended to convert DIMACS files that have clauses
# spread across multiple lines into ones that have each clause on a
# single line

import sys


cur_clause = []
clause_count = 0
max_var = 0
header = None

for line in sys.stdin.xreadlines():
    line = line.strip()
    
    if len(line) == 0:
        continue

    if line[0] == '%':
        if len(cur_clause) != 0:
            raise RuntimeError('Comment during clause.')
        continue

    if line[0] == 'c':
        if len(cur_clause) != 0:
            raise RuntimeError('Comment during clause.')

        sys.stdout.write(line + '\n')
        continue

    if line[0] == 'p':
        if header:
            raise RuntimeError('Duplicate header: %s.' % (line))
        if len(cur_clause) != 0:
            raise RuntimeError('Header during clause.')
        if clause_count != 0:
            raise RuntimeError('Header after clause.')

        header = line.split()
        if len(header) != 4 or header[0] != 'p' or header[1] not in ['cnf', 'wcnf'] or not header[2].isdigit() or not header[3].isdigit():
            raise RuntimeError('Bad header: %s.' % (line))

        sys.stdout.write(' '.join(header) + '\n')
        continue

    if not header:
        raise RuntimeError('Clause before header.')

    for item in [int(x) for x in line.split()]:
        if item == 0:
            if len(cur_clause) != 0:
                sys.stdout.write(' '.join([str(x) for x in cur_clause]) + ' 0\n')
                clause_count += 1
                cur_clause = []
        else:
            if header[1] == 'cnf' or (header[1] == 'wcnf' and len(cur_clause) > 0):
                max_var = max(max_var, abs(item))

            cur_clause.append(item)


if len(cur_clause) != 0:
    raise RuntimeError('Unterminated clause.')

if header:
    sys.stderr.write('header: ' + ' '.join(header) + '\n')
else:
    raise RuntimeError('No header found.')

if int(header[2]) != max_var:
    raise RuntimeError('Variable count mismatch (expected %d, found %d).' % (int(header[2]), max_var))

if int(header[3]) != clause_count:
    raise RuntimeError('Clause count mismatch (expected %d, found %d).' % (int(header[3]), clause_count))

sys.stderr.write('clauses output: ' + str(clause_count) + '\n')
