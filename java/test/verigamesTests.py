#!/usr/bin/env python
import optparse
import subprocess
import os
import difflib
import sys
import filecmp
import xml.etree.ElementTree as ET

# To add a new checker, for example 'foo':
# 1) append it to the 'allCheckers' list below
#
#	allCheckers = {"nninf", "trusted", "foo"}
#
# 2) create an entry in 'checkerArgs' which states where to find its Checker and Visitor
#
#	checkerArgs = {"nninf": ["nninf.NninfChecker", "nninf.NninfVisitor"],
#			"trusted": ["trusted.TrustedChecker", "trusted.TrustedVisitor"],
#			"foo": ["foo.FooChecker", "foo.FooVisitor"] }
#
# 3) create an entry in 'solverArgs' which states where to find its GameSolver
#
#	solverArgs = {"nninf": ["nninf.NninfGameSolver"],
#			"trusted" : ["trusted.TrustedGameSolver"],
#			"foo": ["foo.FooGameSolver"] }
#
#Now you can call it by using:
#
#	python commandTest.py -c foo
#

allCheckers = ["nninf", "trusted"]
checkerArgs = {"nninf": ["nninf.NninfChecker", "nninf.NninfVisitor"],
		"trusted": ["trusted.TrustedChecker", "trusted.TrustedVisitor"] }

solverArgs = {"nninf": ["nninf.NninfGameSolver"],
		"trusted" : ["trusted.TrustedGameSolver"] }

allTests = ["constraint", "xml"]

def diff_junk_lines(str):
	return not (str.startswith("Total running time: ") or str.startswith("Generation: ") or str.startswith("Solving: ") or str.startswith("Output: "))

def get_immediate_subdirectories(dir):
    	return [name for name in os.listdir(dir)
            if os.path.isdir(os.path.join(dir, name))]

def get_all_java_files(dir):
	return [os.path.join(dir, name) for name in os.listdir(dir)
            if  not os.path.isdir(os.path.join(dir, name)) and name.endswith(".java")]

def remove_layout(name):
	tree = ET.parse(name)
	root = tree.getroot()
	for var in root.iter('layout'):
		for x in var.findall('x'):
			var.remove(x)
		for y in var.findall('y'):
			var.remove(y)
	for var in root.iter('point'):
		for x in var.findall('x'):
			var.remove(x)
		for y in var.findall('y'):
			var.remove(y)
	tree.write(name)

def compare_results(expectedName, actualName, diffName):					
	e = open(expectedName)
	a = open(actualName)
	same = filecmp.cmp(expectedName, actualName)
	if (not same) :
		expected = e.readlines()
		actual = a.readlines()
		e.close()
		a.close()
		diff = difflib.unified_diff(expected, actual)
		d = open(diffName, "w")
		d.writelines(diff)
		d.close()
	return same

def main():
	p = optparse.OptionParser()
	p.add_option('--checker', '-c', default="all", help="The type system to use: nninf, trusted, or all. Default is all")
	p.add_option('--tests', '-t', default="all", help="The test suite to run: constraint, xml, or all. Default is all")
	p.add_option('--debug', '-d',  action="store_true", dest="debug", help="Remote debug using port 5005.")
	options, arguments = p.parse_args()

	checkers = allCheckers if options.checker == "all" else [options.checker]
	testsuites = allTests if options.tests == "all" else [options.tests]

	if checkers[0] not in allCheckers:
		print "Unknown checker."
		return
	if testsuites[0] not in allTests:
		print "Unknown test suite."
		return

	print "Type systems: " + str(checkers)
	print "Test suites: " + str(testsuites)
	print
	
	numTests = 0
	numFails = 0
	numErrors = 0

	if options.debug:
		scriptName = "./debugScript.sh"
	else:
		scriptName = "./testScript.sh"
	
	os.putenv("JAVA", os.getenv("JAVA_HOME") + "/bin/java")
	os.putenv("SCALA", os.getenv("SCALA_HOME") + "/bin/scala")
	os.putenv("CLASSPATH", "../verigames.jar")

	failingTests = []

	for testsuite in testsuites:
		print "---Running " + testsuite + " tests---"
		expectedName=""
		actualName=""
		diffName=""
		for test in get_immediate_subdirectories(testsuite + "Tests"):
			javaFiles = get_all_java_files(testsuite +"Tests/" + test)
			for checker in checkers:
				if testsuite == "xml" :
					expectedName = "xmlTests/" + test + "/expected_" + checker + ".xml"
					# Check that an expected file for this checker/test combination exists
					if os.path.isfile(expectedName):
						numTests = numTests + 1
						actualName = "xmlTests/" + test + "/actual_" + checker + ".xml"
						diffName = "xmlTests/" + test + "/diff_" + checker + ".txt"
						# Run the test
						with open(os.devnull, "w") as outfile:
							ret = subprocess.call([scriptName] + checkerArgs[checker] + solverArgs[checker] + javaFiles, stdout=outfile)
							if ret != 0: # Error
								numErrors = numErrors + 1
								print "Error: " + test + " for " + checker + " returned error code " + str(ret)
							else: 
								subprocess.call(["rm", "inference.jaif"]) # cleanup
								subprocess.call(["mv", "World.xml", actualName]) # organize

								# Remove layout information
								remove_layout(expectedName)
								remove_layout(actualName)

				elif testsuite == "constraint":
					expectedName = "constraintTests/" + test + "/expected_" + checker + ".txt"
					# Check that an expected file for this checker/test combination exists
					if os.path.isfile(expectedName):
						numTests = numTests + 1
						actualName = "constraintTests/" + test + "/actual_" + checker + ".txt"
						diffName = "constraintTests/" + test + "/diff_" + checker + ".txt"
						os.putenv("ACTUAL_PATH", actualName)
						# Run the test
						with open(os.devnull, "w") as outfile:
							ret = subprocess.call([scriptName] + checkerArgs[checker] + ["test.TestGameSolver"] + javaFiles, stdout=outfile)
							if ret != 0: # Error
								numErrors = numErrors + 1
								print "Error: " + test + " for " + checker + " returned error code " + str(ret)
							else:
								subprocess.call(["rm", "World.xml", "inference.jaif"]) # cleanup

				# Compare the results
				if os.path.isfile(expectedName) and not ret:
					same = compare_results(expectedName, actualName, diffName)
					if (not same) :
						numFails = numFails + 1
						failingTests = failingTests + [testsuite + " test: " + test + ", Checker: " + checker]
					else:
						subprocess.call(["rm", actualName])
		if failingTests:
			print
			print "Failing tests:"
			for fail in failingTests :
				print fail
			print
		failingTests = []

	print "Tests run: " + str(numTests) + ", Passed: " + str(numTests - numErrors - numFails) + ", Errors: " + str(numErrors) + ", Failures: " + str(numFails)

if __name__ == '__main__':
	main()
