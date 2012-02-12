Function showGridScreen(content) As Integer
    if validateParam(content, "roAssociativeArray", "showGridScreen") = false return -1			

	retrieving = CreateObject("roOneLineDialog")
	retrieving.SetTitle("Retrieving ...")
	retrieving.ShowBusyAnimation()
	retrieving.Show()
	
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
	
	performanceTimer.Mark()
    grid.SetupLists(m.DirectoryNames.Count()) 
	Print "### TIMER - GRID TIMER -- SetupLists took: " + itostr(performanceTimer.TotalMilliseconds())
	
	performanceTimer.Mark()
	grid.SetListNames(m.DirectoryNames)
	Print "### TIMER - GRID TIMER -- SetListNames took: " + itostr(performanceTimer.TotalMilliseconds())
	
	' Show the grid...
	grid.Show()
	retrieving.Close()
	
	keyCount = m.DirectoryNames.Count()
	contentArray = []
	rowCount = 0	
	
	performanceTimer.Mark()
	rowCount = loadNextRow(grid, contentKey, m.Directories[rowCount], contentArray, rowCount)
	Print "### TIMER - ROW LOADER -- First row took: " + itostr(performanceTimer.TotalMilliseconds())
	
	performanceTimer.Mark()
	rowCount = loadNextRow(grid, contentKey, m.Directories[rowCount], contentArray, rowCount)
	
	Print "### TIMER - ROW LOADER -- row took: " + itostr(performanceTimer.TotalMilliseconds())
	Print "### TIMER - TOTAL INITIAL GRID LOAD TIME: " + itostr(totalTimer.TotalMilliseconds())
	
	originalGrid = CreateGridStorage(content, myServer, m.DirectoryNames, contentArray)
	
	while true
        msg = wait(1, m.port)
		
        if type(msg) = "roGridScreenEvent" then
            if msg.isListItemSelected() then
				'print "Selected msg: ";msg.GetData()
				row = msg.GetIndex()
				if row < rowCount then
					selection = msg.getData()
					selectedItem = CreateFocusItem(row, selection)
					
					contentSelected = contentArray[row][selection]
					contentType = contentSelected.ContentType
					cType = contentSelected.Type
					Print "contentType: " + cType
					' play media
					if cType = "album" then
						' Close the grid, we will have to recreate it...
						grid.Close()
						displayPosterScreen(contentSelected, originalGrid, selectedItem)
					else if cType = "artist" then
						' Close the grid, we will have to recreate it...
						grid.Close()
						displayPosterScreen(contentSelected, originalGrid, selectedItem)
					end if
				end if
            else if msg.isScreenClosed() then
				Print "prepare to close gridscreen: " + currentTitle
				Print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLOSE GRID SCREEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                return -1
            end if
		else
			'print "Unknown event: ";msg
        end if
		
		if rowCount < keyCount
			grid.setListVisible(rowCount, false)
			rowCount = rowCount + 1
		end if
    end while
	return 0
End Function

Function recreateGridScreen(originalGrid, originalSelection) As Integer	
	retrieving = CreateObject("roOneLineDialog")
	retrieving.SetTitle("Retrieving ...")
	retrieving.ShowBusyAnimation()
	retrieving.Show()
	
	totalTimer = CreateObject("roTimespan")
	totalTimer.Mark()
	
	Print "##################################### RECREATE GRID SCREEN #####################################"
	m.port = CreateObject("roMessagePort")
    grid = CreateObject("roGridScreen")
	grid.SetMessagePort(m.port)
		
    grid.SetDisplayMode("scale-to-fit")
	grid.SetUpBehaviorAtTopRow("exit")
	
	performanceTimer = CreateObject("roTimespan")
	performanceTimer.Mark()
	
	contentKey = originalGrid.Content.key
	currentTitle = originalGrid.Content.Title
	myServer = originalGrid.Server
	directoryNames = originalGrid.DirectoryNames
	contentArray = originalGrid.ContentArray
		
    grid.SetupLists(directoryNames.Count()) 
	Print "### TIMER - GRID TIMER -- SetupLists took: " + itostr(performanceTimer.TotalMilliseconds())
	
	performanceTimer.Mark()
	grid.SetListNames(directoryNames)
	Print "### TIMER - GRID TIMER -- SetListNames took: " + itostr(performanceTimer.TotalMilliseconds())
	
	' Show the grid...
	grid.Show()
	retrieving.Close()
	
	keyCount = directoryNames.Count()
	rowCount = 0	
	
	performanceTimer.Mark()
	for each items in directoryNames
		grid.setContentList(rowCount, contentArray[rowCount])
		
		' This app only showing top 2 rows for now...
		if rowCount > 2
			grid.setListVisible(rowCount, false)
		end if
		
		rowCount = rowCount + 1
	next
		
	grid.SetFocusedListItem(originalSelection.RowNumber, originalSelection.ItemNumber)
	
	Print "### TIMER - TOTAL GRID RELOAD TIME: " + itostr(totalTimer.TotalMilliseconds())
		
	while true
        msg = wait(1, m.port)
		
        if type(msg) = "roGridScreenEvent" then
            if msg.isListItemSelected() then
				'print "Selected msg: ";msg.GetData()
				row = msg.GetIndex()
				if row < rowCount then
					selection = msg.getData()
					selectedItem = CreateFocusItem(row, selection)
					
					contentSelected = contentArray[row][selection]
					contentType = contentSelected.ContentType

					cType = contentSelected.Type
					Print "contentType: " + cType
					' play media
					if cType = "album" then
						' Close the grid, we will have to recreate it...
						grid.Close()
						displayPosterScreen(contentSelected, originalGrid, selectedItem)
					else if cType = "artist" then
						' Close the grid, we will have to recreate it...
						grid.Close()
						displayPosterScreen(contentSelected, originalGrid, selectedItem)
					end if
				end if
            else if msg.isScreenClosed() then
				Print "prepare to close gridscreen: " + currentTitle
				Print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLOSE GRID SCREEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                return -1
            end if
		else
			'print "Unknown event: ";msg
        end if
    end while
	return 0
End Function

Function CreateFocusItem(focusRow, focusItem) as Object
    item = CreateObject("roAssociativeArray")
    item.RowNumber = focusRow
	item.ItemNumber = focusItem
    return item
end Function

Function CreateGridStorage(oringinalContent, originalServer, originalDirectoryNames, originalContentArray) as Object
    item = CreateObject("roAssociativeArray")
    item.Content = oringinalContent
	item.Server = originalServer
	item.DirectoryNames = originalDirectoryNames
	item.ContentArray = originalContentArray
    return item
end Function

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

Function displayPosterScreen(contentList, originalSource, selectedItem)
	showPosterScreen(contentList, originalSource, selectedItem)
End Function

Function showNextGridScreen(currentTitle, selected As Object) As Dynamic
    if validateParam(selected, "roAssociativeArray", "showNextGridScreen") = false return -1
    showGridScreen(selected)
    return 0
End Function