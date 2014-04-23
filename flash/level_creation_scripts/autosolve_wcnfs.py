'''
Note: before running this script,
download:
	http://home.mis.u-picardie.fr/~cli/maxsatz2009.c
	http://www.laria.u-picardie.fr/~cli/maxsatz.tar.gz
build:
	gcc maxsatz2009.c -o maxsatz2009
	gcc maxsatz.c -o maxsatz
'''
import os, json
SCRIPT_PATH = os.path.dirname(os.path.realpath(__file__))

all_assignments = {}
files = [f for f in os.listdir('.') if os.path.isfile(f)]
n_autosolve_levels = 0
n_total_levels = 0
n_autosolve_nodes = 0
n_total_nodes = 0
n_autosolve_constraints = 0
n_total_constraints = 0
for fname in files:
	is_sat = False
	is_weighted = False
	if fname[-5:] == '.wcnf':
		n_total_levels += 1
		n_autosolve_levels += 1
		fprefix = fname[:-5]
		is_sat = True
		is_weighted = True
	elif fname[-4:] == '.cnf':
		n_total_levels += 1
		fprefix = fname[:-4]
		is_sat = True
	if is_sat:
		if is_weighted:
			ext = 'wcnf'
			print '%s (weighted)' % fprefix
		else:
			ext = 'cnf'
			print fprefix
		# Get mapping of sat var ids (1->n) to original constraint vars (var:12452, etc) from comment in wcnf
		keys = []
		with open('%s.%s' % (fprefix, ext), 'r') as sat_in:
			for input_line in sat_in:
				input_line = input_line.strip()
				if input_line[:7] == 'c keys ':
					keys = input_line[7:].strip().split(' ')
				elif input_line[:9] == 'c offset ':
					score_offset = float(input_line[9:].strip())
				elif input_line[:7] == 'p wcnf ':
					nodes_constraints = input_line[7:].split(' ')
					n_autosolve_nodes += int(nodes_constraints[0])
					n_total_nodes += int(nodes_constraints[0])
					n_autosolve_constraints += int(nodes_constraints[1])
					n_total_constraints += int(nodes_constraints[1])
				elif input_line[:7] == 'p cnf ':
					nodes_constraints = input_line[7:].split(' ')
					n_total_nodes += int(nodes_constraints[0])
					n_total_constraints += int(nodes_constraints[1])
		with os.popen('%s/maxsatz2009 %s.%s' % (SCRIPT_PATH, fprefix, ext)) as sat_cmd:
			lines = sat_cmd.readlines()
			max_score = None
			penalty = None
			assignments = {}
			for line in lines:
				if line[:2] == 'o ':
					if max_score is None:
						max_score = float(line[2:-1].strip())
					else:
						penalty = float(line[2:-1].strip())
				elif line[:2] == 'v ':
					assignments = line[2:-3].strip().split(' ')
			for sat_value_str in assignments:
				sat_value = int(sat_value_str)
				sat_id = abs(sat_value)
				if sat_id == sat_value: # if positive, set assignment to 1 = type:1
					constraint_value = 'type:1'
				else:
					constraint_value = 'type:0'
				if sat_id > len(keys):
					print 'Warning! Found sat variable id out of range given in keys from .%s file: %s len(keys): %s' % (ext, sat_id, len(keys))
					continue
				constraint_id = 'var:%s' % keys[sat_id-1]
				if all_assignments.get(constraint_id) is not None:
					print 'Warning! Multiple assignments found for %s' % constraint_id
					continue
				all_assignments[constraint_id] = constraint_value
		with open('%s.out' % fprefix, 'w') as cnf_out:
			for line in lines:
				cnf_out.write(line)
		#Attempt to write target score to constraints json file
		try:
			with open('%sAssignments.json' % fprefix, 'r') as constr_in:
				lines = constr_in.readlines()
				target_score_line = -1
				starting_score = None
				for i, line in enumerate(lines):
					if line.strip()[:14] == '"target_score"' or line.strip()[:14] == "'target_score'":
						target_score_line = i
					elif line.strip()[:17] == '"starting_score:"' or line.strip()[:17] == "'starting_score:'":
						starting_score = float(line.strip()[17:].strip()[:-1])
			if is_weighted:
				target_score = float(max_score - penalty) + score_offset
			else:
				#TODO: just multiply by 100 for now since they're all identical in this version
				target_score = float(100.0*(max_score - penalty)) + score_offset
			target_score_str = '"target_score":%s,\n' % target_score
			if target_score_line == -1:
				lines.insert(1, target_score_str) # if no target score already, just write to second line
			else:
				lines[target_score_line] = target_score_str
			lines = ''.join(lines)
			os.remove('%sAssignments.json' % fprefix)
			with open('%sAssignments.json' % fprefix, 'w') as constr_out:
				constr_out.write(lines)
			if starting_score >= float(max_score - penalty):
				print 'Starting Score >= Target, moving to auto folder...'
				auto_dir = os.path.dirname('auto/')
				if not os.path.exists(auto_dir):
					os.makedirs(auto_dir)
				os.rename('%s.json' % fprefix, 'auto/%s.json' % fprefix)
				os.rename('%sAssignments.json' % fprefix, 'auto/%sAssignments.json' % fprefix)
				os.rename('%sLayout.json' % fprefix, 'auto/%sLayout.json' % fprefix)
		except Exception as e:
			print 'Error writing target score: %s' % e
			continue
with open('AllAssignments.json', 'w') as asg_out:
	asg_out.write(json.dumps(all_assignments))
print 'Levels: %s autosolved / %s total = %s%' % (n_autosolve_levels, n_total_levels, (n_autosolve_levels / n_total_levels))
print 'Nodes: %s autosolved / %s total = %s%' % (n_autosolve_nodes, n_total_nodes, (n_autosolve_nodes / n_total_nodes))
print 'constraints: %s autosolved / %s total = %s%' % (n_autosolve_constraints, n_total_constraints, (n_autosolve_constraints / n_total_constraints))