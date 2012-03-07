Sub showAudioScreen(songs as Object, currentSelect, prevLoc as string, prevScreen) As Integer
	screenFacade = CreateObject("roPosterScreen")
	screenFacade.show()
	
	Audio = AudioInit()
	
	screen = CreateObject("roSpringboardScreen")
    screen.SetBreadcrumbText(prevLoc, "Now Playing")
    screen.SetMessagePort(Audio.port)
    screen.SetStaticRatingEnabled(false)
    screen.SetDescriptionStyle("audio")
	
	Print "##################################### CREATE AUDIO DETAIL SCREEN #####################################"
	picture = songs[currentSelect].HDPosterUrl
    o = CreateObject("roAssociativeArray")
    o.HDPosterUrl = picture
    o.SDPosterUrl = picture
    o.Title = songs[currentSelect].shortdescriptionline1
	o.Description = songs[currentSelect].shortdescriptionline2
	o.Length = songs[currentSelect].Length
    o.contenttype = "audio"
	
	if (songs[currentSelect].artist <> invalid)
		o.Artist = songs[currentSelect].artist
	end if
    if (songs[currentSelect].Album <> invalid)
        o.Album = songs[currentSelect].Album
    end if
    
	SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
	ReloadButtons(screen, 2) 'set buttons for state "playing"
    screen.SetContent(o)
	
	screen.SetProgressIndicatorEnabled(true)
	
    screen.Show()
	
	screenFacade.Close()

    ' start playing
    'print "Starting Song Playback:";song.Url
	totalSongs = songs.Count()
	
	Audio.setContentList( songs )
    Audio.audioplayer.setNext( currentSelect )
    Audio.setPlayState(2)		' start playing
	Audio.audioplayer.setNext( currentSelect + 1)
	
	prevScreen.setFocusedListItem(currentSelect)
		
	isPlaying = false
	print "playback: "; isPlaying
	currentTime = 0
	totalTime = o.Length
	
    while true
        msg = Audio.getMsgEvents(1000, "roSpringboardScreenEvent")
			
        if type(msg) = "roAudioPlayerEvent"  then	' event from audio player
            if msg.isStatusMessage() then
                message = msg.getMessage()
				if message = "start of play"
					isPlaying = true
                end if
            else if msg.isListItemSelected() then
                print "playback starting"
            else if msg.isRequestSucceeded()
                print "Ending song: "; msg.GetIndex()
				isPlaying = false
				
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
				o.contenttype = "audio"
				
				currentTime = 0
				totalTime = o.Length
				screen.setProgressIndicator(currentTime, totalTime)
					
				print "Going to next song: ";o.Title
				
				if (songs[currentSelect].artist <> invalid)
					o.Artist = songs[currentSelect].artist
				end if
				if (songs[currentSelect].Album <> invalid)
					o.Album = songs[currentSelect].Album
				end if
				
				SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
				reloadButtons(screen, 2) 'set buttons for state "playing"
				screen.SetContent(o)
				screen.Show()
				
				newstate = 2
				
				Audio.setPlayState(newstate)
				reloadButtons(screen, newstate)
				
				prevScreen.setFocusedListItem(currentSelect)
            else if msg.isRequestFailed()
				print "failed to play song:"; msg.GetData()
				isPlaying = false
            else if msg.isFullResult()
                print "FullResult: End of Playlist"
				isPlaying = false
            else if msg.isPaused()
                print "Paused"
				isPlaying = false
            else if msg.isResumed()
                print "Resumed"
				isPlaying = true
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
				
				if button = 5 'next
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
					o.contenttype = "audio"
					
					currentTime = 0
					totalTime = o.Length
					screen.setProgressIndicator(currentTime, totalTime)
					
					print "Going to next song: ";o.Title
					
					if (songs[currentSelect].artist <> invalid)
						o.Artist = songs[currentSelect].artist
					end if
					if (songs[currentSelect].Album <> invalid)
						o.Album = songs[currentSelect].Album
					end if
					
					SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
					reloadButtons(screen, 2) 'set buttons for state "playing"
					screen.SetContent(o)
					screen.Show()
					
					newstate = 2 
				else if button = 4 'previous
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
					o.contenttype = "audio"
					
					currentTime = 0
					totalTime = o.Length
					screen.setProgressIndicator(currentTime, totalTime)
					
					print "Going to previous song: ";o.Title
					
					if (songs[currentSelect].artist <> invalid)
						o.Artist = songs[currentSelect].artist
					end if
					if (songs[currentSelect].Album <> invalid)
						o.Album = songs[currentSelect].Album
					end if
					
					SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
					reloadButtons(screen, 2) 'set buttons for state "playing"
					screen.SetContent(o)
					screen.Show()	
					
					newstate = 2 
				end if
				
				Audio.setPlayState(newstate)
                reloadButtons(screen, newstate)
				
				prevScreen.setFocusedListItem(currentSelect)
            else if msg.isButtonPressed() then
                button = msg.GetIndex()
                print "button index="; button
                if button = 1 'pause or resume
                    if Audio.isPlayState < 2 then	' stopped or paused?
                        if Audio.isPlayState = 0 then
                              Audio.audioplayer.setNext(currentSelect)
                        end if
						newstate = 2  ' now playing
					else 'started
                        newstate = 1 ' now paused
                    end if
                else if button = 2 ' stop
                    newstate = 0 ' now stopped
					currentTime = 0
					screen.setProgressIndicator(currentTime, totalTime)
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
					o.contenttype = "audio"
					
					currentTime = 0
					totalTime = o.Length
					screen.setProgressIndicator(currentTime, totalTime)
					
					print "Going to next song: ";o.Title
					
					if (songs[currentSelect].artist <> invalid)
						o.Artist = songs[currentSelect].artist
					end if
					if (songs[currentSelect].Album <> invalid)
						o.Album = songs[currentSelect].Album
					end if
					
					SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
					reloadButtons(screen, 2) 'set buttons for state "playing"
					screen.SetContent(o)
					screen.Show()
					
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
					o.contenttype = "audio"
					
					currentTime = 0
					totalTime = o.Length
					screen.setProgressIndicator(currentTime, totalTime)
					
					print "Going to previous song: ";o.Title
					
					if (songs[currentSelect].artist <> invalid)
						o.Artist = songs[currentSelect].artist
					end if
					if (songs[currentSelect].Album <> invalid)
						o.Album = songs[currentSelect].Album
					end if
					
					SaveCoverArtForScreenSaver(o.SDPosterUrl,o.HDPosterUrl)
					reloadButtons(screen, 2) 'set buttons for state "playing"
					screen.SetContent(o)
					screen.Show()	
					
					newstate = 2 
                end if
				
                Audio.setPlayState(newstate)
                reloadButtons(screen, newstate)
				
				prevScreen.setFocusedListItem(currentSelect)
            end if
		else
			' if playback then increment the counter
			' this will not be exact but close enough for government work...
			if isPlaying = true then
				currentTime = currentTime + 1
				screen.setProgressIndicator(currentTime, totalTime)
			end if
        end if
    end while
	return 0
End Sub

Sub reloadButtons(screen, playstate as integer)
    screen.ClearButtons()
    if (playstate = 2)  then ' playing
        screen.AddButton(1, "pause playing")
		screen.AddButton(3, "next song")
		screen.AddButton(4, "previous song")
       	screen.AddButton(2, "stop playing")
    else if (playstate = 1) then ' paused
      	screen.AddButton(1, "resume playing")
		screen.AddButton(3, "next song")
		screen.AddButton(4, "previous song")
       	screen.AddButton(2, "stop playing")
    else ' stopped
        screen.AddButton(1, "start playing")
		screen.AddButton(3, "next song")
		screen.AddButton(4, "previous song")
    endif
End Sub
