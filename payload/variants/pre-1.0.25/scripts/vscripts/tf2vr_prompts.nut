global function TF2VR_PromptText
global function TF2VR_PromptGesture
global function TF2VR_TitanKeyHint

// Titan ability swipes in offhand slot order
array<string> function TF2VR_TitanGestures()
{
	return [ "up", "forward", "down", "back" ]
}

int function TF2VR_OffhandSlot( string key )
{
	table<string, int> slots = {
		["%offhand0%"] = 0,
		["%offhand1%"] = 1,
		["%offhand2%"] = 2,
		["%offhand3%"] = 3
	}
	return key in slots ? slots[key] : -1
}

// inline arrow built by gesture_icons.py, other keys stay
string function TF2VR_TitanKeyHint( string key )
{
	int slot = TF2VR_OffhandSlot( key )
	return slot == -1 ? key : "%$rui/tf2vr/arrows/" + TF2VR_TitanGestures()[slot] + "%"
}

int function TF2VR_PromptGesture( OnscreenHint hint )
{
	switch ( hint.locStringGamepad )
	{
		case "#TRAINING_HINT_OBJECTIVE":
			return 4
		case "#BEACON_SWITCH_TO_ARC_TOOL_HINT":
		case "#BEACON_ARC_TOOL_ACTIVATE_SWITCHES_HINT":
		case "#TF2VR_HINT_HIP":
			return 5
		case "#TF2VR_HINT_DRAW":
		case "#TF2VR_HINT_MAGAZINE":
			return 6
		case "#TITAN_TRAINING_HINT_MISSILE_SYSTEM":
		case "#TITAN_TRAINING_HINT_MISSILE_SYSTEM_KBM":
			return 0
		case "#TITAN_TRAINING_HINT_VORTEX":
		case "#TITAN_TRAINING_HINT_VORTEX_KBM":
			return 1
		case "#HINT_WEAPON_PRESS":
		case "#HINT_WEAPON_HOLD":
			return TF2VR_OffhandSlot( hint.stringArg1 )
	}
	return -1
}

