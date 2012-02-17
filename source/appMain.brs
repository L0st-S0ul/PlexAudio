' ********************************************************************
' **  Entry point for the Plex Audio client. 
' ********************************************************************

Sub Main()
	'SetMainAppIsRunning() 'if setting screensaver
	initTheme()
	LaunchHomeScreen()
End Sub


'*************************************************************
'** Set the configurable theme attributes for the application
'** 
'** Configure the custom overhang and Logo attributes
'** Theme attributes affect the branding of the application
'** and are artwork, colors and offsets specific to the app
'*************************************************************

Sub initTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "31"
    theme.OverhangSliceSD = "pkg:/images/Background_SD.jpg"
    theme.OverhangLogoSD  = "pkg:/images/logo_final_SD.png"

    theme.OverhangOffsetHD_X = "125"
    theme.OverhangOffsetHD_Y = "35"
    theme.OverhangSliceHD = "pkg:/images/Background_HD.jpg"
    theme.OverhangLogoHD  = "pkg:/images/logo_final_HD.png"

	theme.GridScreenLogoHD          = "pkg:/images/GridScreen_HD.png"
    theme.GridScreenLogoOffsetHD_X  = "0"
    theme.GridScreenLogoOffsetHD_Y  = "0"
    theme.GridScreenOverhangHeightHD = "99"

    theme.GridScreenLogoSD          = "pkg:/images/GridScreen_SD.png"
    theme.GridScreenOverhangHeightSD = "66"
    theme.GridScreenLogoOffsetSD_X  = "0"
    theme.GridScreenLogoOffsetSD_Y  = "0"
	
    app.SetTheme(theme)
End Sub

