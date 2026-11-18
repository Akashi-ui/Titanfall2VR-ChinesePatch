global function TF2VR_MenuInit
global function TF2VR_OpenSettings
global function TF2VR_OpenHighlights

void function TF2VR_MenuInit()
{
	// once per profile, the stock full master volume starts at half
	if ( !GetConVarBool( "tf2vr_volume_defaulted" ) )
	{
		if ( GetConVarFloat( "sound_volume" ) == 1.0 )
			SetConVarFloat( "sound_volume", 0.5 )
		SetConVarBool( "tf2vr_volume_defaulted", true )
	}
	var menu = GetMenu( "InGameSPMenu" )
	var titanLoadoutButton = Hud_GetChild( menu, "BtnDev" )
	SetButtonRuiText( titanLoadoutButton, "泰坦裝備" )
	AddButtonEventHandler( titanLoadoutButton, UIE_CLICK, TF2VR_OpenTitanLoadout )
	Hud_Show( titanLoadoutButton )
	var settingsButton = Hud_GetChild( menu, "BtnVRSettings" )
	SetButtonRuiText( settingsButton, "#TF2VR_SETTINGS" )
	AddButtonEventHandler( settingsButton, UIE_CLICK, AdvanceMenuEventHandler( GetMenu( "TF2VRSettings" ) ) )
	var recenterButton = Hud_GetChild( menu, "BtnRecenter" )
	SetButtonRuiText( recenterButton, "#TF2VR_RECENTER" )
	AddButtonEventHandler( recenterButton, UIE_CLICK, TF2VR_RecenterButton )
	SetNavUpDown( [ Hud_GetChild( menu, "BtnChangeDifficulty" ), Hud_GetChild( menu, "BtnQuit" ), titanLoadoutButton, settingsButton, recenterButton ] )
	// Titan abilities show their swipe in place of a key, vgui labels can't draw the RUI arrows
	var loadout = Hud_GetChild( GetMenu( "SPTitanLoadoutMenu" ), "TitanLoadoutDisplay" )
	Hud_SetText( Hud_GetChild( loadout, "OrdnanceHintPC" ), "上" )
	Hud_SetText( Hud_GetChild( loadout, "SpecialHintPC" ), "前" )
	Hud_SetText( Hud_GetChild( loadout, "AntirodeoHintPC" ), "下" )
	Hud_SetText( Hud_GetChild( loadout, "CoreHintPC" ), "後" )
	// the spotlight has no promos without a master server, so it holds the support card
	var spotlight = Hud_GetChild( GetPanel( "MainMenuPanel" ), "SpotlightPanel" )
	var supportButton = Hud_GetChild( spotlight, "SpotlightLarge" )
	RuiSetFloat( Hud_GetRui( supportButton ), "basicImageAlpha", 0.0 )
	RuiSetImage( Hud_GetRui( Hud_GetChild( spotlight, "SupportAvatar" ) ), "basicImage", $"rui/tf2vr/support" )
	RuiSetFloat3( Hud_GetRui( Hud_GetChild( spotlight, "SupportBackdrop" ) ), "basicImageColor", < 0, 0, 0 > )
	// Northstar blue
	RuiSetFloat3( Hud_GetRui( Hud_GetChild( spotlight, "SupportAccent" ) ), "basicImageColor", < 101, 109, 207 > / 255.0 )
	TF2VR_SupportFocus( supportButton, false )
	AddButtonEventHandler( supportButton, UIE_GET_FOCUS, void function( var button ) { TF2VR_SupportFocus( button, true ) } )
	AddButtonEventHandler( supportButton, UIE_LOSE_FOCUS, void function( var button ) { TF2VR_SupportFocus( button, false ) } )
	AddButtonEventHandler( supportButton, UIE_CLICK, TF2VR_OpenSupportPage )
	Hud_Show( spotlight )
	thread TF2VR_MenuThink()
}

void function TF2VR_SupportFocus( var button, bool focused )
{
	var spotlight = Hud_GetParent( button )
	RuiSetFloat( Hud_GetRui( Hud_GetChild( spotlight, "SupportBackdrop" ) ), "basicImageAlpha", focused ? 0.85 : 0.55 )
	Hud_SetVisible( Hud_GetChild( spotlight, "SupportAccent" ), focused )
	int body = focused ? 255 : 225
	Hud_SetColor( Hud_GetChild( spotlight, "SupportText" ), body, body, body, 255 )
}

void function TF2VR_OpenSupportPage( var button )
{
	LaunchExternalWebBrowser( "https://ko-fi.com/circuitlord", WEBBROWSER_FLAG_FORCEEXTERNAL )
	DialogData dialogData
	dialogData.header = "OPENED ON DESKTOP"
	dialogData.message = "Ko-fi is opened in your default browser on your desktop!"
	AddDialogButton( dialogData, "OK" )
	AddDialogFooter( dialogData, "#A_BUTTON_SELECT" )
	OpenDialog( dialogData )
}

void function TF2VR_OpenSettings()
{
	AdvanceMenu( GetMenu( "TF2VRSettings" ) )
}

void function TF2VR_OpenHighlights()
{
	DialogData dialogData
	dialogData.header = "本地精彩片段"
	dialogData.message = "Titanfall 2 VR 會錄製遊戲精彩片段並保存到你的電腦上。\n\n此模組不會上傳或分享影片。"
	AddDialogButton( dialogData, "打開資料夾", TF2VR_OpenMemoryDirectory )
	AddDialogButton( dialogData, "#CANCEL" )
	AddDialogFooter( dialogData, "#A_BUTTON_SELECT" )
	AddDialogFooter( dialogData, "#B_BUTTON_BACK" )
	OpenDialog( dialogData )
}

void function TF2VR_RecenterButton( var button )
{
	TF2VR_RequestRecenter()
	CloseActiveMenu()
}

void function TF2VR_OpenTitanLoadout( var button )
{
	ClientCommand( "titan_loadout_select" )
}

void function TF2VR_MenuThink()
{
	int previousStartup = 0
	int previousTick = 0
	while ( true )
	{
		int startup = TF2VR_StartupPhase()
		int tick = TF2VR_StartupTick()
		if ( startup == 2 && tick > previousTick )
			EmitUISound( "menu_focus" )
		previousTick = tick
		if ( startup == 3 && previousStartup != 3 )
			EmitUISound( "Menu_GameSummary_ChallengeCompleted" )
		previousStartup = startup
		TF2VR_SetMenuActive( GetActiveMenu() != null && !uiGlobal.playingVideo )
		WaitFrame()
	}
}
