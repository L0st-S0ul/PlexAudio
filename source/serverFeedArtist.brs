Function initArtistList(baseServerURL, path) As Void
    conn = InitArtistFeedConnection(baseServerURL, path)
    m.Directories = conn.LoadArtistFeed(conn)
	m.ArtistNames = conn.GetArtistNames( m.Directories )
End Function

Function InitArtistFeedConnection(baseServerURL, path) As Object
    conn = CreateObject("roAssociativeArray")
	
	conn.BaseURL   = baseServerURL
	
	conn.BaseURL   = baseServerURL
	conn.ServerURL   = baseServerURL + path
	
    conn.Timer = CreateObject("roTimespan")

    conn.LoadArtistFeed    = load_artist_feed
    conn.GetArtistNames    = get_artist_names
	
    return conn
End Function

Function get_artist_names(directories As Object) As Dynamic
    ArtistNames = []
    for each directory in directories
        ArtistNames.Push(directory.Title)
    next
    return ArtistNames
End Function

Function load_artist_feed(conn As Object) As Dynamic
    http = NewHttp(conn.ServerURL)
	ArtistFeed = []
	
    Dbg("url: ", http.Http.GetUrl())

    m.Timer.Mark()
    response = http.GetToStringWithRetry()
    Dbg("Server Communication Took: ", m.Timer)

    m.Timer.Mark()
    xml=CreateObject("roXMLElement")
    if not xml.Parse(response) then
        print "Can't parse feed"
        return invalid
    endif
    Dbg("Parse Took: ", m.Timer)

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
        o = ParseArtistNode(conn.BaseURL, e)
		ArtistFeed.Push(o)
    next
    Dbg("XML Loading: ", m.Timer)

	return ArtistFeed
End Function

Function ParseArtistNode(BaseURL, xml As Object) As dynamic
    o = CreateObject("roAssociativeArray")

    'print "ParseArtistNode: " + xml.GetName()
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
			o.SDPosterURL = BaseURL + xml@thumb
			o.HDPosterURL = BaseURL + xml@thumb
		else if xml@type = "artist" then
			'o.SDPosterURL = BaseURL + xml@art
			'o.HDPosterURL = BaseURL + xml@art
			o.SDPosterURL = "file://pkg:/images/album-fanart.jpg"
			o.HDPosterURL = "file://pkg:/images/album-fanart.jpg"
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