global function ChineseMenuTest_Init

const string CHINESE_RELEASES_API = "https://api.github.com/repos/Akashi-ui/Titanfall2VR-ChinesePatch/releases/latest"
const string CHINESE_RELEASES_PAGE = "https://github.com/Akashi-ui/Titanfall2VR-ChinesePatch/releases/latest"

var chineseVersionButton = null
var chineseVersionBackdrop = null
var chineseVersionCurrent = null
var chineseVersionLatest = null
var chineseVersionRequested = false

void function ChineseMenuTest_Init()
{
    ClientCommand( "cc_rui 0" )
    ClientCommand( "cc_lang tchinese" )
    ClientCommand( "closecaption 1" )
    print( "[ZH_TW] Noto Sans CJK font / Traditional Chinese captions requested" )
    thread ChineseVersion_Init()
}

void function ChineseVersion_Init()
{
    var panel = null
    var spotlight = null
    for ( int attempt = 0; attempt < 240; attempt++ )
    {
        panel = GetPanel( "MainMenuPanel" )
        if ( panel != null )
            spotlight = Hud_GetChild( panel, "SpotlightPanel" )
        if ( spotlight != null )
        {
            chineseVersionButton = Hud_GetChild( spotlight, "VersionButton" )
            if ( chineseVersionButton != null )
                break
        }
        WaitFrame()
    }
    if ( spotlight == null || chineseVersionButton == null )
        return
    chineseVersionBackdrop = Hud_GetChild( spotlight, "VersionBackdrop" )
    chineseVersionCurrent = Hud_GetChild( spotlight, "VersionCurrent" )
    chineseVersionLatest = Hud_GetChild( spotlight, "VersionLatest" )
    string current = "未知"
    array<ModInfo> infos = NSGetModInformation( "Chinese.MenuTest" )
    if ( infos.len() > 0 )
        current = infos[ 0 ].version
    if ( chineseVersionCurrent != null )
        Hud_SetText( chineseVersionCurrent, current == "未知" ? "目前版本: 未知" : "目前版本: v" + current )
    if ( chineseVersionLatest != null )
        Hud_SetText( chineseVersionLatest, "最新版本: 檢查中" )
    if ( chineseVersionBackdrop != null )
    {
        RuiSetFloat3( Hud_GetRui( chineseVersionBackdrop ), "basicImageColor", < 0, 0, 0 > )
        RuiSetFloat( Hud_GetRui( chineseVersionBackdrop ), "basicImageAlpha", 0.55 )
    }
    RuiSetFloat( Hud_GetRui( chineseVersionButton ), "basicImageAlpha", 0.0 )
    AddButtonEventHandler( chineseVersionButton, UIE_CLICK, ChineseVersion_OpenReleases )
    ChineseVersion_RequestLatest()
}

void function ChineseVersion_RequestLatest()
{
    if ( chineseVersionRequested )
        return
    chineseVersionRequested = true
    if ( !NSHttpGet( CHINESE_RELEASES_API, {}, ChineseVersion_OnResponse, ChineseVersion_OnFailure ) )
        ChineseVersion_SetUnavailable()
}

void function ChineseVersion_SetLatest( string tag )
{
    if ( chineseVersionLatest != null )
        Hud_SetText( chineseVersionLatest, "最新版本: v" + tag )
}

void function ChineseVersion_SetUnavailable()
{
    if ( chineseVersionLatest != null )
        Hud_SetText( chineseVersionLatest, "最新版本: 暫時無法取得" )
}

void function ChineseVersion_OnResponse( HttpRequestResponse response )
{
    if ( response.statusCode != 200 )
    {
        ChineseVersion_SetUnavailable()
        return
    }
    try
    {
        table data = DecodeJSON( response.body, true )
        if ( !( "tag_name" in data ) )
        {
            ChineseVersion_SetUnavailable()
            return
        }
        string tag = strip( string( data[ "tag_name" ] ) )
        if ( tag.len() > 0 && ( tag.find( "v" ) == 0 || tag.find( "V" ) == 0 ) )
            tag = tag.slice( 1 )
        if ( tag == "" )
            ChineseVersion_SetUnavailable()
        else
            ChineseVersion_SetLatest( tag )
    }
    catch ( ex )
    {
        ChineseVersion_SetUnavailable()
    }
}

void function ChineseVersion_OnFailure( HttpRequestFailure failure )
{
    ChineseVersion_SetUnavailable()
}

void function ChineseVersion_OpenReleases( var button )
{
    LaunchExternalWebBrowser( CHINESE_RELEASES_PAGE, WEBBROWSER_FLAG_FORCEEXTERNAL )
}
