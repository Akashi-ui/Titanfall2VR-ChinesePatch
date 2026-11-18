global function TF2VR_ChooseDialogue
global function TF2VR_DialogueText

string function TF2VR_DialogueText( string text, bool top, int controller )
{
	if ( text == "" )
		return ""
	// Frame top takes d-pad up alone
	array<string> tops = [ "左 B", "左 Y", "%$rui/tf2vr/dpad/up%" ]
	array<string> bottoms = [ "左 A", "左 X", "%$rui/tf2vr/dpad/down%" ]
	return "[" + ( top ? tops[controller] : bottoms[controller] ) + "] " + Localize( text )
}

table function TF2VR_ChooseDialogue( entity player, var rui, bool firstAvailable, bool secondAvailable, string firstText, string secondText, float intro, float timeout )
{
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )
	OnThreadEnd( function() { TF2VR_DialogueInput( false ) } )
	float readyAt = Time() + intro
	float expiresAt = readyAt + timeout
	int controller = TF2VR_LeftController()
	RuiSetString( rui, "text1", TF2VR_DialogueText( firstText, true, controller ) )
	RuiSetString( rui, "text2", TF2VR_DialogueText( secondText, false, controller ) )
	TF2VR_DialogueInput( true )
	while ( Time() < expiresAt )
	{
		int input = TF2VR_DialogueInput( true )
		if ( Time() >= readyAt && ( input & 1 ) && firstAvailable )
			return { signal = "DialogueChoice1" }
		if ( Time() >= readyAt && ( input & 2 ) && secondAvailable )
			return { signal = "DialogueChoice2" }
		WaitFrame()
	}
	return { signal = "DialogueChoiceTimeout" }
}
