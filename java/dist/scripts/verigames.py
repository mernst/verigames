#!/usr/bin/env python

import subprocess
import argparse
import sys
import os.path
import shutil

VERIGAMES_HOME = os.environ['VERIGAMES']
SCALA_HOME = os.environ['SCALA_HOME']
JAVA_HOME = os.environ['JAVA_HOME']
VERIGAMES_ASP_HOME = os.environ.get('VERIGAMES_ASP_HOME')
AFU_HOME = os.environ.get('AFU_HOME')

# Program constants
MODES = 'game typecheck floodsolve flood-roundtrip xmlsolve xml-roundtrip'.split()
AUTOMATIC_SOLVER = 'checkers.inference.floodsolver.FloodSolver'
DEBUG_OPTS = '-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005'
OUTPUT_DIR = './output'

class Checker():
    def __init__(self, name, visitor=None, transfer=None, analysis=None, solver=None, subanno=None, superanno=None):
        self.name = name
        self.visitor = visitor
        self.transfer = transfer
        self.analysis = analysis
        self.solver = solver
        self.subanno = subanno
        self.superanno = superanno

    def update_if_set(self, visitor=None, transfer=None, analysis=None, solver=None):
        if visitor:
            self.visitor = visitor
        if transfer:
            self.transfer = transfer
        if analysis:
            self.analysis = analysis
        if solver:
            self.solver = solver

    def to_checker_args(self):
        args = 'checkers.inference.TTIRun --checker ' + self.name
        if self.visitor:
            args += ' --visitor ' + self.visitor
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
encrypted_checker = Checker('encrypted.EncryptedChecker', 'trusted.TrustedVisitor',
    solver='trusted.TrustedGameSolver', subanno='@encrypted.quals.Encrypted', superanno='@encrypted.quals.Plaintext')
ostrusted_checker = Checker('ostrusted.OsTrustedChecker', 'trusted.TrustedVisitor',
    solver='trusted.TrustedGameSolver', subanno='@ostrusted.quals.OsTrusted', superanno='@ostrusted.quals.OsUntrusted')
nonnegative_checker = Checker('nonnegative.NonNegativeChecker', 'nonnegative.NonNegativeVisitor',
    solver='trusted.TrustedGameSolver', subanno='@nonnegative.quals.NonNegative', superanno='@nonnegative.quals.UnknownSign')

checkers={nninf_checker.name: nninf_checker,
        trusted_checker.name: trusted_checker,
        encrypted_checker.name: encrypted_checker,
        ostrusted_checker.name: ostrusted_checker,
        nonnegative_checker.name: nonnegative_checker,
        }

