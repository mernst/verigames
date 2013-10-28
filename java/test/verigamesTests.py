#!/usr/bin/env python
import optparse
import subprocess
import os
import difflib
import sys
import filecmp
import xml.etree.ElementTree as ET
import re

# To add a new checker, for example 'foo':
# 1) append it to the 'allCheckers' list below
#
#    allCheckers = {"nninf", "trusted", "foo"}
#
# 2) create an entry in 'checkerArgs' which states where to find its Checker and Visitor
#
#    checkerArgs = {"nninf": ["nninf.NninfChecker", "nninf.NninfVisitor"],
#            "trusted": ["trusted.TrustedChecker", "trusted.TrustedVisitor"],
#            "foo": ["foo.FooChecker", "foo.FooVisitor"] }
#
# 3) create an entry in 'solverArgs' which states where to find its GameSolver
#
#    solverArgs = {"nninf": ["nninf.NninfGameSolver"],
#            "trusted" : ["trusted.TrustedGameSolver"],
#            "foo": ["foo.FooGameSolver"] }
#
#Now you can call it by using:
#
#    python commandTest.py -c foo
#

thisFile = os.path.realpath(__file__)
parent   = os.path.dirname(thisFile)

allCheckers = ["nullness", "trusted"]
checkerArgs = {"nullness": ["nninf.NninfChecker", "nninf.NninfVisitor",
                            "nninf.NninfTransferImpl", "checkers.inference.InferenceAnalysis"],
               "trusted":  ["trusted.TrustedChecker", "trusted.TrustedVisitor",
                            "checkers.inference.InferenceTransfer", "checkers.inference.InferenceAnalysis"]  }

solverArgs = {"nullness": ["nninf.NninfGameSolver"],
        "trusted" : ["trusted.TrustedGameSolver"] }

allTests = ["constraint", "xml", "inference", "infer-typecheck"]

def diff_junk_lines(str):
    return not (str.startswith("Total running time: ") or str.startswith("Generation: ")
            or str.startswith("Solving: ") or str.startswith("Output: "))

def get_immediate_subdirectories(dir):
        return [name for name in os.listdir(dir)
            if os.path.isdir(os.path.join(dir, name))]

def get_all_java_file_paths(directory):
    javaFiles = [os.path.join(directory, name) for name in os.listdir(directory)
            if not os.path.isdir(os.path.join(directory, name)) and name.endswith(".java")]
    return javaFiles

def get_all_java_files(dir):
    javaFiles = [os.path.join(dir, name) for name in os.listdir(dir)
            if  not os.path.isdir(os.path.join(dir, name)) and name.endswith(".java")]
    cwd = os.getcwd() + "/"
    #print("Here")
    #print str(javaFiles)
    javaFilesString = ""
    for java in javaFiles:
        javaFilesString = javaFilesString + java + " "
    javaFilesString = javaFilesString[:(len(javaFilesString)- 1)]
    javaFilesString = "\"" + javaFilesString + "\""
    return javaFilesString

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

def checker_to_args(checkerName):
    chArgs = checkerArgs[checkerName]
    soArgs = solverArgs[checkerName]
    executable = "../../dist/scripts/inference.sh" #os.path(parent, "..", "dist", "inference.sh")
    return [executable, "checkers.inference.TTIRun", "--checker", chArgs[0],
            "--visitor", chArgs[1], "--solver", soArgs[0], "--transfer", chArgs[2],
            "--analysis", chArgs[3]]

def inference_to_args(checkerName):
    chArgs = checkerArgs[checkerName]
    soArgs = 'checkers.inference.floodsolver.FloodSolver'
    executable = "../../dist/scripts/inference.sh"
    return [executable, "checkers.inference.TTIRun", "--checker", chArgs[0],
            "--visitor", chArgs[1], "--solver", soArgs, "--transfer", chArgs[2],
            "--analysis", chArgs[3]]

def typecheck_to_args(checkerName):
    executable = "../../dist/scripts/typecheck.sh"
    chArgs = checkerArgs[checkerName]
    return [executable, '-processor', chArgs[0]]

def afu_args(jaif, source_file):
    return ['insert-annotations-to-source', jaif, source_file, '-d', '.']

EXPECTED_DIR = "gold_files"
def get_expected_name(checker, test, java_file, expected_dir=EXPECTED_DIR):
    return os.path.join('../', expected_dir, get_test_name(checker, test, java_file) + '.gold')

EXAMPLES_DIR = "/examples/"
def get_test_name(checker, test, java_file):
    return '%s-%s-%s' % (checker, test, java_file.partition(EXAMPLES_DIR)[2].replace("/", "_"))

