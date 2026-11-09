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
	array<string> gestureNames = [ "上", "前", "下", "后" ]
	string useButton = "%use%"
	string abilityButton = weaponHand == 0 ? "右扳机" : "左扳机"
	string pauseButton = leftTouch ? "左侧 Y 键" : "左侧 B 键"
	string detonateButton = leftTouch ? "左侧 X 键" : "左侧 A 键"
	string reloadButton = weaponHand == 0 ? pauseButton : "右侧 B 键"

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
			return "将一只手放在额头上即可查看目标"
		case "#TRAINING_HINT_JUMP":
		case "#SP_SHELL_JUMP_HINT":
			return "按下右侧 A 键跳跃"
		case "#TRAINING_HINT_DOUBLEJUMP":
		case "#SP_SHELL_DOUBLE_JUMP_HINT":
			return "在空中再次按下右侧 A 键进行二段跳"
		case "#TRAINING_HINT_SPRINT_BUTTON":
		case "#TRAINING_HINT_SPRINT_BUTTON_KBM":
			return "按下左摇杆冲刺"
		case "#TRAINING_HINT_WALLRUN":
		case "#TRAINING_WALLRUN_REMINDER":
			return "朝墙壁跳跃即可滑墙"
		case "#TRAINING_HINT_CROUCH":
			return "弯腰或向下拨动右摇杆。冲刺时会进行滑铲"
		case "#HINT_CROUCH":
		case "#SP_SHELL_CROUCH_HINT":
			return "弯腰或向下拨动右摇杆"
		case "#TRAINING_HINT_RELOAD":
		case "#TRAINING_HINT_RELOAD_KBM":
			return reloadButton + " 按下以重新装填弹药"
		case "#TRAINING_HINT_WEAPON_PICKUP":
		case "#TRAINING_HINT_WEAPON_PICKUP_KBM":
			return "用空手拾取带有高亮轮廓的武器"
		case "#TRAINING_HINT_WEAPON_SWAP":
			return "从肩后取出主武器，从左侧腰间取出副武器"
		case "#TF2VR_HINT_DRAW":
			return "松开握持键即可收起武器。将手伸向肩后即可取出武器"
		case "#TF2VR_HINT_MAGAZINE":
			return ( weaponHand == 0 ? "右侧" : "左侧" ) + "从肩后取出弹匣"
		case "#TF2VR_HINT_NO_AMMO":
			return "没有弹药"
		case "#TF2VR_HINT_HIP":
			return "从左侧腰间取出副武器"
		case "#TF2VR_HINT_REPLACE":
			return "拿起新武器后，之前手持的武器将被替换"
		case "#TF2VR_HINT_RECENTER":
			return "同时按下两个摇杆，或在暂停菜单中选择重新校准视角"
		case "#BEACON_SWITCH_TO_ARC_TOOL_HINT":
			return "从右侧腰间取出电弧装置"
		case "#BEACON_ARC_TOOL_ACTIVATE_SWITCHES_HINT":
			return "从右侧腰间取出电弧装置，瞄准开关并扣下扳机"
		case "#TRAINING_HINT_GRENADE":
			return "从胸前上方拿起手雷，挥动手臂并松开握持键即可投掷"
		case "#TF2VR_HINT_SATCHEL":
		case "#SATCHEL_HINT_TAP_TWICE":
			return "按下 " + detonateButton + " 来引爆已放置的炸药包"
		case "#TRAINING_HINT_MELEE":
			return "空手时按住握持键并挥拳，或按下右摇杆"
		case "#TRAINING_HINT_CLOAK":
			return "按下 " + abilityButton + " 隐身"
		case "#TIMESHIFT_HINT_DEFAULT":
			return "按下 " + abilityButton + " 切换时间"
		case "#TIMESHIFT_HINT_COMBAT":
			return "按下 " + abilityButton + " 切换时间"
		case "#TIMESHIFT_HINT_PAST":
			return "按下" + abilityButton + "切换到过去"
		case "#TIMESHIFT_HINT_PRESENT":
			return "按下" + abilityButton + "切换到现在"
		case "#TIMESHIFT_HINT_ESCAPE_DAMAGE":
			return "按下" + abilityButton + "切换时间线以躲避伤害"
		case "#TIMESHIFT_HINT_SCIENTIST_QUARTERS":
			return "按下" + abilityButton + "进行时间跳跃，然后寻找出口"
		case "#TIMESHIFT_HINT_LASER_INTRO":
			return "按下" + abilityButton + "切换时间线，穿过屏障"
		case "#TIMESHIFT_HINT_DEBRIS_INTRO":
			return "按下" + abilityButton + "切换时间线，穿过废墟"
		case "#TIMESHIFT_HINT_DOOR_INTRO":
			return "按下" + abilityButton + "切换时间线，穿过关闭的门"
		case "#TIMESHIFT_HINT_ELEVATOR_INTRO":
			return "按下" + abilityButton + "切换时间线，穿过电梯门"
		case "#TIMESHIFT_HINT_ELEVATOR_CAR_INTRO":
			return "按下" + abilityButton + "切换时间线，穿过电梯舱门"
		case "#TIMESHIFT_HINT_FANS_INTRO":
			return "按下" + abilityButton + "切换时间线，穿过旋转的风扇"
		case "#TRAINING_HINT_LEECH":
			return "长按" + useButton + "骇入附近的幽灵"
		case "#TRAINING_HINT_CONVERSATION":
		case "#TRAINING_HINT_CONVERSATION_KBM":
			return ( leftTouch ? "左侧 Y 键" : "左侧 B 键" ) + "按钮选择上方选项，" + ( leftTouch ? "左侧 X 键" : "左侧 A键" ) + "按钮选择下方选项"
		case "#TRAINING_HINT_GAUNTLET_RESTART":
			return "按下" + pauseButton + "键选择重新开始训练"
		case "#HINT_LOGBOOK_UPDATED":
			return "记录已更新。腾出左手，然后按下" + pauseButton + "键"
		case "#SEWERS_HINT_DISEMBARK":
		case "#HUD_TITAN_DISEMBARK":
			return "长按" + useButton + "以离开泰坦"
		case "#HINT_DASH":
			return "使用左摇杆调整方向，然后按下右侧 A 键进行冲刺"
		case "#TITAN_TRAINING_HINT_VORTEX":
		case "#TITAN_TRAINING_HINT_VORTEX_KBM":
			return "按住左扳机并向前挥动。松开扳机即可反弹来袭的子弹"
		case "#TITAN_TRAINING_HINT_MISSILE_SYSTEM":
		case "#TITAN_TRAINING_HINT_MISSILE_SYSTEM_KBM":
			return "按住左扳机并向上挥动。松开扳机即可向指定目标发射导弹"
		case "#CRANE_OPERATION_HINT_KEYBOARD":
		case "#CRANE_OPERATION_HINT_GAMEPAD":
		case "#CRANE_OPERATION_HINT_GAMEPAD_SOUTHPAW":
			return "使用左摇杆移动起重机，按下" + useButton + "将其放下"
		case "#HINT_WEAPON_PRESS":
		case "#HINT_WEAPON_HOLD":
			if ( TF2VR_PromptGesture( hint ) < 0 )
				return hint.locStringGamepad
			return "按住左扳机，然后通过" + gestureNames[TF2VR_PromptGesture( hint )] + "动作使用" + Localize( hint.stringArg2 )
	}

	return hint.locStringGamepad
}
