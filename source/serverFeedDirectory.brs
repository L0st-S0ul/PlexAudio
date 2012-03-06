Function initDirectoryList(baseServerURL, path) As Void
    conn = InitDirectoryFeedConnection(baseServerURL, path)
    m.Directories = conn.LoadDirectoryFeed(conn)
	m.DirectoryNames = conn.GetDirectoryNames( m.Directories )
End Function

Function InitDirectoryFeedConnection(baseServerURL, path) As Object
    conn = CreateObject("roAssociativeArray")
	
	conn.BaseURL   = baseServerURL
	if path <> "" then
		conn.ServerURL   = baseServerURL+"/library/sections/" + path
	else
		conn.ServerURL   = baseServerURL+"/library/sections"
	end if
	
    conn.Timer = CreateObject("roTimespan")

    conn.LoadDirectoryFeed    = load_Directory_feed
    conn.GetDirectoryNames    = get_Directory_names
	
    return conn
End Function

Function get_directory_names(directories As Object) As Dynamic
    DirectoryNames = []
    for each directory in directories
        DirectoryNames.Push(directory.Title)
    next
    return DirectoryNames
End Function

Function load_directory_feed(conn As Object) As Dynamic
    http = NewHttp(conn.ServerURL)
	DirectoryFeed = []
	
    Dbg("directory feed url: ", http.Http.GetUrl())

    m.Timer.Mark()
    response = http.GetToStringWithRetry()
    'Dbg("Server Communication Took: ", m.Timer)

    m.Timer.Mark()
    xml=CreateObject("roXMLElement")
    if not xml.Parse(response) then
        print "Can't parse feed"
        return invalid
    endif
    'Dbg("Parse Took: ", m.Timer)

    m.Timer.Mark()
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
    'print "number of directories: " + itostr(directories.Count())
    for each e in directories 
        o = ParseDirectoryNode(conn.BaseURL, e)
		DirectoryFeed.Push(o)
    next
    'Dbg("XML Loading: ", m.Timer)

	return DirectoryFeed
End Function

Function ParseDirectoryNode(BaseURL, xml As Object) As dynamic
    o = CreateObject("roAssociativeArray")

    'print "ParseDirectoryNode: " + xml.GetName()
    'PrintXML(xml, 5)

    'parse the curent node to determine the type. everything except
    'special categories are considered normal, others have unique types 
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
		else
			'o.ShortDescriptionLine2 = "(No summary available)"
		end if
        o.Type = xml@type
        o.Key = xml@key
		
		if xml@thumb <> invalid then
			o.SDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+xml@thumb, "124", "112")
			o.HDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+xml@thumb, "188", "188")
			'print "Directory Feed Url: ";o.HDPosterURL 
		else if xml@type = "artist" then
			'if xml@art <> invalid then
			'	o.SDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+xml@art, "110", "150")
			'	o.HDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+xml@art, "210", "270")
			'else
				o.SDPosterURL = "file://pkg:/images/album-fanart.jpg"
				o.HDPosterURL = "file://pkg:/images/album-fanart.jpg"
			'end if
		else if xml@type = "movie" then
			'o.SDPosterURL = BaseURL + xml@art
			'o.HDPosterURL = BaseURL + xml@art
			o.SDPosterURL = "file://pkg:/images/movie-fanart.jpg"
			o.HDPosterURL = "file://pkg:/images/movie-fanart.jpg"
		else if xml@type = "show" then
			'o.SDPosterURL = BaseURL + xml@art
			'o.HDPosterURL = BaseURL + xml@art
			o.SDPosterURL = "file://pkg:/images/show-fanart.jpg"
			o.HDPosterURL = "file://pkg:/images/show-fanart.jpg"
		end if
    else
        'print "ParseDirectoryNode skip: " + xml.GetName()
        return invalid
    endif

    return o
End Function