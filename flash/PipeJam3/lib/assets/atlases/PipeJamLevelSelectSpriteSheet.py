from atlasXMLGen import *

emitHeader('PipeJamLevelSelectSpriteSheet.png')

emitComment('Window')
emitNineSlice('LevelSelectWindow',                0,    0,  824,  584,   64,   64)

emitComment('Tabs')
emitNineSlice('TabActive',                      826,    0,  244,   54,   64,   24,   64,   10)
emitNineSlice('TabInactive',                    826,   56,  244,   44,   64,   24,   64,    5)
emitNineSlice('TabInactiveMouseover',           826,  102,  244,   44,   64,   24,   64,    5)
emitNineSlice('TabInactiveClick',               826,  148,  244,   44,   64,   24,   64,    5)

emitComment('Document Icon')
emitNineSlice('DocumentIconLocked',               0,  610,  124,  124,   16,   16)
emitNineSlice('DocumentIcon',                   130,  610,  124,  124,   16,   16)
emitNineSlice('DocumentIconMouseover',          260,  610,  124,  124,   16,   16)
emitNineSlice('DocumentIconClick',              390,  610,  124,  124,   16,   16)

emitComment('Document Background')
emitNineSlice('DocumentBackgroundLocked',         0,  740,  124,  124,   16,   16)
emitNineSlice('DocumentBackground',             130,  740,  124,  124,   16,   16)
emitNineSlice('DocumentBackgroundMouseover',    260,  740,  124,  124,   16,   16)
emitNineSlice('DocumentBackgroundClick',        390,  740,  124,  124,   16,   16)

emitComment('Scrollbar')
emitRegion('ScrollbarArrowUp',                 1018,  202,   19,   10)
emitRegion('ScrollbarArrowDown',               1041,  201,   19,   10)
emitRegion('ScrollbarButton',                  1019,  214,   10,   10)
emitRegion('ScrollbarButtonMouseover',         1019,  226,   10,   10)
emitRegion('ScrollbarButtonClick',             1019,  238,   10,   10)
emitRegion('Scrollbar',                        1022,  251,    4,    4)

emitFooter()
