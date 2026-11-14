global function ChineseMenuTest_Init
void function ChineseMenuTest_Init()
{
    ClientCommand( "cc_rui 0" )
   ClientCommand( "cc_lang tchinese" )
    ClientCommand( "closecaption 1" )
    print( "[ZH_TW] Noto Sans CJK font / Traditional Chinese captions requested" )
}