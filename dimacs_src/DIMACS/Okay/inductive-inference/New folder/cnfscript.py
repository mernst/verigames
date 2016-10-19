f = open('ii8a1.cnf', 'r')
f1 = open('ii8a1mod.cnf', 'r')
f2 = open('ii8a1modmod.cnf', 'w')

# lines = []
# for line in f:
# 	if line[0] == " ":
# 		lines.append(line[1:])
# 		f1.write(line[1:])

# 	else:
# 		lines.append(line)
# 		f1.write(line)
# 		print line

# # for line in lines:
# # 	f1.write(line + " 0")



for line in f1:
	print line + " 0"
	f2.write(line)

f.close()
f1.close()
f2.close()