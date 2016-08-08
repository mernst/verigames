import os

execfile('../../util.py')

all_files = os.listdir(os.path.dirname(os.path.realpath(__file__)))

files = []
for file in all_files:
    name, ext = os.path.splitext(file)

    if ext == '.json' and not name.endswith('Assignments') and not name.endswith('Layout'):
        files.append(name)

combine_levels_all('../gameplay', files)
