import sys
import os


files = os.listdir(os.path)


for file in files:

	if ".cnf" in file:
		folder = file.split(".")[0]
		subprocess.call("makeConstraintFromDIMACS.py", file, folder) 

		newFiles = os.listdir(os.path)

		if folder+".json" in newFiles:

			subprocess.call("process_constraint.py", folder)

			
