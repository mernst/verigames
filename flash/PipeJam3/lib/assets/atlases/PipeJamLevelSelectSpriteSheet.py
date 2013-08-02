from atlasXMLGen import *

emitHeader('PipeJamLevelSelectSpriteSheet.png')

emitComment('Window')
emitNineSlice('LevelSelectWindow',                0,    0,  824,  584,   64,   64)

emitComment('Tabs')
emitNineSlice('TabActive',                      526,  600,  244,   54,   64,   24,   64,   10)
emitNineSlice('TabInactive',                    526,  656,  244,   44,   64,   24,   64,    5)
emitNineSlice('TabInactiveMouseover',           526,  702,  244,   44,   64,   24,   64,    5)
emitNineSlice('TabInactiveClick',               526,  748,  244,   44,   64,   24,   64,    5)

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
emitRegion('ScrollbarArrowUp',                  718,  802,   19,   10)
emitRegion('ScrollbarArrowDown',                741,  801,   19,   10)
emitRegion('ScrollbarButton',                   719,  814,   10,   10)
emitRegion('ScrollbarButtonMouseover',          719,  826,   10,   10)
emitRegion('ScrollbarButtonClick',              719,  838,   10,   10)
emitRegion('Scrollbar',                         722,  851,    4,    4)

emitFooter()
