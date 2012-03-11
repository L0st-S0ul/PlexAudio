Function initSecondaryList(baseServerURL, path) As Void
    conn = InitSecondaryFeedConnection(baseServerURL, path)
    m.Secondaries = conn.LoadSecondaryFeed(conn)
	m.SecondaryNames = conn.GetSecondaryNames( m.Secondaries )
End Function

Function InitSecondaryFeedConnection(baseServerURL, path) As Object
    conn = CreateObject("roAssociativeArray")
	
	conn.BaseURL   = baseServerURL
	if path <> "" then
		conn.ServerURL   = baseServerURL+"/library/sections/" + path
	else
		conn.ServerURL   = baseServerURL+"/library/sections"
	end if
	
    conn.Timer = CreateObject("roTimespan")

    conn.LoadSecondaryFeed    = load_secondary_feed
    conn.GetSecondaryNames    = get_secondary_names
	
    return conn
End Function

Function get_secondary_names(directories As Object) As Dynamic
    SecondaryNames = []
    for each directory in directories
        SecondaryNames.Push(directory.Title)
    next
    return SecondaryNames
End Function

Function load_secondary_feed(conn As Object) As Dynamic
	http = CreateObject("roUrlTransfer")
    http.SetPort(CreateObject("roMessagePort"))
    http.SetUrl(conn.ServerURL)
    http.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    http.EnableEncodings(true)
    Print "Secondary feed url: ";http.GetUrl() 

	SecondaryFeed = []
	
    m.Timer.Mark()
    response = http.GetToString()
    Print "Server Communication Took: ";m.Timer.TotalMilliseconds()

    m.Timer.Mark()
    xml=CreateObject("roXMLElement")
    if not xml.Parse(response) then
        print "Can't parse feed"
        return invalid
    endif
    Print "Parse Took: ";m.Timer.TotalMilliseconds()

    m.Timer.Mark()
    if xml.Directory = invalid then
        print "no secondary directories tag"
        return invalid
    endif

    if islist(xml.Directory) = false then
        print "invalid feed body"
        return invalid
    endif

    if xml.Directory[0].GetName() <> "Directory" then
        print "no initial secondary directory tag"
        return invalid
    endif
	
    directories = xml.GetChildElements()
    Print "number of secondary directories: " + itostr(directories.Count())
    for each e in directories 
		o = ParseSecondaryNode(conn.BaseURL, e)
		SecondaryFeed.Push(o)
    next
    Print "XML Loading: ";m.Timer.TotalMilliseconds()

	return SecondaryFeed
End Function

Function ParseSecondaryNode(BaseURL, xml As Object) As dynamic
	'performanceTimer = CreateObject("roTimespan")
	'performanceTimer.Mark()
		
    o = CreateObject("roAssociativeArray")

    'print "ParseSecondaryNode: " + xml.GetName()
    'PrintXML(xml, 5)

    if xml.GetName() = "Directory" then	
		o.ContentType = "series"

		o.Title = xml@title		

		if xml@summary <> invalid then
			if len(xml@summary) > 180 then
				o.Description = left(xml@summary, 180)+"..."
			else
				o.Description = xml@summary
			end if
		else
			o.Description = "(No summary available)"
		end if
		
		o.ShortDescriptionLine1 = xml@title
		if xml@summary <> invalid then
			if len(xml@summary) > 180 then
				o.ShortDescriptionLine2 = left(xml@summary, 180)+"..."
			else
				o.ShortDescriptionLine2 = xml@summary
			end if
		end if
		
        o.Type = xml@type
        o.Key = xml@key
		
		if xml@thumb <> invalid then
			o.SDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+xml@thumb, "124", "112")
			o.HDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+xml@thumb, "188", "188")
		else if xml@type = "artist" then
			o.SDPosterURL = "file://pkg:/images/album-fanart.jpg"
			o.HDPosterURL = "file://pkg:/images/album-fanart.jpg"
		else if xml@type = "movie" then
			o.SDPosterURL = "file://pkg:/images/movie-fanart.jpg"
			o.HDPosterURL = "file://pkg:/images/movie-fanart.jpg"
		else if xml@type = "show" then
			o.SDPosterURL = "file://pkg:/images/show-fanart.jpg"
			o.HDPosterURL = "file://pkg:/images/show-fanart.jpg"
		end if
    else
        return invalid
    end if

	'Print "Loading Track Metadata Took: ";performanceTimer.TotalMilliseconds()
    return o
End Function

' load a feed from and xml string instead of going out to get it
Function LoadSubFeed(xmlString)
	DirectoryFeed = []
	
	myServer = RegRead("server", "preference")
	
	'print "XML: "; xmlString
	
    xml=CreateObject("roXMLElement")
    if not xml.Parse(xmlString) then
        print "Can't parse feed"
        return invalid
    endif

    if xml.Directory = invalid then
        print "no directories tag"
        return invalid
    endif

    if islist(xml.Directory) = false then
        print "invalid feed body"
        return invalid
    endif

    if xml.Directory[0].GetName() <> "Directory" then
        print "no initial directory tag"
        return invalid
    endif
	
    directories = xml.GetChildElements()
    print "number of directories: " + itostr(directories.Count())
    for each e in directories 
		' only do artist or albums. 
		if e@type = "artist" OR e@type = "album" OR e@key = "all" OR e@key = "albums" then
			o = ParseDirectoryNode(myServer, e)
			DirectoryFeed.Push(o)
		end if
    next

	return DirectoryFeed
End Function