def handle_result(ret, checker, testname, generate, new_failure):
    if generate:
        print "Generate Error: Test %s-%s exited with return code %d. Recording test as failing." % (testname, checker, ret)
    elif new_failure:
        print "Error: Test %s-%s was previously erroring and is still erroring. Return code: %d" % (testname, checker, ret)
    else:
        print "ERROR: Test %s-%s was previously succeeding and is now erroring. Return code: %d" % (testname, checker, ret)

def run_xml_tests(checker, java_files, outfile_path, generate):
    ran = False
    error = False
    failure = False

    expectedName = get_expected_name(checker, 'xml', java_files)

    # Check that an expected file for this checker/test combination exists
    if not os.path.isfile(expectedName) and not generate:
        print ("Couldn't find expected file: %s testsuite xml not run for checker %s." %
                (expectedName, checker))
    else:
        ran = True
        cwd = os.getcwd()
        actualName = os.path.join(cwd, get_test_name(checker, 'xml', java_files) + '.xml')
        diffName = os.path.join(cwd, get_test_name(checker, 'xml', java_files) + '.diff')
        # Run the test
        with open(outfile_path, "a") as outfile:
            args = checker_to_args(checker) + [java_files]
            ret = subprocess.call(args, stdout=outfile, stderr=outfile)
            if ret != 0: # Error
                error = True
                if generate:
                    print "Error: Test xml for %s exited with return code %d. Creating empty gold file." %\
                            (checker, ret)
                elif os.path.getsize(expectedName) == 0:
                    print "Error: Previously erroring test still erroring. xml for " + checker + " returned error code " + str(ret)
                else:
                    print "ERROR: Test erroring that was not erroring before. xml for " + checker + " returned error code " + str(ret)
            else:
                subprocess.call(["rm", "inference.jaif"]) # cleanup
                subprocess.call(["mv", "World.xml", actualName]) # organize

                # Remove layout information
                if not generate and os.path.getsize(expectedName) > 0:
                    remove_layout(expectedName)
                if os.path.isfile(actualName):
                    remove_layout(actualName)

        if generate:
            if ret != 0:
                open(expectedName, 'a').close()
            else:
                subprocess.call(["mv", actualName, expectedName])
        else:
            failure = check_output(expectedName, actualName, diffName, ret)

    return (ran, error, failure)

def run_infer_typcheck_tests(checker, java_file, outfile_path, generate):

    suite_name = "infer-typecheck"
    ran = True
    error = False
    failure = False

    cwd = os.getcwd()
    expectedName = get_expected_name(checker, suite_name, java_file, 'inference_gold_files')
    actualName = os.path.join(cwd, get_test_name(checker, suite_name, java_file))
    diffName = os.path.join(cwd, get_test_name(checker, suite_name, java_file) + '.diff')
    javaname = os.path.basename(java_file)

    # Run the test
    with open(outfile_path, "a") as outfile:
        # Run inference
        args = inference_to_args(checker) + [java_file]
        ret = subprocess.call(args, stdout=outfile, stderr=outfile)
        if ret != 0: # Error
            error = True
            handle_result(ret, checker, suite_name, generate, not os.path.isfile(expectedName))
        else:
            # Run AFU
            # Must use abspath otherwise afu utilities might put this somewhere weird
            args = afu_args('inference.jaif', os.path.abspath(java_file))
            ret = subprocess.call(args, stdout=outfile, stderr=outfile)
            if ret != 0: #Error
                error = True
                handle_result(ret, checker, "afu", generate, not os.path.isfile(expectedName))
            else:
                # Run typecheck
                os.remove('inference.jaif')
                args = typecheck_to_args(checker) + [javaname]
                ret = subprocess.call(args, stdout=outfile, stderr=outfile)
                if ret != 0: #Error
                    error = True
                    handle_result(ret, checker, "typecheck", generate, not os.path.isfile(expectedName))

                classfile = javaname.replace('.java', '.class')
                if os.path.isfile(classfile):
                    os.remove(classfile)

    if ret == 0 and generate:
        open(expectedName, 'a').close()
        os.remove(javaname)

    return (ran, error, failure)

def run_constraint_tests(checker, java_files, outfile_path, generate):
    ran = False
    error = False
    failure = False

    expectedName = get_expected_name(checker, 'constraint', java_files)

    # Check that an expected file for this checker/test combination exists
    if not os.path.isfile(expectedName) and not generate:
        print ("Couldn't find expected file: %s testsuite constraint not run for checker %s." %
                (expectedName, checker))
    else:
        ran = True
        cwd = os.getcwd()
        actualName = os.path.join(cwd, get_test_name(checker, 'constraint', java_files) + '.txt')
        diffName = os.path.join(cwd, get_test_name(checker, 'constraint', java_files) + '.diff')
        os.putenv("ACTUAL_PATH", actualName)
        # Run the test
        with open(outfile_path, "a") as outfile:
            ret = subprocess.call(["gradle", "-p", "../../", "--daemon", "infer", "-P", "infChecker="+checker+"Test",
                    "-P", "infArgs=" + java_files.replace('../','', 1)], stdout=outfile, stderr=outfile)

            if ret != 0: # Error
                error = True
                if os.path.getsize(expectedName) == 0:
                    print "Error: Previously erroring test still erroring. constraint for " + checker + " returned error code " + str(ret)
                else:
                    print "ERROR: Test erroring that was not erroring before. constraint for " + checker + " returned error code " + str(ret)
            else:
                subprocess.call(["rm", "../../Generation/World.xml", "../../Generation/inference.jaif"]) # cleanup

        if generate:
            if ret != 0:
                open(expectedName, 'a').close()
            else:
                subprocess.call(["mv", actualName, expectedName])
        else:
            failure = check_output(expectedName, actualName, diffName, ret)

    return (ran, error, failure)

