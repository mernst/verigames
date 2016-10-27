import sys
sys.path.append('../../../../../level_creation_scripts/')
import _util

_util.combine_levels_all('../gameplay', _util.list_file_prefixes(__file__))