string function TF2VR_PromptText( OnscreenHint hint, int weaponHand, bool leftTouch )
{
	array<string> gestureNames = [ "위", "앞", "아래", "뒤" ]
	string useButton = "%use%"
	string abilityButton = weaponHand == 0 ? "오른쪽 트리거" : "왼쪽 트리거"
	string pauseButton = leftTouch ? "왼쪽 Y" : "왼쪽 B"
	string reloadButton = weaponHand == 0 ? pauseButton : "오른쪽 B"

	switch ( hint.locStringGamepad )
	{
		case "#TRAINING_HINT_FIRINGRANGE_DMG_TARGETS":
		case "#TRAINING_HINT_ADS":
		case "#TRAINING_HINT_ADS_ALT":
		case "#TRAINING_HINT_ADS_KBM":
		case "#HINT_EXECUTE":
		case "#MELEE_EXECUTE_PROMPT":
		case "#SP_SHELL_MELEE_HINT":
		case "#TRAINING_HINT_TITANFALL":
		case "#HUD_TITAN_READY_HINT":
		case "#HINT_SHOULDER_ROCKETS_HOLD":
			return ""

		case "#TRAINING_HINT_OBJECTIVE":
			return "한 손을 이마에 대면 목표를 확인할 수 있습니다"
		case "#TRAINING_HINT_JUMP":
		case "#SP_SHELL_JUMP_HINT":
			return "오른쪽 A 버튼을 눌러 점프하세요"
		case "#TRAINING_HINT_DOUBLEJUMP":
		case "#SP_SHELL_DOUBLE_JUMP_HINT":
			return "공중에서 오른쪽 A 버튼을 다시 눌러 이단 점프하세요"
		case "#TRAINING_HINT_SPRINT_BUTTON":
		case "#TRAINING_HINT_SPRINT_BUTTON_KBM":
			return "왼쪽 스틱을 눌러 질주하세요"
		case "#TRAINING_HINT_WALLRUN":
		case "#TRAINING_WALLRUN_REMINDER":
			return "벽을 향해 비스듬히 점프하면 벽을 달릴 수 있습니다"
		case "#TRAINING_HINT_CROUCH":
			return "몸을 숙이거나 오른쪽 스틱을 아래로 당기세요. 질주 중에는 슬라이딩합니다"
		case "#HINT_CROUCH":
		case "#SP_SHELL_CROUCH_HINT":
			return "몸을 숙이거나 오른쪽 스틱을 아래로 당기세요"
		case "#TRAINING_HINT_RELOAD":
		case "#TRAINING_HINT_RELOAD_KBM":
			return reloadButton + " 버튼을 눌러 재장전하세요"
		case "#TRAINING_HINT_WEAPON_PICKUP":
		case "#TRAINING_HINT_WEAPON_PICKUP_KBM":
			return "빈손으로 윤곽선이 표시된 무기를 잡으세요"
		case "#TRAINING_HINT_WEAPON_SWAP":
			return "어깨 너머에서 주무기를, 왼쪽 허리에서 보조무기를 잡으세요"
		case "#TF2VR_HINT_DRAW":
			return "그립을 놓으면 무기를 수납합니다. 어깨 너머로 손을 뻗어 꺼내세요"
		case "#TF2VR_HINT_MAGAZINE":
			return ( weaponHand == 0 ? "오른쪽" : "왼쪽" ) + " 어깨 너머에서 탄창을 꺼내세요"
		case "#TF2VR_HINT_NO_AMMO":
			return "탄약이 없습니다"
		case "#TF2VR_HINT_HIP":
			return "왼쪽 허리에서 보조무기를 꺼내세요"
		case "#TF2VR_HINT_REPLACE":
			return "새 무기를 잡으면 마지막으로 들었던 무기가 교체됩니다"
		case "#TF2VR_HINT_RECENTER":
			return "두 스틱을 동시에 누르거나 일시정지 메뉴에서 시점 재정렬을 선택하세요"
		case "#BEACON_SWITCH_TO_ARC_TOOL_HINT":
			return "오른쪽 허리에서 아크 도구를 꺼내세요"
		case "#BEACON_ARC_TOOL_ACTIVATE_SWITCHES_HINT":
			return "오른쪽 허리에서 아크 도구를 꺼내 스위치를 겨누고 트리거를 누르세요"
		case "#TRAINING_HINT_GRENADE":
			return "가슴 위쪽에서 수류탄을 잡고, 손을 휘두르며 그립을 놓아 던지세요"
		case "#TRAINING_HINT_MELEE":
			return "빈손으로 그립을 누르고 주먹을 휘두르거나 오른쪽 스틱을 누르세요"
		case "#TRAINING_HINT_CLOAK":
			return abilityButton + "를 눌러 은폐하세요"
		case "#TIMESHIFT_HINT_DEFAULT":
			return abilityButton + "를 눌러 시간 이동하세요"
		case "#TIMESHIFT_HINT_COMBAT":
			return abilityButton + "를 눌러 시간 이동하세요"
		case "#TIMESHIFT_HINT_PAST":
			return abilityButton + "를 눌러 과거로 이동하세요"
		case "#TIMESHIFT_HINT_PRESENT":
			return abilityButton + "를 눌러 현재로 이동하세요"
		case "#TIMESHIFT_HINT_ESCAPE_DAMAGE":
			return abilityButton + "를 눌러 다른 시간대로 피하세요"
		case "#TIMESHIFT_HINT_SCIENTIST_QUARTERS":
			return abilityButton + "를 눌러 시간 이동한 뒤 출구를 찾으세요"
		case "#TIMESHIFT_HINT_LASER_INTRO":
			return abilityButton + "를 눌러 시간 이동으로 레이저 장벽을 통과하세요"
		case "#TIMESHIFT_HINT_DEBRIS_INTRO":
			return abilityButton + "를 눌러 시간 이동으로 잔해를 지나가세요"
		case "#TIMESHIFT_HINT_DOOR_INTRO":
			return abilityButton + "를 눌러 시간 이동으로 닫힌 문을 통과하세요"
		case "#TIMESHIFT_HINT_ELEVATOR_INTRO":
			return abilityButton + "를 눌러 시간 이동으로 엘리베이터 문을 통과하세요"
		case "#TIMESHIFT_HINT_ELEVATOR_CAR_INTRO":
			return abilityButton + "를 눌러 시간 이동으로 엘리베이터 해치를 통과하세요"
		case "#TIMESHIFT_HINT_FANS_INTRO":
			return abilityButton + "를 눌러 시간 이동으로 회전하는 환풍기를 통과하세요"
		case "#TRAINING_HINT_LEECH":
			return useButton + "를 길게 눌러 주변 스펙터를 해킹하세요"
		case "#TRAINING_HINT_CONVERSATION":
		case "#TRAINING_HINT_CONVERSATION_KBM":
			return ( leftTouch ? "왼쪽 Y" : "왼쪽 B" ) + " 버튼으로 위쪽 선택지, " + ( leftTouch ? "왼쪽 X" : "왼쪽 A" ) + " 버튼으로 아래쪽 선택지를 고르세요"
		case "#TRAINING_HINT_GAUNTLET_RESTART":
			return pauseButton + " 버튼을 누른 뒤 건틀릿 재시작을 선택하세요"
		case "#HINT_LOGBOOK_UPDATED":
			return "기록이 갱신되었습니다. 왼손을 비우고 " + pauseButton + " 버튼을 누르세요"
		case "#SEWERS_HINT_DISEMBARK":
		case "#HUD_TITAN_DISEMBARK":
			return useButton + "을 길게 눌러 타이탄에서 내리세요"
		case "#HINT_DASH":
			return "왼쪽 스틱으로 방향을 정하고 오른쪽 A 버튼을 눌러 대시하세요"
		case "#TITAN_TRAINING_HINT_VORTEX":
		case "#TITAN_TRAINING_HINT_VORTEX_KBM":
			return "왼손 그립을 누르고 앞으로 휘두르세요. 주먹을 겨누고 그립을 놓아 탄환을 되돌리세요"
		case "#TITAN_TRAINING_HINT_MISSILE_SYSTEM":
		case "#TITAN_TRAINING_HINT_MISSILE_SYSTEM_KBM":
			return "왼손 그립을 누르고 위로 휘두르세요. 그립을 놓으면 지정한 표적에 발사합니다"
		case "#CRANE_OPERATION_HINT_KEYBOARD":
		case "#CRANE_OPERATION_HINT_GAMEPAD":
		case "#CRANE_OPERATION_HINT_GAMEPAD_SOUTHPAW":
			return "왼쪽 스틱으로 크레인을 움직이고 " + useButton + "를 눌러 내리세요"
		case "#HINT_WEAPON_PRESS":
		case "#HINT_WEAPON_HOLD":
			if ( TF2VR_PromptGesture( hint ) < 0 )
				return hint.locStringGamepad
			return "왼손 그립을 누르고 " + gestureNames[TF2VR_PromptGesture( hint )] + "로 휘둘러 " + Localize( hint.stringArg2 ) + " 사용"
	}

	return hint.locStringGamepad
}