def error(msg):
    print >> sys.stderr, msg
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser('Execute verigames on the command line.')
    parser.add_argument('--analysis', help='Dataflow analysis. Typesystem dependent.')
    parser.add_argument('--stubs', help='Stub files to use.')
    parser.add_argument('--checker', help='Typesystem Checker.')
    parser.add_argument('--debug', action='store_true', help='Listen for java debugger.')
    parser.add_argument('--extra-classpath', help='Additional classpath entries.')
    parser.add_argument('--java-args', help='Additional java args to pass in.')
    parser.add_argument('--mode', default='game', help='Choose a verigames mode from [%s].' % ', '.join(MODES))
    parser.add_argument('--steps', default='', help='Manually list steps to run.')
    parser.add_argument('--not-strict', action='store_true', help='Disable some checks on generation.')
    parser.add_argument('--output_dir', default=OUTPUT_DIR, help='Directory to output artifacts during roundtrip (inference.jaif, annotated file sourc file')
    parser.add_argument('--print-world', action='store_true', help='Print debugging constraint output.')
    parser.add_argument('--prog-args', help='Additional args to pass in to program eg -AprintErrorStack.')
    parser.add_argument('--solver', help='Inference Solver. Typesystem dependent.')
    parser.add_argument('--transfer', help='Transfer function. Typesystem dependent.')
    parser.add_argument('--visitor', help='Inference Visitor. Typesystem dependent.')
    parser.add_argument('--xmx', default='2048m', help='Java max heap size.')
    parser.add_argument('-p', '--print-only', action='store_true', help='Print command to execute (but do not run).')
    parser.add_argument('files', metavar='PATH', nargs='+', help='Source files to run verigames on')
    args = parser.parse_args()

    if args.mode not in MODES:
        error('Mode: %s not in allowed modes: %s' % (args.mode, MODES))

    if args.mode == 'typecheck' and \
            (args.transfer or args.analysis or args.visitor or args.solver):
        error('Transfer, analysis, solver and visitor cannot be set on the command line.'
                + ' They are inference by the checker framework based on checker name.')

    # Modes are shortcuts for pipeline steps
    # Only support one order at the moment
    # MODES = 'game typecheck floodsolve flood-roundtrip xmlsolve xml-roundtrip'.split()
    pipeline = []
    if args.steps:
        pipeline = args.steps.split(',')
    else:
        if args.mode == 'typecheck':
            pipeline = ['typecheck']
        elif args.mode == 'game':
            pipeline = ['generate', 'xml-validate']
        elif args.mode == 'floodsolve':
            pipeline = ['floodsolve']
        elif args.mode == 'flood-roundtrip':
            pipeline = ['floodsolve', 'insert-jaif', 'typecheck']
        elif args.mode == 'xmlsolve':
            pipeline = ['generate', 'xmlsolve']
        elif args.mode == 'xml-roundtrip':
            pipeline = ['generate', 'xmlsolve', 'update-jaif', 'insert-jaif', 'typecheck']

    # Setup some globaly useful stuff
    classpath = get_verigames_classpath()
    classpath += ':' + get_scala_classpath()

    if args.extra_classpath:
        classpath += ':' + args.extra_classpath

    if checkers[args.checker]:
        checker = checkers[args.checker]
        checker.update_if_set(args.visitor, args.transfer, args.analysis, args.solver)
    else:
        checker = Checker(args.checker, args.visitor, args.transfer, args.analysis, args.solver)

    # State variable need to communicate between steps
    state = {'files' : args.files}

    # Execute steps
    while len(pipeline):
        step = pipeline.pop(0)
        print '\n====Executing step ' + step
        if step == 'generate':
            execute(args, generate_checker_cmd(checker, args.java_args, classpath,
                    args.debug, args.not_strict, args.xmx, args.print_world, args.prog_args, args.stubs, args.files))
        elif step == 'xml-validate':
            execute(args,generate_xml_validator_cmd(os.path.abspath('World.xml'), classpath))
            print 'Xml validation successful'
        elif step == 'typecheck':
            execute(args, generate_typecheck_cmd(checker, args.java_args, classpath,
                    args.debug, args.not_strict, args.xmx, args.prog_args, args.stubs, state['files']))
        elif step == 'floodsolve':
            checker.solver = AUTOMATIC_SOLVER
            execute(args, generate_checker_cmd(checker, args.java_args, classpath,
                    args.debug, args.not_strict, args.xmx, args.print_world, args.prog_args, args.stubs, args.files))

            # Save jaif file
            if not args.print_only:
                if not os.path.exists(args.output_dir) and not args.print_only:
                    os.mkdir(args.output_dir)
                shutil.copyfile('inference.jaif', pjoin(args.output_dir, 'inference.jaif'))

            state['files'] = [pjoin(args.output_dir, os.path.basename(f)) for f in args.files]
        elif step == 'insert-jaif':
            # inference.jaif needs to be in output dir
            execute(args, generate_afu_command(args.files, args.output_dir))
        elif step == 'xmlsolve':
            world_xml_path = os.path.abspath('World.xml')
            world_xml_solution = world_xml_path + '.out'
            oldcwd = os.getcwd()
            os.chdir(VERIGAMES_ASP_HOME)
            execute(args, generate_asp_command(world_xml_path))
            os.chdir(oldcwd)
            command = generate_buzzsaw_check(world_xml_solution)
            ret = execute(args, command, check_return=False)
            # Grep exits 0 when nothing is found.
            if not args.print_only and not ret:
                print('Found buzzsaw in xml output.')
                sys.exit(1)
            else:
                print('No Buzzsaw found. Xml solved correctly.')

        elif step == 'update-jaif':
            execute(args,generate_jaif_cmd(checker, args.java_args, classpath, args.debug,
                    world_xml_solution, 'inference.jaif', 'updatedInference.jaif'))
            if not args.print_only:
                if not os.path.exists(args.output_dir):
                    os.mkdir(args.output_dir)
                os.rename('updatedInference.jaif', pjoin(args.output_dir, 'inference.jaif'))
        else:
            print 'UNKNOWN STEP'

