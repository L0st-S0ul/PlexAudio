Function InitTrackFeedConnection(baseServerURL, path) As Object
    conn = CreateObject("roAssociativeArray")
	
	conn.BaseURL   = baseServerURL
	conn.ServerURL   = baseServerURL + path
	
    conn.Timer = CreateObject("roTimespan")

    conn.LoadTrackFeed    = load_track_feed
    conn.GetTrackNames    = get_track_names
	
    return conn
End Function

Function get_track_names(directories As Object) As Dynamic
    TrackNames = []
    for each Track in directories
        TrackNames.Push(Track.Title)
    next
    return TrackNames
End Function

Function load_track_feed(conn As Object) As Dynamic
    http = NewHttp(conn.ServerURL)
	TrackFeed = CreateObject("roArray", 100, true)
	
    Dbg("track feed url: ", http.Http.GetUrl())

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
    if xml.Track = invalid then
        print "no track tag"
        return invalid
    endif

    if islist(xml.Track) = false then
        print "invalid feed body"
        return invalid
    endif

    if xml.Track[0].GetName() <> "Track" then
        print "no initial track tag"
        return invalid
    endif
	
    directories = xml.GetChildElements()
    'print "number of directories: " + itostr(directories.Count())
    for each e in directories 
        o = ParseTrackNode(conn.BaseURL, e, xml)
		TrackFeed.Push(o)
    next
    'Dbg("XML Loading: ", m.Timer)

	return TrackFeed
End Function

Function ParseTrackNode(BaseURL, xml As Object, parentxml As Object) As dynamic
    o = CreateObject("roAssociativeArray")

    'print "ParseTrackNode: " + xml.GetName()
    'PrintXML(xml, 5)

    'parse the curent node to determine the type. everything except
    'special categories are considered normal, others have unique types 
    if xml.GetName() = "Track" then	
		o.ContentType = "audio"
		o.Title = xml@title
		
		if parentxml@grandparentTitle <> invalid then
			o.Artist = parentxml@grandparentTitle
		else if xml@grandparentTitle <> invalid then
			o.Artist = xml@grandparentTitle
		else
			o.Artist = "Untitled"
		end if
		
		if parentxml@parentTitle <> invalid then
			o.Album = parentxml@parentTitle
		else if xml@parentTitle <> invalid then
			o.Album = xml@parentTitle
		else
			o.Album = "Album Unknown"
		end if
		
		if parentxml@parentYear <> invalid then
			o.AlbumYear = parentxml@parentYear
		else if xml@parentYear <> invalid then
			o.AlbumYear = xml@parentYear
		else
			o.AlbumYear = "Unknown"
		end if
		
		if xml@originalTitle <> invalid then
			if len(xml@originalTitle) > 180 then
				o.Description = left(xml@originalTitle, 180)+"..."
			else
				o.Description = xml@originalTitle
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
        'o.Key = xml@key
		
		o.Url = BaseURL + xml@key
		
		Media = xml.GetChildElements()

		element = Media[0]
		if element.GetName() = "Media" then	
			aCodec = element@audioCodec
			if aCodec = "mp3" OR aCodec = "wmv" OR aCodec = "aac" then
				Parts = element.GetChildElements()
				part = Parts[0]
				o.Key = part@key
				o.Codec = aCodec
				o.feedurl = BaseURL + part@key
				o.Duration = element@duration
				if xml@thumb <> invalid then
					o.SDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+xml@thumb, "124", "112")
					o.HDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+xml@thumb, "188", "188")
				else if parentxml@thumb <> invalid then
					o.SDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+parentxml@thumb, "124", "112")
					o.HDPosterURL = CreateServerImageResizeLocation(BaseURL, BaseURL+parentxml@thumb, "188", "188")
				else
					o.SDPosterURL = "file://pkg:/images/track-fanart.jpg"
					o.HDPosterURL = "file://pkg:/images/track-fanart.jpg"
				end if
				'print "Track Url: ";o.HDPosterURL 
			else
				o.SDPosterURL = "file://pkg:/images/track-na.jpg"
				o.HDPosterURL = "file://pkg:/images/track-na.jpg"
			end if
		end if
    else
        print "ParseTrackNode skip: " + xml.GetName()
        return invalid
    endif

    return o
End Function