def check_output(expectedName, actualName, diffName, ret):
    # Compare the results
    if os.path.isfile(expectedName) and os.path.isfile(actualName) and not ret:
        same = compare_results(expectedName, actualName, diffName)
        if (not same) :
            return True
        else:
            if os.path.isfile(diffName):
                subprocess.call(["rm", diffName])
            if os.path.isfile(actualName):
                subprocess.call(["rm", actualName])
            else:
                print ("STRANGE: exit code zero but no actualFile output for test " +
                        test + " using checker " + checker)
    return False

def main():
    p = optparse.OptionParser()
    p.add_option('--checker', '-c', default="all", help="The type system to use: nninf, trusted, or all. Default is all")
    p.add_option('--test-suite', '-s', default="all", help="The test suite to run: constraint, xml, or all. Default is all")
    p.add_option('--debug', '-d',  action="store_true", dest="debug", help="Remote debug using port 5005.")
    p.add_option('--outfile', '-o', default=os.devnull, help="File to append output from tests.")
    p.add_option('--update-gold', '-u', default=False, action="store_true", help="Update the gold files.")
    p.add_option('--test', '-t', default=None, help="Individual test to run and check. (Regex filter)")
    options, arguments = p.parse_args()

    checkers = allCheckers if options.checker == "all" else [options.checker]
    testsuites = allTests if options.test_suite == "all" else [options.test_suite]
    if checkers[0] not in allCheckers:
        print "Unknown checker."
        return
    if testsuites[0] not in allTests:
        print "Unknown test suite."
        return
    test_pattern = re.compile(options.test) if options.test else None

    print "Type systems: " + str(checkers)
    print "Test suites: " + str(testsuites)
    print

    if options.debug:
        os.putenv("DEBUG", "true")

# TODO: scriptName is never used. Do we need these scripts?
#    if options.debug:
#        scriptName = "./debugScript.sh"
#    else:
#        scriptName = "./testScript.sh"

    os.putenv("JAVA", os.getenv("JAVA_HOME") + "/bin/java")
    os.putenv("SCALA", os.getenv("SCALA_HOME") + "/bin/scala")\

    if not os.path.exists('test_tmp'):
        os.mkdir('test_tmp')

    os.chdir('test_tmp')
    cwd = os.getcwd()
    print ("Current directory: " + cwd)

    failingTests = []
    numTests = 0
    numFails = 0
    numErrors = 0
    test_dir = '../../Generation/examples/'

    for testsuite in testsuites:
        print "---Running " + testsuite + " tests---"
        dirs = [test_dir] + [os.path.join(test_dir, subdir) for subdir in get_immediate_subdirectories(test_dir)]
        for directory in dirs:
            java_files = get_all_java_file_paths(directory)

            for java_file in java_files:
                # If given a test regex, match
                if test_pattern and not test_pattern.search(java_file):
                    continue

                print java_file
                for checker in checkers:
                    if testsuite == "xml" :
                        (ran, error, failure) = run_xml_tests(checker, java_file, options.outfile, options.update_gold)
                    elif testsuite == "constraint":
                        (ran, error, failure) = run_constraint_tests(checker, java_file, options.outfile, options.update_gold)
                    elif testsuite == "inference":
                        (ran, error, failure) = run_inference_tests(checker, java_file, options.outfile, options.update_gold)
                    elif testsuite == "infer-typecheck":
                        (ran, error, failure) = run_infer_typcheck_tests(checker, java_file, options.outfile, options.update_gold)

                    if ran:
                        numTests += 1
                        if error:
                            numErrors += 1
                        elif failure:
                            numFails += 1
                            failingTests = failingTests + [testsuite + ", " + checker + ", " + java_file]
                            print "Failure"
                        else:
                            print "Success"

        if failingTests:
            print
            print "Failing tests:"
            for fail in failingTests :
                print fail
            print
        failingTests = []

    print "Tests run: %d, Passed: %d, Errors: %d, Failures (Goal file mismatch): %d" % (numTests,
            (numTests - numErrors - numFails), numErrors, numFails)

if __name__ == '__main__':
    main()