def generate_asp_command(world_file):
    args = '%s/processworld %s' % (VERIGAMES_ASP_HOME, world_file)
    return args

def generate_buzzsaw_check(world_file):
    args = 'grep \'buzzsaw="true"\' %s' % world_file
    return args

def generate_afu_command(files, outdir):
    files = [os.path.abspath(f) for f in files]
    insert_path = 'insert-annotations-to-source' if not AFU_HOME \
            else pjoin(AFU_HOME, 'annotation-file-utilities/scripts/insert-annotations-to-source')
    args = '%s -v -d %s %s %s ' % (insert_path, outdir, pjoin(outdir, 'inference.jaif'), ' '.join(files))
    return args

def generate_xml_validator_cmd(world_file, classpath):
    xmlcp = pjoin(VERIGAMES_HOME, 'java/Translation/lib/xom-1.2.10.jar')
    java_path = pjoin(JAVA_HOME, 'bin/java')
    full_cp = classpath + ':' + xmlcp
    args = ' '.join([java_path, '-cp', classpath, 'verigames.level.XMLValidator', '<', world_file])
    return args

def generate_checker_cmd(checker, java_args, classpath, debug, not_strict, xmx, print_world, prog_args, stubs, files):
    java_path = pjoin(JAVA_HOME, 'bin/java')
    java_args = java_args if java_args else ''
    prog_args = prog_args if prog_args else ''
    java_opts = '%s -Dscala.usejavacp=true -Xms512m -Xmx%s -Xbootclasspath/p:%s -ea ' % \
        (java_args, xmx, classpath)
    if debug:
        java_opts += ' ' + DEBUG_OPTS
    if print_world:
        java_opts += ' -DPRINT_WORLD=true '
    if not_strict:
        java_opts += ' -DSTRICT=false '
    if stubs:
        prog_args += ' --stubs ' + stubs
    args = ' '.join([java_path, java_opts, checker.to_checker_args(), prog_args, ' '.join(files)])
    return args

def generate_typecheck_cmd(checker, java_args, classpath, debug, not_strict,
            xmx, prog_args, stubs, files):

    java_path = pjoin(JAVA_HOME, 'bin/java')
    java_args = java_args if java_args else ''
    prog_args = prog_args if prog_args else ''
    java_opts = '%s -Xms512m -Xmx%s -jar %s -cp %s ' % \
        (java_args, xmx, get_checker_jar(), classpath)
    if debug:
        java_opts += ' -J' + DEBUG_OPTS
    if not_strict:
        java_opts += ' -DSTRICT=false '
    if stubs:
        prog_args += ' -Astubs=' + stubs
    args = ' '.join([java_path, java_opts, '-processor ', checker.name, prog_args, ' '.join(files)])
    return args

# xml_file, jaif_file, output_file, subtype_annotation, supertype_annotation
def generate_jaif_cmd(checker, java_args, classpath, debug, xml_file, jaif_file, output_file):
    java_path = pjoin(JAVA_HOME, 'bin/java')
    java_args = java_args if java_args else ''
    java_opts = '%s -cp %s ' % (java_args, classpath)
    if debug:
        java_opts += ' -J' + DEBUG_OPTS
    args = ' '.join([java_path, java_opts, 'verigames.utilities.JAIFParser', xml_file, jaif_file, \
            output_file, checker.subanno, checker.superanno])
    return args

def execute(cli_args, args, check_return=True):
    if cli_args.print_only:
        print('Would have executed command: \n' + args)
        print
    else:
        print('Executing command: \n' + args)
        print
        ret = subprocess.call(args, shell=True)
        if check_return and ret:
            error('Command exited with unexpected status code: %d' % ret)
        return ret

def get_checker_jar():
    return pjoin(VERIGAMES_HOME, 'java/dist/checkers.jar')

def get_verigames_classpath():
    base_dir = pjoin(VERIGAMES_HOME, 'java/dist')
    return get_classpath(base_dir)

def get_scala_classpath():
    scala_dir = os.path.join(SCALA_HOME, 'lib')
    cp = pjoin(scala_dir, 'scala-compiler.jar') + ':' +\
            pjoin(scala_dir, 'scala-library.jar')
    return cp

def pjoin(*parts):
    return os.path.join(*[os.path.join(part) for part in parts])

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
    print >> sys.stderr, 'Exiting'
    sys.exit(1)

if __name__=='__main__':
    main()
