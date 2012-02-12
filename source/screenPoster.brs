'* Displays the content in a poster screen. Can be any content type.
Function showPosterScreen(content, originalSource, selectedItem) As Integer	
	Print "##################################### CREATE POSTER SCREEN #####################################"
	retrieving = CreateObject("roOneLineDialog")
	retrieving.SetTitle("Retrieving ...")
	retrieving.ShowBusyAnimation()
	retrieving.Show()
	
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
					Show_Audio_Screen_For_Multi(songlist.posteritems, msg.GetIndex(), currentTitle)
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
	o.Length = song.Length
    o.contenttype = "episode"
	
    if (song.artist > "")
        o.Description = "Album: " + song.Album + chr(10) + "Artist: " + song.artist + chr(10) + "Year: " + song.year
    end if
	
    scr = create_springboard(Audio.port, prevLoc)
    scr.ReloadButtons(2) 'set buttons for state "playing"
    scr.screen.SetTitle("Screen Title")

    ' SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
    scr.screen.SetContent(o)
    scr.Show()

    ' start playing
    print "Starting Song Playback:";song.Url
    Audio.setupSong(song.Url, song.StreamFormat)
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
                print "playback started"
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

Sub Show_Audio_Screen_For_Multi(songs as Object, currentSelect, prevLoc as string) As Integer
    Audio = AudioInit()
    
	Print "##################################### CREATE AUDIO DETAIL SCREEN #####################################"
	picture = songs[currentSelect].HDPosterUrl
    o = CreateObject("roAssociativeArray")
    o.HDPosterUrl = picture
    o.SDPosterUrl = picture
    o.Title = songs[currentSelect].shortdescriptionline1
	o.Description = songs[currentSelect].shortdescriptionline2
	o.Length = songs[currentSelect].Length
    o.contenttype = "episode"
	
    if (songs[currentSelect].artist > "")
        o.Description = "Album: " + songs[currentSelect].Album + chr(10) + "Artist: " + songs[currentSelect].artist + chr(10) + "Year: " + songs[currentSelect].year
    end if
	
    scr = create_springboard(Audio.port, prevLoc)
    scr.ReloadButtons(2) 'set buttons for state "playing"
    scr.screen.SetTitle("Screen Title")

    ' SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
    scr.screen.SetContent(o)
    scr.Show()

    ' start playing
    'print "Starting Song Playback:";song.Url
	totalSongs = songs.Count()
	
	Audio.setContentList( songs )
    Audio.audioplayer.setNext( currentSelect )
    Audio.setPlayState(2)		' start playing
	Audio.audioplayer.setNext( currentSelect + 1)
	
    while true
        msg = Audio.getMsgEvents(20000, "roSpringboardScreenEvent")

        if type(msg) = "roAudioPlayerEvent"  then	' event from audio player
            if msg.isStatusMessage() then
                message = msg.getMessage()
                if message = "end of playlist"
                    print "end of playlist (obsolete status msg event)"
                end if
            else if msg.isListItemSelected() then
                print "playback started"
            else if msg.isRequestSucceeded()
                print "ending song:"; msg.GetIndex()
                Audio.setPlayState(0)	' stop the player, wait for user input
                scr.ReloadButtons(0)    ' set button to allow play start
            else if msg.isRequestFailed()
                print "failed to play song:"; msg.GetData()
            else if msg.isFullResult()
                print "FullResult: End of Playlist"
            else if msg.isPaused()
                print "Paused"
            else if msg.isResumed()
                print "Resumed"
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
                              Audio.audioplayer.setNext(currentSelect)
                        end if
						newstate = 2  ' now playing
					else 'started
                         newstate = 1 ' now paused
                    end if
                else if button = 2 ' stop
                    newstate = 0 ' now stopped
				else if button = 3 ' next
					currentSelect = currentSelect + 1
					if currentSelect = totalSongs then
						currentSelect = 0
					end if
					print "Going to next song: ";currentSelect
					
					Audio.setPlayState(0)
					Audio.audioplayer.setNext(currentSelect)
					
					picture = songs[currentSelect].HDPosterUrl
					o = CreateObject("roAssociativeArray")
					o.HDPosterUrl = picture
					o.SDPosterUrl = picture
					o.Title = songs[currentSelect].shortdescriptionline1
					o.Description = songs[currentSelect].shortdescriptionline2
					o.Length = songs[currentSelect].Length
					o.contenttype = "episode"
					
					print "Going to next song: ";o.Title
					
					if (songs[currentSelect].artist > "")
						o.Description = "Album: " + songs[currentSelect].Album + chr(10) + "Artist: " + songs[currentSelect].artist + chr(10) + "Year: " + songs[currentSelect].year
					end if
					
					scr = create_springboard(Audio.port, prevLoc)
					scr.ReloadButtons(2) 'set buttons for state "playing"
					scr.screen.SetTitle("Screen Title")

					' SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
					scr.screen.SetContent(o)
					scr.Show()
					
					newstate = 2 
				else if button = 4 ' previous
					currentSelect = currentSelect - 1
					if currentSelect < 0 then
						currentSelect = totalSongs - 1
					end if
					print "Going to previous song: ";currentSelect
					
					Audio.setPlayState(0)
					Audio.audioplayer.setNext(currentSelect)
					
					picture = songs[currentSelect].HDPosterUrl
					o = CreateObject("roAssociativeArray")
					o.HDPosterUrl = picture
					o.SDPosterUrl = picture
					o.Title = songs[currentSelect].shortdescriptionline1
					o.Description = songs[currentSelect].shortdescriptionline2
					o.Length = songs[currentSelect].Length
					o.contenttype = "episode"
					
					print "Going to previous song: ";o.Title
					
					if (songs[currentSelect].artist > "")
						o.Description = "Album: " + songs[currentSelect].Album + chr(10) + "Artist: " + songs[currentSelect].artist + chr(10) + "Year: " + songs[currentSelect].year
					end if
					
					scr = create_springboard(Audio.port, prevLoc)
					scr.ReloadButtons(2) 'set buttons for state "playing"
					scr.screen.SetTitle("Screen Title")
					' SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
					scr.screen.SetContent(o)
					scr.Show()	
					
					newstate = 2 
                end if
				
                Audio.setPlayState(newstate)
                scr.ReloadButtons(newstate)
            end if
        end if
    end while
	return 0
End Sub

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