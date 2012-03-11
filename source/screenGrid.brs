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
	
	' add in the more catagories option
	m.DirectoryNames.Push("More Catagories")
	
	performanceTimer.Mark()
    grid.SetupLists(m.DirectoryNames.Count()) 
	Print "### TIMER - GRID TIMER -- SetupLists took: " + itostr(performanceTimer.TotalMilliseconds())
	
	performanceTimer.Mark()
	grid.SetListNames(m.DirectoryNames)
	Print "### TIMER - GRID TIMER -- SetListNames took: " + itostr(performanceTimer.TotalMilliseconds())
	
	' Show the grid...
	grid.Show()
	
	keyCount = m.DirectoryNames.Count()
	contentArray = []
	rowCount = 0
		
	performanceTimer.Mark()
	rowCount = loadNextRow(grid, contentKey, m.Directories[rowCount], contentArray, rowCount)
	Print "### TIMER - ROW LOADER -- First row took: " + itostr(performanceTimer.TotalMilliseconds())
	
	performanceTimer.Mark()
	rowCount = loadNextRow(grid, contentKey, m.Directories[rowCount], contentArray, rowCount)
	Print "### TIMER - ROW LOADER -- row took: " + itostr(performanceTimer.TotalMilliseconds())
	
	rowCount = addMoreContentRow(grid, contentArray, rowCount)
	
	originalGrid = CreateGridStorage(content, myServer, m.DirectoryNames, contentArray)
	Print "### TIMER - TOTAL INITIAL GRID LOAD TIME: " + itostr(totalTimer.TotalMilliseconds())
	
	showCount = rowCount
	
	recreatingGrid = false
	
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
	
					recreateGridScreen(grid, originalGrid, selectedItem)
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
        end if
    end while
	return 0
End Function

Function loadNextRow(myGrid, contentKey, myContent, myContentArray, myRowCount) as Integer
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
            Title: "By Genre",
			Type: "sub",
            Description:"View your catalog by Genre",
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
	totalTimer = CreateObject("roTimespan")
	totalTimer.Mark()
	
	Print "##################################### RELOAD GRID SCREEN #####################################"
	
	performanceTimer = CreateObject("roTimespan")
	performanceTimer.Mark()

	directoryNames = originalGrid.DirectoryNames
	contentArray = originalGrid.ContentArray
	
    gridscreen.SetupLists(directoryNames.Count()) 
	gridscreen.SetListNames(directoryNames)

	rowCount = 0	
	
	performanceTimer.Mark()
	for each items in directoryNames
		gridscreen.setContentList(rowCount, contentArray[rowCount])
		
		' This app only showing top 2 rows for now...
		if originalSelection.RowNumber = rowCount then
			gridscreen.SetFocusedListItem(originalSelection.RowNumber, originalSelection.ItemNumber)
		end if
		rowCount = rowCount + 1
	next
	
	Print "### TIMER - RELOAD GRID TIMER -- Reloading Grid took: " + itostr(performanceTimer.TotalMilliseconds())
	
	' Show the grid...
	gridscreen.Show()
End Function



