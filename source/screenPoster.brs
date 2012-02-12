'* Displays the content in a poster screen. Can be any content type.
Function showPosterScreen(content, originalSource, selectedItem) As Integer
	retrieving = CreateObject("roOneLineDialog")
	retrieving.SetTitle("Retrieving ...")
	retrieving.ShowBusyAnimation()
	retrieving.Show()
	
	Print "##################################### CREATE POSTER SCREEN #####################################"
	
	port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
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
	else if content.Type = "artist" then
		myConn = InitArtistFeedConnection(myServer, contentKey)
		myContent = myConn.LoadArtistFeed(myConn)
	else
		' assume it's a tracking listing for now...
		myConn = InitTrackFeedConnection(myServer, contentKey)
		myContent = myConn.LoadTrackFeed(myConn)
	end if
			
    screen.SetContentList(myContent)
	
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                selected = myContent[msg.GetIndex()]
                contentType = selected.ContentType
                if contentType = "audio" then
					SongList = CreateMp3SongList(myContent, currentTitle)
					Show_Audio_Screen(songlist.posteritems[msg.GetIndex()], "Songs")
                else
                	showNextPosterScreen(currentTitle, selected)
                end if
            else if msg.isScreenClosed() then
				Print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLOSE POSTER SCREEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
				' if we are going back to the grid then recreate it to get around the display "bug"
				if type(originalSource) = "roAssociativeArray" then
					recreateGridScreen(originalSource, selectedItem)
				end if
				
                return -1
            end if
        end if
    end while
    return 0
End Function

Function showNextPosterScreen(currentTitle, selected As Object) As Dynamic
    if validateParam(selected, "roAssociativeArray", "showNextPosterScreen") = false return -1
    showPosterScreen(selected, "", "")
    return 0
End Function

Sub Show_Audio_Screen(song as Object, prevLoc as string) As Integer
    Audio = AudioInit()
    picture = song.HDPosterUrl

	Print "##################################### CREATE AUDIO DETAIL SCREEN #####################################"
	
    o = CreateObject("roAssociativeArray")
    o.HDPosterUrl = picture
    o.SDPosterUrl = picture
    o.Title = song.shortdescriptionline1
    o.Description = song.shortdescriptionline2
    o.contenttype = "episode"
	
    if (song.artist > "")
        o.Description = o.Description + chr(10) + "by: " + song.artist
    end if
	
    scr = create_springboard(Audio.port, prevLoc)
    scr.ReloadButtons(2) 'set buttons for state "playing"
    scr.screen.SetTitle("Screen Title")

    ' SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
    scr.screen.SetContent(o)
    scr.Show()

    ' start playing
    print "Starting Song Playback:";song.feedurl
    Audio.setupSong(song.feedurl, song.streamformat)
    Audio.audioplayer.setNext(0)
    Audio.setPlayState(2)		' start playing
	
    while true
        msg = Audio.getMsgEvents(20000, "roSpringboardScreenEvent")

        if type(msg) = "roAudioPlayerEvent"  then	' event from audio player
            if msg.isStatusMessage() then
                message = msg.getMessage()
                if message = "end of playlist"
                    print "end of playlist (obsolete status msg event)"
                end if
            else if msg.isListItemSelected() then
                print "starting song:"; msg.GetIndex()
            else if msg.isRequestSucceeded()
                print "ending song:"; msg.GetIndex()
                audio.setPlayState(0)	' stop the player, wait for user input
                scr.ReloadButtons(0)    ' set button to allow play start
            else if msg.isRequestFailed()
                print "failed to play song:"; msg.GetData()
            else if msg.isFullResult()
                print "FullResult: End of Playlist"
            else if msg.isPaused()
                print "Paused"
            else if msg.isResumed()
                print "Resumed"
            else
                print "ignored event type:"; msg.GetData()
            end if
        else if type(msg) = "roSpringboardScreenEvent" then	' event from user
            if msg.isScreenClosed()
				Print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLOSE AUDIO DETAIL SCREEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                Audio.setPlayState(0)
                return -1
            end if
			
            if msg.isRemoteKeyPressed() then
                button = msg.GetIndex()
                print "Remote Key button = "; button
            else if msg.isButtonPressed() then
                button = msg.GetIndex()
                print "button index="; button
                if button = 1 'pause or resume
                    if Audio.isPlayState < 2	' stopped or paused?
                        if (Audio.isPlayState = 0)
                              Audio.audioplayer.setNext(0)
                        end if
						newstate = 2  ' now playing
					else 'started
                         newstate = 1 ' now paused
                    end if
                else if button = 2 ' stop
                    newstate = 0 ' now stopped
                end if
                audio.setPlayState(newstate)
                scr.ReloadButtons(newstate)
            end if
        end if
    end while
	return 0
End Sub

Function CreateMp3SongList( songContent, albumTitle ) as Object	
    aa = CreateObject("roAssociativeArray")
    aa.posteritems = CreateObject("roArray", songContent.count(), true)
    
	for each song in songContent
		a = CreateSong( song.Title, albumTitle, "artist", "mp3", song.feedurl, song.HDPosterURL)
		aa.posteritems.push(a)
	next
	
    return aa
End Function

Function CreatePosterItem(id as string, desc1 as string, desc2 as string) as Object
    item = CreateObject("roAssociativeArray")
    item.ShortDescriptionLine1 = desc1
    item.ShortDescriptionLine2 = desc2
    item.HDPosterUrl = "pkg:/images/" + id + "/Poster_Logo_HD.png"
    item.SDPosterUrl = item.HDPosterUrl
    return item
end Function

Function CreateSong(title as string, description as string, artist as string, streamformat as string, feedurl as string, imagelocation as string) as Object
    item = CreatePosterItem("", title, description)
    item.HDPosterUrl = imagelocation
    item.SDPosterUrl = imagelocation
    item.Artist = artist
    item.Title = title    ' Song name
    item.feedurl = feedurl
    item.streamformat = streamformat
    item.picture = item.HDPosterUrl      ' default audioscreen picture to PosterScreen Image
    return item
End Function