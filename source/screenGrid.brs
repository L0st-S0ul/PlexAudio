Function showGridScreen(content) As Integer
    if validateParam(content, "roAssociativeArray", "showGridScreen") = false return -1			
		
	totalTimer = CreateObject("roTimespan")
	totalTimer.Mark()
	
	Print "##################################### CREATE GRID SCREEN #####################################"
	m.port = CreateObject("roMessagePort")
    grid = CreateObject("roGridScreen")
	grid.SetMessagePort(m.port)
		
    grid.SetDisplayMode("scale-to-fit")
	grid.SetUpBehaviorAtTopRow("exit")
	
	performanceTimer = CreateObject("roTimespan")
	
	contentKey = content.key
	currentTitle = content.Title
	
	performanceTimer.Mark()
	myServer = RegRead("server", "preference")
	initDirectoryList(myServer, contentKey)
	Print "### TIMER - GRID TIMER -- initDirectoryList took: " + itostr(performanceTimer.TotalMilliseconds())
	
	' add in the more categories option
	m.DirectoryNames.Push("Categories")
	
    grid.SetupLists(m.DirectoryNames.Count()) 
	grid.SetListNames(m.DirectoryNames)

	keyCount = m.DirectoryNames.Count()
	
	contentArray = []
	identityArray = []
	httpArray = []
	
	rowCount = 0
	loaded = 0
	
	showCount =  m.Directories.Count()
		
	' let's block on the artists first. Make sure it's loaded before showing the screen.
	performanceTimer.Mark()
	rowCount = loadBlockingRow(grid, contentKey, m.Directories[rowCount], contentArray, rowCount)
	Print "### TIMER - ROW LOADER -- First row took: " + itostr(performanceTimer.TotalMilliseconds())
	
	performanceTimer.Mark()
	
	httpArray[rowCount] = createNewNetworkConnection(m.port)
	rowCount = loadNextRow(httpArray[rowCount], contentKey, m.Directories[rowCount], identityArray, rowCount)
	
	httpArray[rowCount] = createNewNetworkConnection(m.port)
	rowCount = loadNextRow(httpArray[rowCount], contentKey, m.Directories[rowCount], identityArray, rowCount)
	
	' add the more content row...
	rowCount = addMoreContentRow(grid, contentArray, rowCount)
	
	Print "### TIMER - INITIAL HTTP OBJECT CREATION: " + itostr(performanceTimer.TotalMilliseconds())
		
	recreatingGrid = false
	
	' Show the grid...
	grid.Show()
					
	while true
        msg = wait(0, m.port)
		
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
						displayPosterScreen(grid, contentSelected)
					else if cType = "artist" then
						displayPosterScreen(grid, contentSelected)
					else if cType = "sub" then
						displaySubGridScreen(grid, contentSelected, contentKey)
					end if
					
					' when we come back recreate the gridscreen
					grid = CreateObject("roGridScreen")
					grid.SetMessagePort(m.port)
						
					grid.SetDisplayMode("scale-to-fit")
					grid.SetUpBehaviorAtTopRow("exit")
	
					' if we're fully loaded then let's go
					if loaded = showCount-1 then
						recreateGridScreen(grid, originalGrid, selectedItem)
					else ' we were not fully loaded so we need to start from scratch...
						Print "##################################### RELOAD GRID SCREEN FROM SCRATCH #####################################"
						grid.SetupLists(m.DirectoryNames.Count()) 
						grid.SetListNames(m.DirectoryNames)
						
						rowCount = 0	
						loaded = 0

						rowCount = loadBlockingRow(grid, contentKey, m.Directories[rowCount], contentArray, rowCount)
						performanceTimer.Mark()
						
						httpArray[rowCount] = createNewNetworkConnection(m.port)
						rowCount = loadNextRow(httpArray[rowCount], contentKey, m.Directories[rowCount], identityArray, rowCount)
						
						httpArray[rowCount] = createNewNetworkConnection(m.port)
						rowCount = loadNextRow(httpArray[rowCount], contentKey, m.Directories[rowCount], identityArray, rowCount)
						
						' add the more content row...
						rowCount = addMoreContentRow(grid, contentArray, rowCount)
	
						' Show the grid...
						grid.Show()
					end if
				end if
            else if msg.isScreenClosed() then
				if recreatingGrid = false then
					Print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLOSE GRID SCREEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
					Print "closed initial gridscreen: " + currentTitle
					LaunchHomeScreen()
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
						grid.setContentList(rowNum, contentArray[rowNum])
						loaded = loaded + 1
					end if
					rowNum = rowNum + 1
				next
				
				if loaded = showCount-1 then
					originalGrid = CreateGridStorage(content, myServer, m.DirectoryNames, contentArray)
					
					Print "### TIMER - TOTAL GRID LOADING TIME: " + itostr(totalTimer.TotalMilliseconds())
				end if 
			end if
		else
			' Currently we're not loading more...
			'if rowcount <> showCount then
			'	httpArray[rowCount] = createNewNetworkConnection(subPort)
			'	rowCount = loadNextSubRow(httpArray[rowCount], myParentKey, contentKey, m.Secondaries[rowCount], identityArray, rowCount)
			'end if
        end if
    end while
	return 0
