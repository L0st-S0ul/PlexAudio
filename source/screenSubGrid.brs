Function displaySubGridScreen(activeGrid, contentList, myParentKey)
	' Close the active grid, we will have to recreate it...				
	Print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLOSED ACTIVE GRID SCREEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	activeGrid.Close()
	showSubGridScreen(contentList, myParentKey)
End Function

Function showSubGridScreen(content, myParentKey) As Integer
    if validateParam(content, "roAssociativeArray", "showGridScreen") = false return -1			

	totalTimer = CreateObject("roTimespan")
	totalTimer.Mark()
		
	Print "##################################### CREATE SUB GRID SCREEN #####################################"
	subPort = CreateObject("roMessagePort")
    subGrid = CreateObject("roGridScreen")
	subGrid.SetMessagePort(subPort)
	
	subGrid.SetDisplayMode("scale-to-fit")
	subGrid.SetUpBehaviorAtTopRow("exit")
	
	performanceTimer = CreateObject("roTimespan")
	
	contentKey = content.key
	currentTitle = content.Title
	
	performanceTimer.Mark()
	myServer = RegRead("server", "preference")
	initSecondaryList(myServer, myParentKey + "/" + contentKey)
	Print "### TIMER - SUB GRID TIMER -- initSecondaryList took: " + itostr(performanceTimer.TotalMilliseconds())
	
	' Show the grid...
	subGrid.SetupLists(m.SecondaryNames.Count()) 
	subGrid.SetListNames(m.SecondaryNames)
	
	keyCount = m.SecondaryNames.Count()
	
	contentArray = []
	identityArray = []
	httpArray = []
	
	rowCount = 0
	loaded = 0
	
	showCount = m.Secondaries.Count()
	
	performanceTimer.Mark()

	httpArray[rowCount] = createNewNetworkConnection(subPort)
	rowCount = loadNextSubRow(httpArray[rowCount], myParentKey, contentKey, m.Secondaries[rowCount], identityArray, rowCount)
	
	'httpArray[rowCount] = createNewNetworkConnection(subPort)
	'rowCount = loadNextSubRow(httpArray[rowCount], myParentKey, contentKey, m.Secondaries[rowCount], identityArray, rowCount)

	Print "### TIMER - http object creation: " + itostr(performanceTimer.TotalMilliseconds())
	
	recreatingGrid = false
	
	' Show the grid...
	subGrid.Show()
	
	while true
        msg = wait(1, subPort)
		
        if type(msg) = "roGridScreenEvent" then
            if msg.isListItemSelected() then
				row = msg.GetIndex()
				if row < rowCount then
					recreatingGrid = true
					
					selection = msg.getData()
					selectedItem = CreateFocusItem(row, selection)
					
					contentSelected = contentArray[row][selection]
					contentType = contentSelected.ContentType
					
					cType = contentSelected.Type
					if cType = "album" then
						displayPosterScreen(subGrid, contentSelected)
					else if cType = "artist" then
						displayPosterScreen(subGrid, contentSelected)
					end if
					
					' when we come back recreate the gridscreen
					subGrid = CreateObject("roGridScreen")
					subGrid.SetMessagePort(subPort)
						
					subGrid.SetDisplayMode("scale-to-fit")
					subGrid.SetUpBehaviorAtTopRow("exit")
					
					' if we're fully loaded then let's go
					if loaded = showCount then
						recreateSubGridScreen(subGrid, subGridStorage, selectedItem)
					else ' we were not fully loaded so we need to start from scratch...
						Print "##################################### RELOAD GRID SCREEN FROM SCRATCH #####################################"
						subGrid.SetupLists(m.SecondaryNames.Count()) 
						subGrid.SetListNames(m.SecondaryNames)
						
						rowCount = 0	
						loaded = 0
					
						' Show the grid...
						subGrid.Show()
					end if
				end if
            else if msg.isScreenClosed() then
				if recreatingGrid = false then
					Print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLOSE SUB GRID SCREEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
					Print "closed Secondary gridscreen: " + currentTitle
					return -1
				else
					' ignore the case when the grid is being recreated and reset the system
					recreatingGrid = false
				end if
            end if
		else if type(msg) = "roUrlEvent" then			
			if msg.GetInt() = 1 then
				myIdentity = msg.GetSourceIdentity()
				myString = msg.GetString()
				
				' find the row to put it in...
				rowNum = 0
				for each item in identityArray
					if item = myIdentity then
						contentArray[rowNum] = LoadSubFeed(myString)
						subGrid.setContentList(rowNum, contentArray[rowNum])
						loaded = loaded + 1
					end if
					rowNum = rowNum + 1
				next
				
				if loaded = showCount then
					subGridStorage = CreateGridStorage(content, myServer, m.SecondaryNames, contentArray)
					Print "### TIMER - TOTAL SUB GRID LOAD TIME: " + itostr(totalTimer.TotalMilliseconds())
				end if 
			end if
		else
			if rowcount <> showCount then
				httpArray[rowCount] = createNewNetworkConnection(subPort)
				rowCount = loadNextSubRow(httpArray[rowCount], myParentKey, contentKey, m.Secondaries[rowCount], identityArray, rowCount)
			end if
        end if
    end while
	return 0
End Function

Function loadNextSubRow(myHttp, myParentKey, contentKey, myContent, identityArray, myRowCount) as Integer
	myServer = RegRead("server", "preference")
	
    myHttp.SetUrl(myServer+"/library/sections/" + myParentKey + "/" + contentKey + "/" + myContent.key)
    myHttp.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    myHttp.EnableEncodings(true)
	
    Print "Experimental feed url: ";myHttp.GetUrl() 
	
	myHttp.AsyncGetToString()
	identityArray[myRowCount] = myHttp.GetIdentity()

	myRowCount = myRowCount + 1
	return myRowCount
End Function


Function recreateSubGridScreen(gridscreen, originalGrid, originalSelection) As Object 			
	Print "##################################### RELOAD GRID SCREEN #####################################"
	
	performanceTimer = CreateObject("roTimespan")
	performanceTimer.Mark()
	
	directoryNames = originalGrid.DirectoryNames
	contentArray = originalGrid.ContentArray
	
    gridscreen.SetupLists(directoryNames.Count()) 
	gridscreen.SetListNames(directoryNames)
	
	rowCount = 0		
	
	' Show the grid...
	gridscreen.Show()
	
	for each items in directoryNames
		gridscreen.setContentList(rowCount, contentArray[rowCount])
		
		' This app only showing top 2 rows for now...
		if originalSelection.RowNumber = rowCount then
			gridscreen.SetFocusedListItem(originalSelection.RowNumber, originalSelection.ItemNumber)
		end if
		rowCount = rowCount + 1
	next
	
	Print "### TIMER - RELOAD GRID TIMER -- Reloading Grid took: " + itostr(performanceTimer.TotalMilliseconds())
End Function
