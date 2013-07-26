from atlasXMLGen import *

emitHeader('PipeJamSpriteSheet.png')

emitComment  ('Dark Gray')
emitNineSlice('GrayDarkBox',                         2,   30,  192,  192,   64,   64)
emitRegion   ('GrayDarkStart',                     779,  123,   38,   38)
emitRegion   ('GrayDarkEnd',                       826,  140,   27,   17)
emitRegion   ('GrayDarkPlug',                      861,  179,   30,   44)
emitRegion   ('GrayDarkJoint',                     880,    5,   16,   16)
emitRegion   ('GrayDarkSegment',                   920,    5,   16,   16)

emitComment  ('Light Gray')
emitNineSlice('GrayLightBox',                        2,  224,  192,  192,   64,   64)
emitRegion   ('GrayLightStart',                    786,   59,   24,   24)
emitRegion   ('GrayLightEnd',                      826,  102,   11,   17)
emitRegion   ('GrayLightPlug',                     912,  179,   16,   44)
emitRegion   ('GrayLightJoint',                    880,   25,   16,   16)
emitRegion   ('GrayLightSegment',                  920,   25,   16,   16)

emitComment  ('Dark Blue')
emitNineSlice('BlueDarkBox',                       196,   30,  192,  192,   64,   64)
emitRegion   ('BlueDarkStart',                     779,   84,   38,   38)
emitRegion   ('BlueDarkEnd',                       826,  159,   27,   17)
emitRegion   ('BlueDarkPlug',                      827,  179,   30,   44)
emitRegion   ('BlueDarkJoint',                     900,    5,   16,   16)
emitRegion   ('BlueDarkSegment',                   940,    5,   16,   16)

emitComment  ('Light Blue')
emitNineSlice('BlueLightBox',                      196,  224,  192,  192,   64,   64)
emitRegion   ('BlueLightStart',                    786,   34,   24,   24)
emitRegion   ('BlueLightEnd',                      826,  121,   11,   17)
emitRegion   ('BlueLightPlug',                     894,  179,   16,   44)
emitRegion   ('BlueLightJoint',                    900,   25,   16,   16)
emitRegion   ('BlueLightSegment',                  940,   25,   16,   16)

emitComment  ('Orange (Error)')
emitRegion   ('OrangeAdaptor',                     779,  162,   43,   61)
emitRegion   ('OrangeAdaptorPlug',                 931,  179,   16,   44)
emitRegion   ('OrangeScore',                       840,    2,   32,   32)

emitComment  ('Scorebar UI')
emitRegion   ('ScoreBarForeground',                  1,  419,  960,  116)
emitRegion   ('ScoreBarBlue',                      859,   44,   46,   46)
emitRegion   ('ScoreBarOrange',                    909,   44,   46,   46)

emitComment  ('Menu Boxes')
emitNineSlice('MenuBoxFree',                       390,   30,  192,  192,   64,   64)
emitNineSlice('MenuBoxAttached',                   390,  224,  192,  192,   64,   64)

emitComment  ('Menu Scrollbars')
emitRegion   ('MenuBoxScrollbar',                  830,   95,    4,    4)
emitRegion   ('MenuBoxScrollbarButton',            827,   61,   10,   10)
emitRegion   ('MenuBoxScrollbarButtonOver',        827,   72,   10,   10)
emitRegion   ('MenuBoxScrollbarButtonSelected',    827,   83,   10,   10)

emitComment  ('Menu Buttons')
emitNineSlice('MenuButton',                        584,   30,  192,  192,   64,   64)
emitNineSlice('MenuButtonOver',                    584,  224,  192,  192,   64,   64)
emitNineSlice('MenuButtonSelected',                778,  224,  192,  192,   64,   64)

emitComment  ('Tutorials')
emitNineSlice('TutorialBox',                         2,  536,  192,  192,   64,   64)
emitRegion   ('TutorialArrow',                     817,    6,   10,   19)

emitComment  ('Menu Arrows')
emitRegion   ('MenuArrowHorizonal',                817,   36,   10,   19)
emitRegion   ('MenuArrowVertical',                 833,   40,   19,   10)

emitComment  ('Scroll Bar Parts')
emitRegion   ('Thumb',                             826,   60,   11,   11)
emitRegion   ('ThumbOver',                         826,   71,   11,   11)
emitRegion   ('ThumbSelected',                     826,   82,   11,   11)
emitRegion   ('TrackBackground',                   830,   94,    6,    6)

emitComment  ('Back Buttons')
emitRegion   ('BackButton',                        857,   94,   25,   25)
emitRegion   ('BackButtonOver',                    857,  122,   25,   25)
emitRegion   ('BackButtonSelected',                857,  150,   25,   25)

emitComment  ('Settings Buttons')
emitRegion   ('SettingsButton',                    885,   94,   25,   25)
emitRegion   ('SettingsButtonOver',                885,  122,   25,   25)
emitRegion   ('SettingsButtonSelected',            885,  150,   25,   25)

emitComment  ('Sound Buttons')
emitRegion   ('SoundButton',                       913,   94,   25,   25)
emitRegion   ('SoundButtonOver',                   913,  122,   25,   25)
emitRegion   ('SoundButtonSelected',               913,  150,   25,   25)

emitComment  ('ZoomIn Buttons')
emitRegion   ('ZoomInButton',                      969,   94,   25,   25)
emitRegion   ('ZoomInButtonOver',                  969,  122,   25,   25)
emitRegion   ('ZoomInButtonSelected',              969,  150,   25,   25)

emitComment  ('ZoomOut Buttons')
emitRegion   ('ZoomOutButton',                     941,   94,   25,   25)
emitRegion   ('ZoomOutButtonOver',                 941,  122,   25,   25)
emitRegion   ('ZoomOutButtonSelected',             941,  150,   25,   25)

emitComment  ('Recenter Buttons')
emitRegion   ('RecenterButton',                    997,   94,   25,   25)
emitRegion   ('RecenterButtonOver',                997,  122,   25,   25)
emitRegion   ('RecenterButtonSelected',            997,  150,   25,   25)

emitComment  ('Text Inputs')
emitRegion   ('TextInput',                           0,    0,  246,   28)
emitRegion   ('TextInputOver',                     248,    0,  246,   28)
emitRegion   ('TextInputSelected',                 495,    0,  246,   28)

emitFooter()
