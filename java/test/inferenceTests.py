#!/usr/bin/env python

from os.path import join
import argparse
import os.path
import re
import subprocess

MODES=['typecheck', 'roundtrip', 'xmlsolve', 'xml-roundtrip']

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', default='typecheck', help='Inference test modes: [%s' % ', '.join(MODES))
    parser.add_argument('-t', '--test', help='Regex to match test names on.')
    parser.add_argument('-d', '--debug', action='store_true', help='Print out all command output')
    parser.add_argument('--checker', default='encrypted.EncryptedChecker', help='Type system to run')
    args = parser.parse_args()

    execute_tests(args.checker, args.test, args.mode, args.debug)

def execute_tests(checker, test_name, mode, debug):
    pattern = re.compile(test_name) if test_name else None
    print 'build_search_dirs', build_search_dirs()
    test_files = [join(test_dir, test_file)
            for test_dir in build_search_dirs()
                for test_file in os.listdir(test_dir)
                    if os.path.isfile(join(test_dir, test_file))
                    and test_file.endswith('.java')
                    and (pattern is None or pattern.search(test_file))]

    successes = []
    failures = []
    for test_file in test_files:
        print 'Executing test ' + test_file
        cmd = get_verigames_cmd(checker, test_file, mode)
        success = execute_command(cmd, debug)
        if success:
            print 'Success'
            successes.append(test_file)
        else:
            print 'Failure'
            failures.append(test_file)

    print_summary(successes, failures)

def print_summary(successes, failures):
    print '%d Passed, %d failed' % (len(successes), len(failures))
    print 'Failed tests:'
    for failed in failures:
        print failed

def get_verigames_cmd(checker, file_name, mode):
    return '%s --mode %s --checker %s %s' % \
            (get_verigames_exe(), mode, checker, file_name)

def build_search_dirs():
    dirs = []
    dirs.append(join(os.environ['CHECKERS'], 'tests', 'all-systems'))
    dirs.append(join(get_this_scripts_dir(), 'inference_test_files', 'encrypted'))
    dirs.append(join(os.environ['VERIGAMES'], 'java', 'Generation', 'examples'))
    dirs.append(join(os.environ['VERIGAMES'], 'java', 'Generation', 'examples', 'refmerge'))
    dirs.append(join(os.environ['VERIGAMES'], 'java', 'Generation', 'examples', 'generics'))
    return dirs

def get_this_scripts_dir():
    return os.path.dirname(os.path.abspath(__file__))

def get_verigames_exe():
    return os.path.abspath(join(get_this_scripts_dir(), '../dist/scripts/verigames.py'))

def execute_command(args, debug):
    if debug:
        ret = subprocess.call(args, shell=True)
    else:
        with open(os.devnull) as out:
            ret = subprocess.call(args, shell=True, stdout=out, stderr=out)
    return ret == 0

if __name__=='__main__':
   main()
