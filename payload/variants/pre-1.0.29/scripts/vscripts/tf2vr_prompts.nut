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
	array<string> gestureNames = [ "上", "前", "下", "後" ]
	string useButton = "%use%"
	string abilityButton = weaponHand == 0 ? "右扳機" : "左扳機"
	string pauseButton = leftTouch ? "左側 Y 鍵" : "左側 B 鍵"
	string detonateButton = leftTouch ? "左側 X 鍵" : "左側 A 鍵"
	string reloadButton = weaponHand == 0 ? pauseButton : "右側 B 鍵"

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
			return "將一隻手放在額頭上即可查看目標"
		case "#TRAINING_HINT_JUMP":
		case "#SP_SHELL_JUMP_HINT":
			return "按下右側 A 鍵跳躍"
		case "#TRAINING_HINT_DOUBLEJUMP":
		case "#SP_SHELL_DOUBLE_JUMP_HINT":
			return "在空中再次按下右側 A 鍵進行二段跳"
		case "#TRAINING_HINT_SPRINT_BUTTON":
		case "#TRAINING_HINT_SPRINT_BUTTON_KBM":
			return "按下左搖桿衝刺"
		case "#TRAINING_HINT_WALLRUN":
		case "#TRAINING_WALLRUN_REMINDER":
			return "朝牆壁跳躍即可滑牆"
		case "#TRAINING_HINT_CROUCH":
			return "彎腰、蹲下或向下撥動右搖桿。衝刺時會進行滑鏟"
		case "#HINT_CROUCH":
		case "#SP_SHELL_CROUCH_HINT":
			return "彎腰、蹲下或向下撥動右搖桿"
		case "#TRAINING_HINT_RELOAD":
		case "#TRAINING_HINT_RELOAD_KBM":
			return reloadButton + " 按下以重新裝填彈藥"
		case "#TRAINING_HINT_WEAPON_PICKUP":
		case "#TRAINING_HINT_WEAPON_PICKUP_KBM":
			return "用空手拾取帶有高亮輪廓的武器"
		case "#TRAINING_HINT_WEAPON_SWAP":
			return "從肩後取出主武器，從左側腰間取出副武器"
		case "#TF2VR_HINT_DRAW":
			return "鬆開握持鍵即可收起武器。將手伸向肩後即可取出武器"
		case "#TF2VR_HINT_MAGAZINE":
			return ( weaponHand == 0 ? "右側" : "左側" ) + "從肩後取出彈匣"
		case "#TF2VR_HINT_NO_AMMO":
			return "沒有彈藥"
		case "#TF2VR_HINT_HIP":
			return "從左側腰間取出副武器"
		case "#TF2VR_HINT_REPLACE":
			return "拿起新武器後，之前手持的武器將被替換"
		case "#TF2VR_HINT_RECENTER":
			return "同時按下兩個搖桿，或在暫停選單中選擇重設視角"
		case "#BEACON_SWITCH_TO_ARC_TOOL_HINT":
			return "從右側腰間取出電弧裝置"
		case "#BEACON_ARC_TOOL_ACTIVATE_SWITCHES_HINT":
			return "從右側腰間取出電弧裝置，瞄準開關並扣下扳機"
		case "#TRAINING_HINT_GRENADE":
			return "從胸前上方拿起手雷，揮動手臂並鬆開握持鍵即可投擲"
		case "#TF2VR_HINT_SATCHEL":
		case "#SATCHEL_HINT_TAP_TWICE":
			return "按下 " + detonateButton + " 來引爆已放置的炸藥包"
		case "#TRAINING_HINT_MELEE":
			return "空手時按住握持鍵並揮拳，或按下右搖桿"
		case "#TRAINING_HINT_CLOAK":
			return "按下 " + abilityButton + " 隱形"
		case "#TIMESHIFT_HINT_DEFAULT":
			return "按下 " + abilityButton + " 切換時間"
		case "#TIMESHIFT_HINT_COMBAT":
			return "按下 " + abilityButton + " 切換時間"
		case "#TIMESHIFT_HINT_PAST":
			return "按下" + abilityButton + "切換到過去"
		case "#TIMESHIFT_HINT_PRESENT":
			return "按下" + abilityButton + "切換到現在"
		case "#TIMESHIFT_HINT_ESCAPE_DAMAGE":
			return "按下" + abilityButton + "切換時間線以躲避傷害"
		case "#TIMESHIFT_HINT_SCIENTIST_QUARTERS":
			return "按下" + abilityButton + "進行時間跳躍，然後尋找出口"
		case "#TIMESHIFT_HINT_LASER_INTRO":
			return "按下" + abilityButton + "切換時間線，穿過屏障"
		case "#TIMESHIFT_HINT_DEBRIS_INTRO":
			return "按下" + abilityButton + "切換時間線，穿過廢墟"
		case "#TIMESHIFT_HINT_DOOR_INTRO":
			return "按下" + abilityButton + "切換時間線，穿過關閉的門"
		case "#TIMESHIFT_HINT_ELEVATOR_INTRO":
			return "按下" + abilityButton + "切換時間線，穿過電梯門"
		case "#TIMESHIFT_HINT_ELEVATOR_CAR_INTRO":
			return "按下" + abilityButton + "切換時間線，穿過電梯艙門"
		case "#TIMESHIFT_HINT_FANS_INTRO":
			return "按下" + abilityButton + "切換時間線，穿過旋轉的風扇"
		case "#TRAINING_HINT_LEECH":
			return "長按" + useButton + "駭入附近的幽靈"
		case "#TRAINING_HINT_CONVERSATION":
		case "#TRAINING_HINT_CONVERSATION_KBM":
			return ( leftTouch ? "左側 Y 鍵" : "左側 B 鍵" ) + "鍵選擇上方選項，" + ( leftTouch ? "左側 X 鍵" : "左側 A 鍵" ) + "鍵選擇下方選項"
		case "#TRAINING_HINT_GAUNTLET_RESTART":
			return "按下" + pauseButton + "選擇重新開始訓練"
		case "#HINT_LOGBOOK_UPDATED":
			return "記錄已更新。騰出左手，然後按下" + pauseButton
		case "#SEWERS_HINT_DISEMBARK":
		case "#HUD_TITAN_DISEMBARK":
			return "長按" + useButton + "以離開泰坦"
		case "#HINT_DASH":
			return "使用左搖桿調整方向，然後按下右側 A 鍵進行衝刺"
		case "#TITAN_TRAINING_HINT_VORTEX":
		case "#TITAN_TRAINING_HINT_VORTEX_KBM":
			return "按住左扳機並向前揮動。鬆開扳機即可反彈來襲的子彈"
		case "#TITAN_TRAINING_HINT_MISSILE_SYSTEM":
		case "#TITAN_TRAINING_HINT_MISSILE_SYSTEM_KBM":
			return "按住左扳機並向上揮動。鬆開扳機即可向指定目標發射飛彈"
		case "#CRANE_OPERATION_HINT_KEYBOARD":
		case "#CRANE_OPERATION_HINT_GAMEPAD":
		case "#CRANE_OPERATION_HINT_GAMEPAD_SOUTHPAW":
			return "使用左搖桿移動起重機，按下" + useButton + "將其放下"
		case "#HINT_WEAPON_PRESS":
		case "#HINT_WEAPON_HOLD":
			if ( TF2VR_PromptGesture( hint ) < 0 )
				return hint.locStringGamepad
			return "按住左扳機，然後作出「" + gestureNames[TF2VR_PromptGesture( hint )] + "」動作使用" + Localize( hint.stringArg2 )
	}

	return hint.locStringGamepad
}
