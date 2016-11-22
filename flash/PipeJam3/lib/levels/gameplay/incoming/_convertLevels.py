import os, shutil, sys

NEED_SCALE = {}

SCRIPTS_DIR = '../../../../../level_creation_scripts/'

sys.path.append(SCRIPTS_DIR)
import _util

def python_script(cmd):
    print '===', cmd
    ret = os.system('python ../' + SCRIPTS_DIR + cmd)
    if ret != 0:
        raise RuntimeError('Error from Python call: ' + cmd)

for file in os.listdir('.'):
    if not file.endswith('.cnf'):
        continue

    pref = file[:-4]

    # make temp space
    shutil.rmtree('tmp', True)
    os.mkdir('tmp')
    os.chdir('tmp')

    
    # put DIMACS in normalized format
    python_script('normalizeDIMACS.py < ../%s.cnf > %s.cnf' % (pref, pref))

    # convert DIMACS to level format
    python_script('makeConstraintFromDIMACS.py %s.cnf %s' % (pref, pref))

    # do level layout, etc
    python_script('cnstr/process_constraint_json.py %s' % (pref))


    # post-process level files
    outfolder = '%s_game_files/' % (pref)

    prefs = _util.list_file_prefixes(outfolder + 'file')
    if len(prefs) > 1:
        raise RuntimeError('Level %s was split.' % (pref))

    # scale layout if needed
    if NEED_SCALE.has_key(file):
        for pref in prefs:
            python_script('scaleXY.py %s %f' % (outfolder + pref, NEED_SCALE[file]))

    # udpate QID
    for pref in prefs:
        python_script('updateQID.py %s' % (outfolder + pref))


    # move level files
    for outfile in os.listdir(outfolder):
        shutil.move(outfolder + outfile, '../../setup/' + outfile)


    # clean up
    os.chdir('..')
    shutil.rmtree('tmp')
