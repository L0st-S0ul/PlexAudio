'*****************************************************************
'**  Home screen: the entry display of the application
'**
'*****************************************************************

Function preShowHomeScreen() As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.SetListStyle("flat-category")
    screen.setListDisplayMode("zoom-to-fill")
    return screen
End Function

Function showHomeScreen(screen, server) As Integer
    screenFacade = CreateObject("roPosterScreen")
    screenFacade.show()
	
	Print "##################################### CREATE HOME SCREEN #####################################"
	
	sectionList = CreateObject("roArray", 10, true)
	
	if server <> invalid AND server <> "" then
		print "Configured Server: ";server
		initDirectoryList(server, "")
		for each directory in m.Directories
			if directory.type = "artist" then
				sectionList.Push(directory)
			end if
		next
	end if
		
	'** Prefs
	prefs = CreateObject("roAssociativeArray")
	prefs.server = m
    prefs.sourceUrl = ""
	prefs.ContentType = "series"
	prefs.Key = "prefs"
	prefs.Title = "Preferences"
	prefs.ShortDescriptionLine1 = "Preferences"
	prefs.SDPosterURL = "file://pkg:/images/prefs.jpg"
	prefs.HDPosterURL = "file://pkg:/images/prefs.jpg"
	sectionList.Push(prefs)
	
    screen.SetContentList(sectionList)
    screen.Show()
	
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                section = sectionList[msg.GetIndex()]
				if section.key = "prefs" then
					screen.Close()
					Preferences() 
					screenFacade.Close()
					' exit so we don't hit the close
					exit while
				else
					screen.Close()
					showGridScreen(section)
					screenFacade.Close()
					' exit so we don't hit the close
					exit while
				end if
            else if msg.isScreenClosed() then
				Print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLOSE HOME SCREEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
				screenFacade.Close()
                exit while
            end if
        end if
    end while
	
	return 0
End Function

Function Preferences()
	port = CreateObject("roMessagePort") 
	dialog = CreateObject("roMessageDialog") 
	dialog.SetMessagePort(port)
	dialog.SetMenuTopLeft(true)
	dialog.EnableBackButton(false)
	
	manifest = ReadAsciiFile("pkg:/manifest")
    lines = manifest.Tokenize(chr(10))
    aa = {}
    for each line in lines
        entry = line.Tokenize("=")
        aa.AddReplace(entry[0],entry[1])
    end for

	dialog.SetTitle("Preferences v."+aa["version"])
	dialog.AddButton(1, "Plex Media Servers")
	dialog.AddButton(4, "Close Preferences")
	dialog.Show()
	while true 
		msg = wait(0, dialog.GetMessagePort()) 
		if type(msg) = "roMessageDialogEvent"
			if msg.isScreenClosed() then
				LaunchHomeScreen()
			else if msg.isButtonPressed() then
				if msg.getIndex() = 1 then
					ConfigureMediaServers()
        			dialog.close()
        		else if msg.getIndex() = 4 then
        			dialog.close()
        		end if
			end if 
		end if
	end while
End Function

Function ConfigureMediaServers()
	port = CreateObject("roMessagePort") 
	dialog = CreateObject("roMessageDialog") 
	dialog.SetMessagePort(port)
	dialog.SetMenuTopLeft(true)
	dialog.EnableBackButton(false)
	dialog.SetTitle("Plex Media Server") 
	dialog.setText("Manage Plex Media Server")
	
	dialog.AddButton(1, "Close manage servers dialog")
	dialog.AddButton(2, "Add server manually")
	dialog.AddButton(3, "Remove Server")
		
	dialog.Show()
	while true 
		msg = wait(0, dialog.GetMessagePort()) 
		if type(msg) = "roMessageDialogEvent"
			if msg.isScreenClosed() then
				'print "Manage server closed event"
				LaunchHomeScreen()
				dialog.close()
				exit while
			else if msg.isButtonPressed() then
				if msg.getIndex() = 1 then
					'print "Closing dialog"
				else if msg.getIndex() = 2 then
					address = AddServerManually()
					print "Returned from add server manually: ";address
					if address <> invalid then
						RegWrite("server", "http://"+address+":32400", "preference")
					end if
        		else if msg.getIndex() = 3 then
        			RegWrite("server", "", "preference")
					myServer = RegRead("server", "preference")
        		end if
        		dialog.close()
				exit while
			end if 
		end if
	end while
End Function

Function AddServerManually()
	port = CreateObject("roMessagePort") 
	keyb = CreateObject("roKeyboardScreen")    
	keyb.SetMessagePort(port)
    keyb.SetDisplayText("Enter Host Name or IP without http:// or :32400")
	keyb.SetMaxLength(80)
	keyb.AddButton(1, "Done") 
	keyb.AddButton(2, "Close")
	keyb.setText("")
	keyb.Show()
	while true 
		msg = wait(0, keyb.GetMessagePort()) 
		if type(msg) = "roKeyboardScreenEvent"
			if msg.isScreenClosed() then
				'print "Exiting keyboard dialog screen"
			   	return invalid
				exit while
			else if msg.isButtonPressed() then
				if msg.getIndex() = 1 then
					return keyb.GetText()
       			end if
       			return invalid
				exit while
			end if 
		end if
	end while
End Function

Function LaunchHomeScreen()
	myServer = RegRead("server", "preference")
	screen=preShowHomeScreen()
	showHomeScreen(screen, myServer)
End Function