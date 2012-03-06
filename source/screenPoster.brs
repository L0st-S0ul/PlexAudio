'* Displays the content in a poster screen. Can be any content type.
Function showPosterScreen(content, originalSource, selectedItem) As Integer	
	Print "##################################### CREATE POSTER SCREEN #####################################"
	
	retrieving = CreateObject("roOneLineDialog")
	retrieving.SetTitle("Retrieving ...")
	retrieving.ShowBusyAnimation()
	retrieving.Show()
	
	posterPort=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(posterPort)
    screen.SetListStyle("arced-square")
    screen.setListDisplayMode("scale-to-fit")
	
	print "show poster screen for key ";content.key
	screen.Show()
	retrieving.Close()

	server = content.server
	
	contentKey = content.key
	currentTitle = content.Title

	myServer = RegRead("server", "preference")
	
	if content.Type = "album" then
		myConn = InitTrackFeedConnection(myServer, contentKey)
		myContent = myConn.LoadTrackFeed(myConn)
		screen.setBreadcrumbText(currentTitle, myContent[0].Artist)
	else if content.Type = "artist" then
		myConn = InitArtistFeedConnection(myServer, contentKey)
		myContent = myConn.LoadArtistFeed(myConn)
		screen.setBreadcrumbText("", currentTitle)
	else
		' assume it's a tracking listing for now...
		myConn = InitTrackFeedConnection(myServer, contentKey)
		myContent = myConn.LoadTrackFeed(myConn)
		screen.setBreadcrumbText(currentTitle, myContent[0].Artist)
	end if
	
	screen.setBreadcrumbEnabled(true)
    screen.SetContentList(myContent)
	
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                selected = myContent[msg.GetIndex()]
                contentType = selected.ContentType
                if contentType = "audio" then
					if selected.Codec <> "invalid" then
						SongList = CreateMp3SongList(myContent, currentTitle)
						showAudioScreen(songlist.posteritems, msg.GetIndex(), currentTitle, screen)
					end if
                else
                	showNextPosterScreen(currentTitle, selected)
                end if
            else if msg.isScreenClosed() then
				Print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLOSE POSTER SCREEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
				' if we are going back to the grid then recreate it to get around the display "bug"
				if type(originalSource) = "roAssociativeArray" then
					recreateGridScreen(originalSource, selectedItem)
				end if
				
				screen = invalid
                return -1
            end if
		else
			Print "poster screen loop"
        end if
    end while
    return 0
End Function

Function showNextPosterScreen(currentTitle, selected As Object) As Dynamic
    if validateParam(selected, "roAssociativeArray", "showNextPosterScreen") = false return -1
    showPosterScreen(selected, "", "")
    return 0
End Function

Function CreateMp3SongList( songContent, albumTitle ) as Object	
    aa = CreateObject("roAssociativeArray")
    aa.posteritems = CreateObject("roArray", songContent.count(), true)
    
	print "Album Title: ";albumTitle
	
	for each song in songContent
		a = CreateSong( song.Title, albumTitle, song.Artist, song.Album, song.AlbumYear, song.Codec, song.feedurl, song.HDPosterURL, song.Duration)
		aa.posteritems.push(a)
	next
	
    return aa
End Function

Function CreateSong(title as string, description as string, artist as string, album as string, year as string, streamformat as string, feedurl as string, imagelocation as string, duration) as Object
	item = CreateObject("roAssociativeArray")
	item.ShortDescriptionLine1 = title
    item.ShortDescriptionLine2 = description
    item.HDPosterUrl = imagelocation
    item.SDPosterUrl = imagelocation
    item.Artist = artist
	item.Album = album
	item.Year = year
    item.Title = title    ' Song name
	item.Length = int(val(duration)/1000)
    item.Url = feedurl
    item.StreamFormat = streamformat
    item.picture = item.HDPosterUrl 
    return item
End Function