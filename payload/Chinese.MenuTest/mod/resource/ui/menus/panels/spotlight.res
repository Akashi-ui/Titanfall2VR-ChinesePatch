"resource/ui/menus/panels/spotlight.res"
{
    // support card, a clear button over a backdrop, the avatar, and labels, tf2vr_menu.nut
    SpotlightLarge
    {
        ControlName				RuiButton
        classname 				SpotlightButtonClass
        scriptID				0
        rui						"ui/basic_image.rpak"
        labelText				""
        wide					540
        tall					150
        zpos					4
        visible					1
    }
    SupportBackdrop
    {
        ControlName				RuiPanel
        rui						"ui/basic_image.rpak"
        wide					540
        tall					150
        zpos					1
        visible					1

        pin_to_sibling			SpotlightLarge
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	TOP_LEFT
    }
    SupportAccent
    {
        ControlName				RuiPanel
        rui						"ui/basic_image.rpak"
        wide					6
        tall					150
        zpos					3
        visible					0

        pin_to_sibling			SpotlightLarge
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	TOP_LEFT
    }
    SupportAvatar
    {
        ControlName				RuiPanel
        rui						"ui/basic_image.rpak"
        wide					150
        tall					150
        zpos					2
        visible					1

        pin_to_sibling			SupportAccent
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	TOP_RIGHT
    }
    SupportTitle
    {
        ControlName				Label
        InheritProperties		SubheaderText
        xpos					16
        ypos					-14
        textAlignment			north-west
        zpos					2
        labelText				"SUPPORT CIRCUITLORD"

        pin_to_sibling			SupportAvatar
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	TOP_RIGHT
    }
    SupportText
    {
        ControlName				Label
        wide					360
        tall					90
        zpos					2
        font					Default_23
        wrap					1
        textAlignment			north-west
        fgcolor_override		"225 225 225 255"
        labelText				"If you're enjoying my Titanfall 2 VR mod, consider supporting me on Ko-fi so I can keep making cool stuff like this!"

        pin_to_sibling			SupportTitle
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	BOTTOM_LEFT
    }
    // Chinese patch version window, directly below the support card.
    VersionBackdrop
    {
        ControlName				RuiPanel
        rui						"ui/basic_image.rpak"
        wide					540
        tall					125
        zpos					1
        visible					1

        pin_to_sibling			SpotlightLarge
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	BOTTOM_LEFT
        ypos					16
    }
    VersionAccent
    {
        ControlName				RuiPanel
        rui						"ui/basic_image.rpak"
        wide					6
        tall					125
        zpos					3
        visible					1

        pin_to_sibling			VersionBackdrop
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	TOP_LEFT
    }
    VersionButton
    {
        ControlName				RuiButton
        rui						"ui/basic_image.rpak"
        labelText				""
        wide					540
        tall					125
        zpos					6
        visible					1

        pin_to_sibling			SpotlightLarge
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	BOTTOM_LEFT
        ypos					16
    }
    VersionTitle
    {
        ControlName				Label
        InheritProperties		SubheaderText
        xpos					-8
        ypos					4
        textAlignment			north-west
        zpos					5
        labelText				"中文補丁版本"

        pin_to_sibling			VersionBackdrop
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	TOP_LEFT
    }
    VersionCurrent
    {
        ControlName				Label
        xpos					-8
        ypos					-33
        wide					508
        tall					22
        font					Default_23
        zpos					5
        fgcolor_override		"225 225 225 255"
        labelText				"目前版本: 載入中"

        pin_to_sibling			VersionBackdrop
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	TOP_LEFT
    }
    VersionLatest
    {
        ControlName				Label
        xpos					-8
        ypos					-57
        wide					508
        tall					22
        font					Default_23
        zpos					5
        fgcolor_override		"225 225 225 255"
        labelText				"最新版本: 檢查中"

        pin_to_sibling			VersionBackdrop
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	TOP_LEFT
    }
    VersionHint
    {
        ControlName				Label
        xpos					-8
        ypos					-36
        wide					508
        tall					32
        font					Default_25
        zpos					5
        fgcolor_override		"225 225 225 255"
        labelText				"點擊此卡片可在桌面上的瀏覽器中開啟最新版本下載頁面"

        pin_to_sibling			VersionButton
        pin_corner_to_sibling	TOP_LEFT
        pin_to_sibling_corner	BOTTOM_LEFT
    }
    // Northstar's script navigates to the small spotlights, which have no promos without a master server
    SpotlightSmall0
    {
        ControlName				RuiButton
        InheritProperties		SpotlightButtonSmall
        classname 				SpotlightButtonClass
        scriptID				1
        visible					0
    }
    SpotlightSmall1
    {
        ControlName				RuiButton
        InheritProperties		SpotlightButtonSmall
        classname 				SpotlightButtonClass
        scriptID				2
        visible					0
    }
}
