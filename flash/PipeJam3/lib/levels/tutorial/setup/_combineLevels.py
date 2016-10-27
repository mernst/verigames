import sys
sys.path.append('../../../../../level_creation_scripts/')
import _util

FILES = [
	'001',
	'002',
	'01',
	'004',
	'02',
	'005',
	'03',
	'04',
#	'1',
	'2',
#	'3',
#	'4',
#	'5',
#	'6',
#	'7',
#	'8',
#	'10',
#	'12',
#	'13',
#	'14',
]

_util.combine_levels_all('../tutorial', FILES)
