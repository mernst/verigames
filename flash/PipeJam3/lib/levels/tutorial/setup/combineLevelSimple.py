import sys

FILES = [
    'IntroWidget',
    'WidgetPractice',
    'LockedWidget',
    'SatisfyBoxes',
    'Passages',
    'Clashes',
    'WidenBoxes',
    'NarrowBoxes',
    'Optimize',
    'Splits',
    'Merges',
	'SplitMergePractice',
    'ZoomPan',
    'Layout',
    'GroupSelect',
	'CreateJoint',
    'SkillsA',
    'SkillsB',
#    'End',
]

def combineLevels(files, graphHeader):
    lines = []
    
    if graphHeader:
        lines += '<?xml version="1.0" encoding="UTF-8"?>\n'
        lines += '<graph id="world">\n'
    else:
        lines += '<?xml version="1.0" encoding="UTF-8"?>\n'
        lines += '<!DOCTYPE world SYSTEM "world.dtd">\n'
        lines += '<world version="1">\n'

    for file in files:
        inlevel = False

        for line in open(file):
            if '<level' in line:
                inlevel = True

            linestr = line.rstrip()
            if inlevel and len(linestr) != 0:
                lines += linestr + '\n'

            if '</level' in line:
                inlevel = False

    if graphHeader:
        lines += '</graph>\n'
    else:
        lines += '</world>\n'

    return lines


open('../tutorial.xml', 'w').writelines(combineLevels([fn + '.xml' for fn in FILES], False))
open('../tutorialConstraints.xml', 'w').writelines(combineLevels([fn + 'Constraints.xml' for fn in FILES], True))
open('../tutorialLayout.xml', 'w').writelines(combineLevels([fn + 'Layout.xml' for fn in FILES], True))
