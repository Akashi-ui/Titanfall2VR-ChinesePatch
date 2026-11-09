global function KoreanMenuTest_Init
void function KoreanMenuTest_Init()
{
    ClientCommand( "cc_rui 0" )
   ClientCommand( "cc_lang tchinese" )
    ClientCommand( "closecaption 1" )
    print( "[ZH_TW] Noto Sans CJK font / Traditional Chinese captions requested" )
}