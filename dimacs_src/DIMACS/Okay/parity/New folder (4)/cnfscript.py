f = open('par32-4-c.cnf', 'r')
f1 = open('par32-4-cmod.cnf', 'w')


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
