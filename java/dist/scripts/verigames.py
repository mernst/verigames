#!/usr/bin/env python

import subprocess
import argparse
import sys
import os.path

# Required env vars
VERIGAMES_HOME = os.environ['VERIGAMES']
SCALA_HOME = os.environ['SCALA_HOME']
JAVA_HOME = os.environ['JAVA_HOME']

# Program constants
MODES = 'game typecheck autosolve'.split()
AUTOMATIC_SOLVER = 'checkers.inference.floodsolver.FloodSolver'
DEBUG_OPTS = '-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005'

class Checker():
    def __init__(self, name, visitor=None, transfer=None, analysis=None, solver=None):
        self.name = name
        self.visitor = visitor
        self.transfer = transfer
        self.analysis = analysis
        self.solver = solver

    def update_if_set(self, visitor=None, transfer=None, analysis=None, solver=None):
        if visitor:
            self.visitor = visitor
        if transfer:
            self.transfer = transfer
        if analysis:
            self.analysis = analysis
        if solver:
            solf.solver = solver

    def to_checker_args(self):
        args = 'checkers.inference.TTIRun --checker %s --visitor %s' % (self.name, self.visitor)
        if self.transfer:
            args += ' --transfer ' + self.transfer
        if self.analysis:
            args += ' --analysis ' + self.analysis
        if self.solver:
            args += ' --solver ' + self.solver

        return args


# Note that TTI run has its own defaults for transfer (InferenceTransefer)
# and analysis (InferenceAnalysis) so they don't need to be speicified here.
nninf_checker = Checker('nninf.NninfChecker', 'nninf.NninfVisitor',
    'nninf.NninfTransferImpl', solver='nninf.NninfGameSolver')
trusted_checker = Checker('trusted.TrustedChecker', 'trusted.TrustedVisitor',
    solver='trusted.TrustedGameSolver')

checkers={nninf_checker.name: nninf_checker,
        trusted_checker.name: trusted_checker}

def error(msg):
    print >> sys.stderr, msg
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser('Execute verigames on the command line.')
    parser.add_argument('--mode', default='game', help='Choose a verigames mode from [%s].' % ', '.join(MODES))
    parser.add_argument('files', metavar='PATH', nargs='+', help='Source files to run verigames on')
    parser.add_argument('--debug', action='store_true', help='Listen for java debugger.')
    parser.add_argument('--not-strict', action='store_true', help='Disable some checks on generation.')
    parser.add_argument('--print', action='store_true', help='Print debugging constraint output.')
    parser.add_argument('--checker', help='Typesystem Checker.')
    parser.add_argument('--transfer', help='Transfer function. Typesystem dependent.')
    parser.add_argument('--analysis', help='Dataflow analysis. Typesystem dependent.')
    parser.add_argument('--visitor', help='Inference Visitor. Typesystem dependent.')
    parser.add_argument('--solver', help='Inference Solver. Typesystem dependent.')
    parser.add_argument('--java-args', help='Additional java args to pass in.')
    parser.add_argument('--prog-args', help='Additional args to pass in to program eg -AprintErrorStack.')
    parser.add_argument('--extra-classpath', help='Additional classpath entries.')
    #parser.add_argument('--outfile', default=os.devnull, help='Capture stdout and stderr to separate fil.e')
    parser.add_argument('--xmx', default='2048m', help='Java max heap size.')
    parser.add_argument('-p', '--print-only', action='store_true', help='Print command to execute (but do not run).')
    args = parser.parse_args()

    if args.mode not in MODES:
        error('Mode: %s not in allowed modes: %s' % (args.mode, MODES))


    if args.mode == 'typecheck' and \
            (args.transfer or args.analysis or args.visitor or args.solver):
        error('Transfer, analysis, solver and visitor cannot be set on the command line.'
                + ' They are inference by the checker framework based on checker name.')

    classpath = get_verigames_classpath()
    classpath += ':' + get_scala_classpath()

    if args.extra_classpath:
        classpath += ":" + args.extra_classpath

    if checkers[args.checker]:
        checker = checkers[args.checker]
        checker.update_if_set(args.visitor, args.transfer, args.analysis, args.solver)
    else:
        checker = Checker(args.checker, args.visitor, args.transfer, args.analysis, args.solver)

    if args.mode in ['game', 'autosolve']:
        if args.mode == 'autosolve':
            checker.solver = AUTOMATIC_SOLVER
        command = generate_checker_cmd(checker, args.java_args, classpath,
                args.debug, args.not_strict, args.xmx, args.files)
        execute(command)
    elif args.mode == 'typecheck':
        command = generate_typecheck_cmd(checker, args.java_args, classpath,
                args.debug, args.not_strict, args.xmx, args.prog_args, args.files)
        execute(command)

def generate_checker_cmd(checker, java_args, classpath, debug, not_strict, xmx, files):
    java_path = os.path.join(JAVA_HOME, 'bin', 'java')
    java_args = java_args if java_args else ""
    java_opts = "%s -Dscala.usejavacp=true -Xms512m -Xmx%s -Xbootclasspath/p:%s -ea " % \
        (java_args, xmx, classpath)
    if debug:
        java_opts += " " + DEBUG_OPTS
    if not_strict:
        java_opts += " -DSTRICT=false "
    args = ' '.join([java_path, java_opts, checker.to_checker_args(), ' '.join(files)])
    return args

def generate_typecheck_cmd(checker, java_args, classpath, debug, not_strict, 
            xmx, prog_args, files):

    java_path = os.path.join(JAVA_HOME, 'bin', 'java')
    java_args = java_args if java_args else ""
    java_opts = "%s -Xms512m -Xmx%s -jar %s -cp %s " % \
        (java_args, xmx, get_checker_jar(), classpath)
    if debug:
        java_opts += " -J" + DEBUG_OPTS
    if not_strict:
        java_opts += " -DSTRICT=false "
    args = ' '.join([java_path, java_opts, '-processor ', checker.name, prog_args, ' '.join(files)])
    return args

def execute(args):
    print('Executing command: ' + args)
    print
    ret = subprocess.call(args, shell=True)

def get_checker_jar():
    return os.path.join(VERIGAMES_HOME, 'java', 'dist', 'checkers.jar')

def get_verigames_classpath():
    base_dir = os.path.join(VERIGAMES_HOME, 'java', 'dist')
    return get_classpath(base_dir)

def get_scala_classpath():
    scala_dir = os.path.join(SCALA_HOME, 'lib')
    cp = os.path.join(scala_dir, 'scala-compiler.jar') + ':' +\
            os.path.join(scala_dir, 'scala-library.jar')
    return cp

def get_classpath(base_dir):
    if not os.path.isdir(base_dir):
        error('Verigames dist directory not found: %s' % base_dir)
    jars = [os.path.join(base_dir, f) for f in os.listdir(base_dir)
                if os.path.isfile(os.path.join(base_dir, f))
                and f.endswith('.jar')]
    jars.reverse()
    return ':'.join(jars)

def error(msg):
    print >> sys.stderr, msg
    sys.exit(1)

if __name__=='__main__':
    main()