End Function

Function loadNextRow(myHttp, contentKey, myContent, identityArray, myRowCount) as Integer
	myServer = RegRead("server", "preference")
		
    myHttp.SetUrl(myServer+"/library/sections/"+contentKey+"/"+myContent.key)
    myHttp.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    myHttp.EnableEncodings(true)
	
    Print "Experimental feed url: ";myHttp.GetUrl() 
	
	myHttp.AsyncGetToString()
	identityArray[myRowCount] = myHttp.GetIdentity()

	myRowCount = myRowCount + 1
	return myRowCount
End Function

Function loadBlockingRow(myGrid, contentKey, myContent, myContentArray, myRowCount) as Integer
	performanceTimer = CreateObject("roTimespan")

	performanceTimer.Mark()

	myServer = RegRead("server", "preference")
	myConn = InitDirectoryFeedConnection(myServer, contentKey+"/"+myContent.key)
	myDirectories = myConn.LoadDirectoryFeed(myConn)
	Print "### TIMER - PAGE CONTENT TIMER -- Getting Row Content took: " + itostr(performanceTimer.TotalMilliseconds())

	myContentArray[myRowCount] = []

	performanceTimer.Mark()
	itemCount = 0
	for each item in myDirectories
		myContentArray[myRowCount][itemCount] = item
		itemCount = itemCount + 1
	next

	if itemCount > 0 then
		myGrid.setContentList(myRowCount, myContentArray[myRowCount])
	else
		myGrid.setListVisible(myRowCount, false)
	end if

	myRowCount = myRowCount + 1

	return myRowCount
End Function

Function addMoreContentRow(myGrid, myContentArray, myRowCount) as Integer
	' now add the custom guys
	contentList = [
		{
            Title: "By Collection",
			Type: "sub",
            Description:"View your catalog by collections",
			Key: "collection",
            HDPosterUrl:"file://pkg:/images/collections.png",
            SDPosterUrl:"file://pkg:/images/collections.png",
        }
        {
            Title: "By Genre",
			Type: "sub",
            Description:"View your catalog by genre",
			Key: "genre",
            HDPosterUrl:"file://pkg:/images/genre.jpg",
            SDPosterUrl:"file://pkg:/images/genre.jpg",
        }
        {
            Title: "By Decade",
            Description:"View your catalog by the decade the album was released",
			Type: "sub",
			Key: "decade",
            HDPosterUrl:"file://pkg:/images/decade.jpg",
            SDPosterUrl:"file://pkg:/images/decade.jpg",
        }
        {
            Title: "By Year",
            Description:"View your catalog by year the album was released",
			Type: "sub",
			Key: "year",
            HDPosterUrl:"file://pkg:/images/year.jpg",
            SDPosterUrl:"file://pkg:/images/year.jpg",
        }
	]
	
	myContentArray[myRowCount] = contentList
	
	myGrid.setContentList(myRowCount, myContentArray[myRowCount])
	myRowCount = myRowCount + 1
	
	return myRowCount
End Function

Function recreateGridScreen(gridscreen, originalGrid, originalSelection) As Object 	
	Print "##################################### RELOAD GRID SCREEN #####################################"
	
	totalTimer = CreateObject("roTimespan")
	totalTimer.Mark()
		
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



