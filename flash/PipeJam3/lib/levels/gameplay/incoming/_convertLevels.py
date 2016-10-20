import os, shutil

SCRIPTS_DIR = '../../../../../../level_creation_scripts/'

def python_script(cmd):
    ret = os.system('python ' + SCRIPTS_DIR + cmd)
    if ret != 0:
        raise RuntimeError('Error from Python call: ' + cmd)

for file in os.listdir('.'):
    if not file.endswith('.cnf'):
        continue

    pref = file[:-4]

    shutil.rmtree('tmp', True)
    os.mkdir('tmp')
    os.chdir('tmp')
    
    python_script('normalize_dimacs.py < ../%s.cnf > %s.cnf' % (pref, pref))
    python_script('makeConstraintFromDIMACS.py %s.cnf %s' % (pref, pref))
    python_script('cnstr/process_constraint_json.py %s' % (pref))

    outfolder = '%s_game_files/' % (pref)
    for outfile in os.listdir(outfolder):
        shutil.move(outfolder + outfile, '../../setup/' + outfile)

    os.chdir('..')
    shutil.rmtree('tmp')
