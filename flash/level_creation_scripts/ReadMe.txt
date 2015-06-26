Standard tasks:
(Read the files for more detail)

Create a level from a wcnf, cnf, or json file:

	From wcnf or cnf, run makeConstraintFile.py to create a json file.
	
	From a json file created by Mike's team
		run cnstr/process_constraint_json.py foo, where foo is the root name of the json file
	
	From a level file (constraint of the type "c1 <= v1")
		run ... (not finished...)

	From DIMACS cnf, run makeConstraintFromDIMACS.py to create a json file. Then, run cnstr/process_constraint_json.py on the result to create the level files.

Add a level to the database:

	Think about which files to delete. Game info is retrieved from the ActiveLevels table and the PlayerActivity table. The latter is used to track progress, so I wouldn't remove it,
	but the former is used to choose the next level out of, and so should be cleaned of all levels not wanted any more. You can also remove the GameSolvedLevels table info, but 
	I'd save that as it might be wanted to track submissions for prior levels.
	
	Create a description file for the levels, you can do this by hand, or use createDescriptionFile.py
	
	With the description file, run addLevelToDB.py

zipall.py

Zips a directory of files into individual zip files. Unix only. Usually I upload the json files to a server (upload the zipped collection is far faster, then unzip them) and then run this, as I don't have a Windows equivalent.
	
Autosolve levels:

	Use autosolve_wcnfs.py
	
	If you have json files, use json_to_wcnf.py to convert them.
	
makeConstraints.py

Makes a global constraint file from a wcnf or cnf file.	


Obsolete files in this directory

classic2grid.py
layoutgrid.ph
classic2gridall.py
layoutgridall.py

These files will create and layout a level. classic2grid calls layoutgrid. Run classic2grid/layoutgrid on single levels, classic2gridall/layoutgridall on a directory. These last two are unix only.

obfuscateNames.py

Removes all names from a world, replacing them with consecutive integers. Creates a mapping xml file defining the relationships.

PipeJamRenamer.py

Uses the Pipe Jam classic renaming scheme on a directory of levels.

separateLevelsInWorld.py

Separates a world into disjoint worlds. Copies the varID-sets into each file.



