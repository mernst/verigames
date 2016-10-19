f = open('par8-2.cnf', 'r')
f1 = open('par8-2mod.cnf', 'w')


lines = []
for line in f:
	if line[0] == " ":
		lines.append(line[1:])
		f1.write(line[1:])

	else:
		lines.append(line)
		f1.write(line)
		print line

# # for line in lines:
# # 	f1.write(line + " 0")





f.close()
f1.close()
