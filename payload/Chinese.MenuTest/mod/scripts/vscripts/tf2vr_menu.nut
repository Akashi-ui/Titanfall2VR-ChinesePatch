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
	SetButtonRuiText( titanLoadoutButton, "#KO_TITAN_LOADOUT" )
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
	Hud_SetText( Hud_GetChild( loadout, "CoreHintPC" ), "后" )
	thread TF2VR_MenuThink()
}

void function TF2VR_OpenSettings()
{
	AdvanceMenu( GetMenu( "TF2VRSettings" ) )
}

void function TF2VR_OpenHighlights()
{
	DialogData dialogData
	dialogData.header = "#KO_HIGHLIGHTS_TITLE"
	dialogData.message = "#KO_HIGHLIGHTS_MESSAGE"
	AddDialogButton( dialogData, "#KO_OPEN_FOLDER", TF2VR_OpenMemoryDirectory )
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
