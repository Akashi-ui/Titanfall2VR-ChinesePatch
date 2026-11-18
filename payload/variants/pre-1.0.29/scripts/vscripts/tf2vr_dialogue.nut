global function TF2VR_ChooseDialogue
global function TF2VR_DialogueText

string function TF2VR_DialogueText( string text, bool top, bool leftTouch )
{
	if ( text == "" )
		return ""
	string button = top ? ( leftTouch ? "Y" : "B" ) : ( leftTouch ? "X" : "A" )
	return "[左 " + button + "] " + Localize( text )
}

table function TF2VR_ChooseDialogue( entity player, var rui, bool firstAvailable, bool secondAvailable, string firstText, string secondText, float intro, float timeout )
{
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )
	OnThreadEnd( function() { TF2VR_DialogueInput( false ) } )
	float readyAt = Time() + intro
	float expiresAt = readyAt + timeout
	bool leftTouch = TF2VR_LeftUsesTouch() != 0
	RuiSetString( rui, "text1", TF2VR_DialogueText( firstText, true, leftTouch ) )
	RuiSetString( rui, "text2", TF2VR_DialogueText( secondText, false, leftTouch ) )
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
