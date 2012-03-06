' ********************************************************************
' **  Entry point for the Plex Audio client. 
' ********************************************************************

Sub Main()
	initTheme()
	
	screenFacade = CreateObject("roPosterScreen")
	screenFacade.show()

	SetMainAppIsRunning() 'if setting screensaver
	SaveCoverArtForScreenSaver("file://pkg:/images/sd.jpg","file://pkg:/images/hd.jpg")
	
	LaunchHomeScreen()
	
	screenFacade.showMessage("")
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

	theme.BackgroundColor = "#363636"
	theme.ButtonMenuNormalText = "#74777A"
	
	theme.GridScreenBackgroundColor = "#363636"
	
	theme.SpringboardTitleText = "#AAAEB3"
	theme.SpringboardArtistColor = "#74777A"
	theme.SpringboardAlbumColor = "#74777A"
	theme.SpringboardRuntimeColor = "#74777A"
	
    theme.OverhangOffsetSD_X = "0"
    theme.OverhangOffsetSD_Y = "0"
    theme.OverhangSliceSD = "pkg:/images/Screen_SD.png"

    theme.OverhangOffsetHD_X = "0"
    theme.OverhangOffsetHD_Y = "0"
    theme.OverhangSliceHD = "pkg:/images/Screen_HD.png"

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

