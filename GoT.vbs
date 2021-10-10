'On the DOF website put Exxx
'101 Left Flipper
'102 Right Flipper
'103 left slingshot
'104 right slingshot
'105
'106
'107 Center Bumper
'108 RIGHT Bumper
'109 Left bumper
'110
'111 HellHouse
'118
'119 Reset drop Targets
'120 AutoFire
'122 knocker
'123 ballrelease

Option Explicit
Randomize

Const BallSize = 50     ' 50 is the normal size used in the core.vbs, VP kicker routines uses this value divided by 2
Const BallMass = 1.7    ' standard ball mass in JP's VPX Physics 3.0

'***********TABLE VOLUME LEVELS ********* 
' [Value is from 0 to 1 where 1 is full volume. 
' NOTE: you can go past 1 to amplify sounds]

' Desktop Volumes
'Const VolBGMusic = 0.5  ' Volume for Video Clips   
'Const VolMusic1 = 0.4	' Volume for Cleland or Original Gameplay music
' Cab Volumes
Const VolBGMusic = 0.9  ' Volume for Video Clips   
Const VolMusic1 = 0.7	' Volume forOriginal Gameplay music

Const VolDef = 0.2		' Default volume for callouts 
Const VolSfx = 0.2		' Volume for table Sound effects 


Const DMDMode = 1 ' Use Flex/UltraDMD (currently the only option supported)
Const UltraDMDVideos = True				'	ULTRA: Works on my DMDv3 but seems it causes issues on others
Const bUsePlungerForSternKey = False    ' If true, use the plunger key for the Action/Select button. 

' Load the core.vbs for supporting Subs and functions
LoadCoreFiles

Sub LoadCoreFiles
    On Error Resume Next
    ExecuteGlobal GetTextFile("core.vbs")
    If Err Then MsgBox "Can't open core.vbs"
    ExecuteGlobal GetTextFile("controller.vbs")
    If Err Then MsgBox "Can't open controller.vbs"
    On Error Goto 0
End Sub

' Define any Constants
Const cGameName = "gameofthrones"
Const myVersion = "0.9"
Const MaxPlayers = 4          ' from 1 to 4
Const BallSaverTime = 20      ' in seconds of the first ball
Const MaxMultiplier = 5       ' limit playfield multiplier
Const MaxBonusMultiplier = 50 'limit Bonus multiplier
Const BallsPerGame = 3        ' usually 3 or 5
Const MaxMultiballs = 4       ' max number of balls during multiballs

'********* UltraDMD **************
Dim UltraDMD:UltraDMD=0
Const UltraDMD_VideoMode_Stretch = 0
Const UltraDMD_VideoMode_Top = 1
Const UltraDMD_VideoMode_Middle = 2
Const UltraDMD_VideoMode_Bottom = 3
Const UltraDMD_Animation_FadeIn = 0
Const UltraDMD_Animation_FadeOut = 1
Const UltraDMD_Animation_ZoomIn = 2
Const UltraDMD_Animation_ZoomOut = 3
Const UltraDMD_Animation_ScrollOffLeft = 4
Const UltraDMD_Animation_ScrollOffRight = 5
Const UltraDMD_Animation_ScrollOnLeft = 6
Const UltraDMD_Animation_ScrollOnRight = 7
Const UltraDMD_Animation_ScrollOffUp = 8
Const UltraDMD_Animation_ScrollOffDown = 9
Const UltraDMD_Animation_ScrollOnUp = 10
Const UltraDMD_Animation_ScrollOnDown = 11
Const UltraDMD_Animation_None = 14
Const UltraDMD_deOn = 1500

'********* End UltraDMD **************


' Define Global Variables that aren't game-specific 
Dim PlayersPlayingGame
Dim CurrentPlayer
Dim Credits
Dim PuPlayer                ' Not currently used
Dim plungerIM 'used mostly as an autofire plunger
Dim BonusPoints(4)
Dim BonusHeldPoints(4)
Dim BonusMultiplier(4)
Dim Score(4)
Dim HighScore(4)
Dim HighScoreName(4)
Dim BallsRemaining(4)
Dim ExtraBallsAwards(4)     ' I don't think we need an array here - EBs can't be carried over
Dim Tilt
Dim TiltSensitivity
Dim Tilted
Dim TotalGamesPlayed
Dim mBalls2Eject
Dim BallsOnPlayfield        ' Active balls on playfield, including real locked ones
Dim RealBallsInLock			' These are actually locked on the table
Dim BallsInLock             ' Number of balls the current player has locked
Dim BallSearchCnt

' flags
Dim bMultiBallMode
Dim bAutoPlunger
Dim bInstantInfo
Dim bAttractMode
Dim bFreePlay
Dim bGameInPlay
Dim bOnTheFirstBall
Dim bBallInPlungerLane
Dim bBallSaverActive
Dim bBallSaverReady
Dim bTableReady
Dim	bUseUltraDMD
Dim	bUsePUPDMD
Dim	bPupStarted
Dim bBonusHeld
Dim bJustStarted            ' Not sure what this is used for
Dim bShowMatch


' *********************************************************************
'                Visual Pinball Defined Script Events
' *********************************************************************

Sub Table1_Init()
    LoadEM
    Dim i
    Randomize

	' TODO need to look into this 
	vpmNudge.TiltSwitch = 14
    vpmNudge.Sensitivity = 1
    vpmNudge.TiltObj = Array(Bumper1, bumper2, bumper3, LeftSlingshot, RightSlingshot)
	
	bTableReady=False
	bUseUltraDMD=False
	bUsePUPDMD=False
	bPupStarted=False
	if DMDMode = 1 then 
		bUseUltraDMD= True
		set PuPlayer = New PinupNULL
	elseif DMDMode = 2 Then
		bUsePUPDMD = True
	Else 
		set PuPlayer = New PinupNULL
	End if 

	if b2son then 
		Controller.B2SSetData 1,1
		Controller.B2SSetData 2,1
		Controller.B2SSetData 3,1
		Controller.B2SSetData 4,1
		Controller.B2SSetData 5,1
		Controller.B2SSetData 6,1
		Controller.B2SSetData 7,1
		Controller.B2SSetData 8,1
	End if 

    'Impulse Plunger as autoplunger
    Const IMPowerSetting = 45 ' Plunger Power
    Const IMTime = 1.1        ' Time in seconds for Full Plunge
    Set plungerIM = New cvpmImpulseP
    With plungerIM
        .InitImpulseP swplunger, IMPowerSetting, IMTime
        .Random 1.5
        .InitExitSnd SoundFX("fx_kicker", DOFContactors), SoundFX("fx_solenoid", DOFContactors)
        .CreateEvents "plungerIM"
    End With

    ' Misc. VP table objects Initialisation, droptargets, animations...
    VPObjects_Init

    'load saved values, highscore, names, jackpot
    Loadhs

    'Init main variables
    'TODO: Revisit tablestate_init
	' TableState_Init(0)
	' TableState_Init(1)
	' TableState_Init(2)
	' TableState_Init(3)
	' TableState_Init(4)
	' for i = 0 to StackSize
	' 	StackState_Init(i)
	' Next

    ' initalise the DMD display
    DMD_Init

    ' freeplay or coins
    bFreePlay = False ' coins yes or no?

    ' initialse any other flags
    bOnTheFirstBall = False
    bBallInPlungerLane = False
    bBallSaverActive = False
    bBallSaverReady = False
    bMultiBallMode = False
    bGameInPlay = False
	'bGameInPlayHidden = False 
	bShowMatch = False
	'bCreatedBall = False
    bAutoPlunger = False
	'bAutoPlunged = False
    BallsOnPlayfield = 0
	RealBallsInLock=0
    BallsInLock = 0
    Tilt = 0
    TiltSensitivity = 6
    Tilted = False
    bBonusHeld = False
    bJustStarted = True
    bInstantInfo = False


	
	bTableReady = True
	' set any lights for the attract mode
    GiOff
    StartAttractMode

    ' Start the RealTime timer
    RealTime.Enabled = 1

    ' Load table color
    LoadLut

End Sub

'******
' Keys
'******

Sub Table1_KeyDown(ByVal Keycode)

    If keycode = LeftTiltKey Then Nudge 90, 8:PlaySound "fx_nudge", 0, 1, -0.1, 0.25
    If keycode = RightTiltKey Then Nudge 270, 8:PlaySound "fx_nudge", 0, 1, 0.1, 0.25
    If keycode = CenterTiltKey Then Nudge 0, 9:PlaySound "fx_nudge", 0, 1, 1, 0.25

    If keycode = LeftMagnaSave Then bLutActive = True
    If keycode = RightMagnaSave Then
        If bLutActive Then
            NxtLUT
        End If
    End If

    If Keycode = AddCreditKey Then
        Credits = Credits + 1
        if bFreePlay = False Then DOF 125, DOFOn
        If(Tilted = False)Then
            DMDFlush
            DMD "_", CL(1, "CREDITS " & Credits), "", eNone, eNone, eNone, 500, True, "fx_coin"
            If NOT bGameInPlay Then ShowTableInfo
        End If
    End If

    If keycode = PlungerKey Then
        Plunger.Pullback
        PlaySoundAt "fx_plungerpull", plunger
    End If

    If hsbModeActive Then
        EnterHighScoreKey(keycode)
        Exit Sub
    End If

    ' Normal flipper action

    If bGameInPlay AND NOT Tilted Then

        If keycode = LeftTiltKey Then CheckTilt 'only check the tilt during game
        If keycode = RightTiltKey Then CheckTilt
        If keycode = CenterTiltKey Then CheckTilt

        If keycode = LeftFlipperKey Then SolLFlipper 1:InstantInfoTimer.Enabled = True:RotateLaneLights 1
        If keycode = RightFlipperKey Then SolRFlipper 1:InstantInfoTimer.Enabled = True:RotateLaneLights 0

        '  Action Button, Start Mode, fire ball
		If keycode = RightMagnaSave or keycode = LockBarKey or _  
			(keycode = PlungerKey and bUsePlungerForSternKey) Then

			if bAutoPlunger=False and bBallInPlungerLane = True then	' Auto fire ball with stern key
				plungerIM.Strength = 60
				'plungerIM.InitImpulseP swplunger, 60, 0		' Change impulse power while we are here
				PlungerIM.AutoFire
				DOF 125, DOFPulse
				DOF 112, DOFPulse
				plungerIM.Strength = 45
				'plungerIM.InitImpulseP swplunger, 45, 1.1
			Else	
				CheckActionButton True				
			end if
		End if

        If CheckLocalKeydown(keycode) Then Exit Sub

        If keycode = StartGameKey Then
            If((PlayersPlayingGame <MaxPlayers)AND(bOnTheFirstBall = True))Then

                If(bFreePlay = True)Then
                    PlayersPlayingGame = PlayersPlayingGame + 1
                    TotalGamesPlayed = TotalGamesPlayed + 1
                    DMD "_", CL(1, PlayersPlayingGame & " PLAYERS"), "", eNone, eBlink, eNone, 1000, True, ""
                Else
                    If(Credits> 0)then
                        PlayersPlayingGame = PlayersPlayingGame + 1
                        TotalGamesPlayed = TotalGamesPlayed + 1
                        Credits = Credits - 1
                        DMD "_", CL(1, PlayersPlayingGame & " PLAYERS"), "", eNone, eBlink, eNone, 1000, True, ""
                        If Credits <1 And bFreePlay = False Then DOF 125, DOFOff
                    Else
                        ' Not Enough Credits to start a game.
                        DMD CL(0, "CREDITS " & Credits), CL(1, "INSERT COIN"), "", eNone, eBlink, eNone, 1000, True, "vo_nocredits"
                    End If
                End If
            End If
        End If
    Else ' If (GameInPlay)

        If keycode = StartGameKey Then
            If(bFreePlay = True)Then
                If(BallsOnPlayfield = 0)Then
                    ResetForNewGame()
                End If
            Else
                If(Credits> 0)Then
                    If(BallsOnPlayfield = 0)Then
                        Credits = Credits - 1
                        If Credits <1 And bFreePlay = False Then DOF 125, DOFOff
                        ResetForNewGame()
                    End If
                Else
                    ' Not Enough Credits to start a game.
                    DMDFlush
                    DMD CL(0, "CREDITS " & Credits), CL(1, "INSERT COIN"), "", eNone, eBlink, eNone, 1000, True, "vo_nocredits"
                    ShowTableInfo
                End If
            End If
        End If
    End If ' If (GameInPlay)
End Sub

Sub Table1_KeyUp(ByVal keycode)

    If keycode = LeftMagnaSave Then bLutActive = False

    If keycode = PlungerKey Then
        Plunger.Fire
        PlaySoundAt "fx_plunger", plunger
    End If

    If hsbModeActive Then
        Exit Sub
    End If

    ' Table specific

    If bGameInPLay AND NOT Tilted Then
        If keycode = LeftFlipperKey Then
            SolLFlipper 0
            InstantInfoTimer.Enabled = False
            If bInstantInfo Then
                DMDScoreNow
                bInstantInfo = False
            End If
        End If
        If keycode = RightFlipperKey Then
            SolRFlipper 0
            InstantInfoTimer.Enabled = False
            If bInstantInfo Then
                DMDScoreNow
                bInstantInfo = False
            End If
        End If
    End If
End Sub

Sub InstantInfoTimer_Timer
    InstantInfoTimer.Enabled = False
    If NOT hsbModeActive Then
        bInstantInfo = True
        DMDFlush
        InstantInfo
    End If
End Sub

'********************
'     Flippers
'********************

Sub SolLFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFXDOF("fx_flipperup", 101, DOFOn, DOFFlippers), LeftFlipper
        LeftFlipper.EOSTorque = 0.75:LeftFlipper.RotateToEnd
        LeftUFlipper.EOSTorque = 0.75:LeftUFlipper.RotateToEnd

    Else
        PlaySoundAt SoundFXDOF("fx_flipperdown", 101, DOFOff, DOFFlippers), LeftFlipper
        LeftFlipper.EOSTorque = 0.2:LeftFlipper.RotateToStart
        LeftUFlipper.EOSTorque = 0.2:LeftUFlipper.RotateToStart
    End If
End Sub

Sub SolRFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFXDOF("fx_flipperup", 102, DOFOn, DOFFlippers), RightFlipper
        RightFlipper.EOSTorque = 0.75:RightFlipper.RotateToEnd
        RightUFlipper.EOSTorque = 0.75:RightUFlipper.RotateToEnd
    Else
        PlaySoundAt SoundFXDOF("fx_flipperdown", 102, DOFOff, DOFFlippers), RightFlipper
        RightFlipper.EOSTorque = 0.2:RightFlipper.RotateToStart
        RightUFlipper.EOSTorque = 0.2:RightUFlipper.RotateToStart
    End If
End Sub

' flippers hit Sound

Sub LeftFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0, AudioFade(ActiveBall)
End Sub

Sub RightFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0, AudioFade(ActiveBall)
End Sub

Sub LeftUFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0, AudioFade(ActiveBall)
End Sub

Sub RightUFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0, AudioFade(ActiveBall)
End Sub

'*********
' TILT
'*********

'NOTE: The TiltDecreaseTimer Subtracts .01 from the "Tilt" variable every round

Sub CheckTilt                                  'Called when table is nudged
    Tilt = Tilt + TiltSensitivity              'Add to tilt count
    TiltDecreaseTimer.Enabled = True
    If(Tilt> TiltSensitivity)AND(Tilt <15)Then 'show a warning
        DMD "_", CL(1, "CAREFUL"), "_", eNone, eBlinkFast, eNone, 1000, True, ""
    End if
    If Tilt> 15 Then 'If more than 15 then TILT the table
        Tilted = True
        'display Tilt
        DMDFlush
        DMD "", "", "d_TILT", eNone, eNone, eBlink, 200, False, ""
        DisableTable True
        TiltRecoveryTimer.Enabled = True 'start the Tilt delay to check for all the balls to be drained
    End If
End Sub

Sub TiltDecreaseTimer_Timer
    ' DecreaseTilt
    If Tilt> 0 Then
        Tilt = Tilt - 0.1
    Else
        TiltDecreaseTimer.Enabled = False
    End If
End Sub

Sub DisableTable(Enabled)
    If Enabled Then
        'turn off GI and turn off all the lights
        GiOff
        LightSeqTilt.Play SeqAllOff
        'Disable slings, bumpers etc
        LeftFlipper.RotateToStart
        RightFlipper.RotateToStart
        LeftUFlipper.RotateToStart
        RightUFlipper.RotateToStart
        Bumper1.Threshold = 100
        Bumper2.Threshold = 100
        Bumper3.Threshold = 100
        LeftSlingshot.Disabled = 1
        RightSlingshot.Disabled = 1
    Else
        'turn back on GI and the lights
        GiOn
        LightSeqTilt.StopPlay
        Bumper1.Threshold = 1
        Bumper2.Threshold = 1
        Bumper3.Threshold = 1
        LeftSlingshot.Disabled = 0
        RightSlingshot.Disabled = 0
        'clean up the buffer display
        DMDFlush
    End If
End Sub

Sub TiltRecoveryTimer_Timer()
    ' if all the balls have been drained then..
    If(BallsOnPlayfield = 0)Then
        ' do the normal end of ball thing (this doesn't give a bonus if the table is tilted)
        vpmtimer.Addtimer 2000, "EndOfBall() '"
        TiltRecoveryTimer.Enabled = False
    End If
' else retry (checks again in another second or so)
End Sub

'***************************************************************
'             Supporting Ball & Sound Functions v3.0
'  includes random pitch in PlaySoundAt and PlaySoundAtBall
'***************************************************************

Dim TableWidth, TableHeight

TableWidth = Table1.width
TableHeight = Table1.height

Function Vol(ball) ' Calculates the Volume of the sound based on the ball speed
    Vol = Csng(BallVel(ball) ^2 / 2000)
End Function

Function Pan(ball) ' Calculates the pan for a ball based on the X position on the table. "table1" is the name of the table
    Dim tmp
    tmp = ball.x * 2 / TableWidth-1
    If tmp> 0 Then
        Pan = Csng(tmp ^10)
    Else
        Pan = Csng(-((- tmp) ^10))
    End If
End Function

Function Pitch(ball) ' Calculates the pitch of the sound based on the ball speed
    Pitch = BallVel(ball) * 20
End Function

Function BallVel(ball) 'Calculates the ball speed
    BallVel = (SQR((ball.VelX ^2) + (ball.VelY ^2)))
End Function

Function AudioFade(ball) 'only on VPX 10.4 and newer
    Dim tmp
    tmp = ball.y * 2 / TableHeight-1
    If tmp> 0 Then
        AudioFade = Csng(tmp ^10)
    Else
        AudioFade = Csng(-((- tmp) ^10))
    End If
End Function

Sub PlaySoundAt(soundname, tableobj) 'play sound at X and Y position of an object, mostly bumpers, flippers and other fast objects
    PlaySound soundname, 0, 1, Pan(tableobj), 0.1, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtBall(soundname) ' play a sound at the ball position, like rubbers, targets, metals, plastics
    PlaySound soundname, 0, Vol(ActiveBall), pan(ActiveBall), 0.4, 0, 0, 0, AudioFade(ActiveBall)
End Sub

Sub PlaySoundVol(soundname, Volume)
  PlaySound soundname, 1, Volume
End Sub

Sub PlaySoundLoopVol(soundname, Volume)
  PlaySound soundname, -1, Volume
End Sub

'********************
' Music as wav sounds
'********************

Dim Song
Song = ""

Sub ThemeSong
	PlaySong("Song-1")
	SongNum=1
End Sub

Sub RotateSong()
'debug.print "Rotate " & SongNum
	PlaySong "Song-" & SongNum
	SongNum=SongNum+1
	if (SongNum>=4) then SongNum=1
End Sub


dim bPlayPaused
bPlayPaused = False
Sub PlaySong(name)
'debug.print "PlaySong " & name & " " & song
	dim PlayLength
	if bUsePUPDMD then 			' Use Pup if we have it so we can pause the music
'		PlaySongPup(name)
		exit sub
	End If 
	StopSound "m_wait"
	StopSound Song	' Stop the old song
	if name <> "" then Song = name
	PlayLength = -1
	If Song = "m_end" Then PlayLength = 0
	bPlayPaused=False
	PlaySound Song, PlayLength, VolBGMusic 'this last number is the volume, from 0 to 1
End Sub


Function RndNbr(n) 'returns a random number between 1 and n
    Randomize timer
    RndNbr = Int((n * Rnd) + 1)
End Function

'***********************************************
'   JP's VP10 Rolling Sounds + Ballshadow v3.0
'   uses a collection of shadows, aBallShadow
'***********************************************

Const tnob = 19   'total number of balls, 20 balls, from 0 to 19
Const lob = 0     'number of locked balls
Const maxvel = 45 'max ball velocity
ReDim rolling(tnob)
InitRolling

Sub InitRolling
    Dim i
    For i = 0 to tnob
        rolling(i) = False
    Next
End Sub

Sub RollingUpdate()
    Dim BOT, b, ballpitch, ballvol, speedfactorx, speedfactory
    BOT = GetBalls

    ' stop the sound of deleted balls and hide the shadow
    For b = UBound(BOT) + 1 to tnob
        rolling(b) = False
        StopSound("fx_ballrolling" & b)
        aBallShadow(b).Y = 3000
    Next

    ' exit the sub if no balls on the table
    If UBound(BOT) = lob - 1 Then Exit Sub 'there no extra balls on this table

    ' play the rolling sound for each ball and draw the shadow
    For b = lob to UBound(BOT)
        aBallShadow(b).X = BOT(b).X
        aBallShadow(b).Y = BOT(b).Y
        aBallShadow(b).Height = BOT(b).Z -24

        If BallVel(BOT(b))> 1 Then
            If BOT(b).z <30 Then
                ballpitch = Pitch(BOT(b))
                ballvol = Vol(BOT(b))
            Else
                ballpitch = Pitch(BOT(b)) + 25000 'increase the pitch on a ramp
                ballvol = Vol(BOT(b)) * 10
            End If
            rolling(b) = True
            PlaySound("fx_ballrolling" & b), -1, ballvol, Pan(BOT(b)), 0, ballpitch, 1, 0, AudioFade(BOT(b))
        Else
            If rolling(b) = True Then
                StopSound("fx_ballrolling" & b)
                rolling(b) = False
            End If
        End If

        ' rothbauerw's Dropping Sounds
        If BOT(b).VelZ <-1 and BOT(b).z <55 and BOT(b).z> 27 Then 'height adjust for ball drop sounds
            PlaySound "fx_balldrop", 0, ABS(BOT(b).velz) / 17, Pan(BOT(b)), 0, Pitch(BOT(b)), 1, 0, AudioFade(BOT(b))
        End If

        ' jps ball speed control
        If BOT(b).VelX AND BOT(b).VelY <> 0 Then
            speedfactorx = ABS(maxvel / BOT(b).VelX)
            speedfactory = ABS(maxvel / BOT(b).VelY)
            If speedfactorx <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactorx
                BOT(b).VelY = BOT(b).VelY * speedfactorx
            End If
            If speedfactory <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactory
                BOT(b).VelY = BOT(b).VelY * speedfactory
            End If
        End If
    Next
End Sub

'**********************
' Ball Collision Sound
'**********************

Sub OnBallBallCollision(ball1, ball2, velocity)
    PlaySound "fx_collide", 0, Csng(velocity) ^2 / 2000, Pan(ball1), 0, Pitch(ball1), 0, 0, AudioFade(ball1)
End Sub

'************************************
' Diverse Collection Hit Sounds v3.0
'************************************

Sub aMetals_Hit(idx):PlaySoundAtBall "fx_MetalHit":End Sub
Sub aMetalWires_Hit(idx):PlaySoundAtBall "fx_MetalWire":End Sub
Sub aRubber_Bands_Hit(idx):PlaySoundAtBall "fx_rubber_band":End Sub
Sub aRubber_LongBands_Hit(idx):PlaySoundAtBall "fx_rubber_longband":End Sub
Sub aRubber_Posts_Hit(idx):PlaySoundAtBall "fx_rubber_post":End Sub
Sub aRubber_Pins_Hit(idx):PlaySoundAtBall "fx_rubber_pin":End Sub
Sub aRubber_Pegs_Hit(idx):PlaySoundAtBall "fx_rubber_peg":End Sub
Sub aPlastics_Hit(idx):PlaySoundAtBall "fx_PlasticHit":End Sub
Sub aGates_Hit(idx):PlaySoundAtBall "fx_Gate":End Sub
Sub aWoods_Hit(idx):PlaySoundAtBall "fx_Woodhit":End Sub
' TODO: Not sure we want to play random sounds when triggers are hit?
Sub aTriggers_Hit(idx):PlaySfx:End Sub

' Slingshots has been hit

Dim LStep, RStep

Sub LeftSlingShot_Slingshot
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF("CrispySlingLeft", 103, DOFPulse, DOFContactors), Lemk
    DOF 104, DOFPulse
    LeftSling4.Visible = 1:LeftSling1.Visible = 0
    Lemk.RotX = 26
    LStep = 0
    LeftSlingShot.TimerEnabled = True
    ' add some points
    AddScore 170
    ' add some effect to the table?
    'FlashForMs l20, 1000, 50, 0:FlashForMs l20f, 1000, 50, 0
    'FlashForMs l21, 1000, 50, 0:FlashForMs l21f, 1000, 50, 0
    ' remember last trigger hit by the ball
    LastSwitchHit = "LeftSlingShot"
End Sub

Sub LeftSlingShot_Timer
    Select Case LStep
        Case 1:LeftSLing4.Visible = 0:LeftSLing3.Visible = 1:Lemk.RotX = 14
        Case 2:LeftSLing3.Visible = 0:LeftSLing2.Visible = 1:Lemk.RotX = 2
        Case 3:LeftSLing2.Visible = 0:LeftSling1.Visible = 1:Lemk.RotX = -10:Gi2.State = 1:LeftSlingShot.TimerEnabled = False
    End Select
    LStep = LStep + 1
End Sub

Sub RightSlingShot_Slingshot
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF("CrispySlingRight", 105, DOFPulse, DOFContactors),Remk
    DOF 106, DOFPulse
    RightSling4.Visible = 1:RightSling1.Visible = 0
    Remk.RotX = 26
    RStep = 0
    RightSlingShot.TimerEnabled = True
    ' add some points
    AddScore 170
    ' add some effect to the table?
    'FlashForMs l22, 1000, 50, 0:FlashForMs l22f, 1000, 50, 0
    'FlashForMs l23, 1000, 50, 0:FlashForMs l23f, 1000, 50, 0
    ' remember last trigger hit by the ball
    LastSwitchHit = "RightSlingShot"
End Sub

Sub RightSlingShot_Timer
    Select Case RStep
        Case 1:RightSLing4.Visible = 0:RightSLing3.Visible = 1:Remk.RotX = 14:
        Case 2:RightSLing3.Visible = 0:RightSLing2.Visible = 1:Remk.RotX = 2:
        Case 3:RightSLing2.Visible = 0:RightSLing1.Visible = 1:Remk.RotX = -10:Gi4.State = 1:RightSlingShot.TimerEnabled = False
    End Select
    RStep = RStep + 1
End Sub


'************************************
' High Score support
'************************************
'*****************************
'    Load / Save / Highscore
'*****************************

Sub Loadhs
    Dim x
    x = LoadValue(cGameName, "HighScore1")
    If(x <> "")Then HighScore(0) = CDbl(x)Else HighScore(0) = 100000 End If
    x = LoadValue(cGameName, "HighScore1Name")
    If(x <> "")Then HighScoreName(0) = x Else HighScoreName(0) = "AAA" End If
    x = LoadValue(cGameName, "HighScore2")
    If(x <> "")then HighScore(1) = CDbl(x)Else HighScore(1) = 100000 End If
    x = LoadValue(cGameName, "HighScore2Name")
    If(x <> "")then HighScoreName(1) = x Else HighScoreName(1) = "BBB" End If
    x = LoadValue(cGameName, "HighScore3")
    If(x <> "")then HighScore(2) = CDbl(x)Else HighScore(2) = 100000 End If
    x = LoadValue(cGameName, "HighScore3Name")
    If(x <> "")then HighScoreName(2) = x Else HighScoreName(2) = "CCC" End If
    x = LoadValue(cGameName, "HighScore4")
    If(x <> "")then HighScore(3) = CDbl(x)Else HighScore(3) = 100000 End If
    x = LoadValue(cGameName, "HighScore4Name")
    If(x <> "")then HighScoreName(3) = x Else HighScoreName(3) = "DDD" End If
    x = LoadValue(cGameName, "Credits")
    If(x <> "")then Credits = CInt(x)Else Credits = 0:If bFreePlay = False Then DOF 125, DOFOff:End If
    x = LoadValue(cGameName, "TotalGamesPlayed")
    If(x <> "")then TotalGamesPlayed = CInt(x)Else TotalGamesPlayed = 0 End If
End Sub

Sub Savehs
    SaveValue cGameName, "HighScore1", HighScore(0)
    SaveValue cGameName, "HighScore1Name", HighScoreName(0)
    SaveValue cGameName, "HighScore2", HighScore(1)
    SaveValue cGameName, "HighScore2Name", HighScoreName(1)
    SaveValue cGameName, "HighScore3", HighScore(2)
    SaveValue cGameName, "HighScore3Name", HighScoreName(2)
    SaveValue cGameName, "HighScore4", HighScore(3)
    SaveValue cGameName, "HighScore4Name", HighScoreName(3)
    SaveValue cGameName, "Credits", Credits
    SaveValue cGameName, "TotalGamesPlayed", TotalGamesPlayed
End Sub

Sub Reseths
    HighScoreName(0) = "AAA"
    HighScoreName(1) = "BBB"
    HighScoreName(2) = "CCC"
    HighScoreName(3) = "DDD"
    HighScore(0) = 150000
    HighScore(1) = 140000
    HighScore(2) = 130000
    HighScore(3) = 120000
    Savehs
End Sub

' ***********************************************************
'  High Score Initals Entry Functions - based on Black's code
' ***********************************************************

Dim hsbModeActive
Dim hsEnteredName
Dim hsEnteredDigits(3)
Dim hsCurrentDigit
Dim hsValidLetters
Dim hsCurrentLetter
Dim hsLetterFlash

Sub CheckHighscore()
    Dim tmp
    tmp = Score(CurrentPlayer)

    If tmp> HighScore(0)Then 'add 1 credit for beating the highscore
        Credits = Credits + 1
        DOF 125, DOFOn
    End If

    If tmp> HighScore(3)Then
        PlaySound SoundFXDOF("fx_Knocker", 122, DOFPulse, DOFKnocker)
        DOF 121, DOFPulse
        HighScore(3) = tmp
        'enter player's name
        HighScoreEntryInit()
    Else
        EndOfBallComplete()
    End If
End Sub

Sub HighScoreEntryInit()
    hsbModeActive = True
    PlaySound "vo_enterinitials"
    hsLetterFlash = 0

    hsEnteredDigits(0) = " "
    hsEnteredDigits(1) = " "
    hsEnteredDigits(2) = " "
    hsCurrentDigit = 0

    hsValidLetters = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789<" ' < is back arrow
    hsCurrentLetter = 1
    DMDFlush()
    HighScoreDisplayNameNow()

    HighScoreFlashTimer.Interval = 250
    HighScoreFlashTimer.Enabled = True
End Sub

Sub EnterHighScoreKey(keycode)
    If keycode = LeftFlipperKey Then
        playsound "fx_Previous"
        hsCurrentLetter = hsCurrentLetter - 1
        if(hsCurrentLetter = 0)then
            hsCurrentLetter = len(hsValidLetters)
        end if
        HighScoreDisplayNameNow()
    End If

    If keycode = RightFlipperKey Then
        playsound "fx_Next"
        hsCurrentLetter = hsCurrentLetter + 1
        if(hsCurrentLetter> len(hsValidLetters))then
            hsCurrentLetter = 1
        end if
        HighScoreDisplayNameNow()
    End If

    If keycode = PlungerKey OR keycode = StartGameKey Then
        if(mid(hsValidLetters, hsCurrentLetter, 1) <> "<")then
            playsound "fx_Enter"
            hsEnteredDigits(hsCurrentDigit) = mid(hsValidLetters, hsCurrentLetter, 1)
            hsCurrentDigit = hsCurrentDigit + 1
            if(hsCurrentDigit = 3)then
                HighScoreCommitName()
            else
                HighScoreDisplayNameNow()
            end if
        else
            playsound "fx_Esc"
            hsEnteredDigits(hsCurrentDigit) = " "
            if(hsCurrentDigit> 0)then
                hsCurrentDigit = hsCurrentDigit - 1
            end if
            HighScoreDisplayNameNow()
        end if
    end if
End Sub

Sub HighScoreDisplayNameNow()
    HighScoreFlashTimer.Enabled = False
    hsLetterFlash = 0
    HighScoreDisplayName()
    HighScoreFlashTimer.Enabled = True
End Sub

Sub HighScoreDisplayName()
    Dim i
    Dim TempTopStr
    Dim TempBotStr

    TempTopStr = "YOUR NAME:"
    dLine(0) = ExpandLine(TempTopStr, 0)
    DMDUpdate 0

    TempBotStr = "    > "
    if(hsCurrentDigit> 0)then TempBotStr = TempBotStr & hsEnteredDigits(0)
    if(hsCurrentDigit> 1)then TempBotStr = TempBotStr & hsEnteredDigits(1)
    if(hsCurrentDigit> 2)then TempBotStr = TempBotStr & hsEnteredDigits(2)

    if(hsCurrentDigit <> 3)then
        if(hsLetterFlash <> 0)then
            TempBotStr = TempBotStr & "_"
        else
            TempBotStr = TempBotStr & mid(hsValidLetters, hsCurrentLetter, 1)
        end if
    end if

    if(hsCurrentDigit <1)then TempBotStr = TempBotStr & hsEnteredDigits(1)
    if(hsCurrentDigit <2)then TempBotStr = TempBotStr & hsEnteredDigits(2)

    TempBotStr = TempBotStr & " <    "
    dLine(1) = ExpandLine(TempBotStr, 1)
    DMDUpdate 1
End Sub

Sub HighScoreFlashTimer_Timer()
    HighScoreFlashTimer.Enabled = False
    hsLetterFlash = hsLetterFlash + 1
    if(hsLetterFlash = 2)then hsLetterFlash = 0
    HighScoreDisplayName()
    HighScoreFlashTimer.Enabled = True
End Sub

Sub HighScoreCommitName()
    HighScoreFlashTimer.Enabled = False
    hsbModeActive = False

    hsEnteredName = hsEnteredDigits(0) & hsEnteredDigits(1) & hsEnteredDigits(2)
    if(hsEnteredName = "   ")then
        hsEnteredName = "YOU"
    end if

    HighScoreName(3) = hsEnteredName
    SortHighscore
    EndOfBallComplete()
End Sub

Sub SortHighscore
    Dim tmp, tmp2, i, j
    For i = 0 to 3
        For j = 0 to 2
            If HighScore(j) <HighScore(j + 1)Then
                tmp = HighScore(j + 1)
                tmp2 = HighScoreName(j + 1)
                HighScore(j + 1) = HighScore(j)
                HighScoreName(j + 1) = HighScoreName(j)
                HighScore(j) = tmp
                HighScoreName(j) = tmp2
            End If
        Next
    Next
End Sub


'********************************************************
' DMD Support. For now, this uses UltraDMD
' but we'll probably update to FlexDMD-specific API calls
' and eventually PuP
'******************************************************** 

Const eNone = 0        ' Instantly displayed

Sub LoadUltraDMD
	Dim WshShell
	Set WshShell = CreateObject("WScript.Shell")
	WshShell.RegWrite "HKCU\Software\UltraDMD\fullcolor",False,"REG_SZ"

	On Error Resume Next
    Set UltraDMD = CreateObject("UltraDMD.DMDObject")
    If UltraDMD is Nothing Then
        MsgBox "No UltraDMD found.  This table MAY run without it."
		bUseUltraDMD=False
        Exit Sub
    End If
	On Error Goto 0

    UltraDMD.Init
	UltraDMD.SetVideoStretchMode 2
    If Not UltraDMD.GetMajorVersion = 1 Then
        MsgBox "Incompatible Version of UltraDMD found."
        Exit Sub
    End If

    If UltraDMD.GetMinorVersion < 1 Then
        MsgBox "Incompatible Version of UltraDMD found. Please update to version 1.1 or newer."
        Exit Sub
    End If

    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    Dim curDir
    curDir = fso.GetAbsolutePathName(".")
    UltraDMD.SetProjectFolder curDir & "\GameOfThronesLE.UltraDMD"
	dim vid0
	
End Sub

Sub DMD_Clearforhighscore()
	if (bUseUltraDMD) then
		UltraDMD.CancelRendering
		UltraDMD.Clear
	End If
End Sub

Sub DMDClearQueue				' It looks like if we call this too fast it will cancel the ULTRA DMD logo scene
	if bUseUltraDMD and UltraDMDVideos Then
		If UltraDMD.IsRendering Then
			UltraDMD.CancelRendering
			'UltraDMD.CancelRenderingWithId video
			'UltraDMD.Clear
		End If
	End If
End Sub

Sub PlayDMDScene(video, timeMs)
	if bUseUltraDMD and UltraDMDVideos Then
		' Note Video needs to not have sounds and must be more then 3 seconds (Export from iMovie, I chose 540p, high quality, Faster compression.
		UltraDMD.DisplayScene00 video, "", 15, "", 15, UltraDMD_Animation_None, timeMs, UltraDMD_Animation_None
		'UltraDMD.DisplayScene00ExWithId video, False, video, "", 15, 15, "", 15, 15, 14, 4000, 14
	End If
End Sub

Sub DisplayDMDText(Line1, Line2, duration)
	'debug.print "DMDText " & Line1 & " " & Line2
	if bUseUltraDMD Then
		UltraDMD.DisplayScene00 "", Line1, 15, Line2, 15, 14, duration, 14
	Elseif bUsePUPDMD Then
		If bPupStarted then 
			if Line1 = "" or Line1 = "_" then 
				pupDMDDisplay "-", Line2, "" ,Duration/1000, 0, 10
			else
				pupDMDDisplay "-", Line1 & "^" & Line2, "" ,Duration/1000, 0, 10
			End If 
		End If 
	End If
End Sub

Sub DisplayDMDText2(Line1, Line2, duration, pri, blink)
	if bUseUltraDMD Then
		UltraDMD.DisplayScene00 "", Line1, 15, Line2, 15, 14, duration, 14
	Elseif bUsePUPDMD Then
		If bPupStarted then 
			if Line1 = "" or Line1 = "_" then 
				pupDMDDisplay "-", Line2, "" ,Duration/1000, blink, pri
			else
				pupDMDDisplay "-", Line1 & "^" & Line2, "" ,Duration/1000, blink, pri
			End If 
		End If 
	End If
End Sub



Sub DMDId(id, toptext, bottomtext, duration) 'used in the highscore entry routine
	if bUseUltraDMD then 
		UltraDMD.DisplayScene00ExwithID id, false, "", toptext, 15, 0, bottomtext, 15, 0, 14, duration, 14
	Elseif bUsePUPDMD Then
		If bPupStarted then pupDMDDisplay "default", toptext & "^" & bottomtext, "" ,Duration/1000, 0, 10
	End If 
End Sub

Sub DMDMod(id, toptext, bottomtext, duration) 'used in the highscore entry routine
	if bUseUltraDMD then 
		UltraDMD.ModifyScene00Ex id, toptext, bottomtext, duration
	Elseif bUsePUPDMD Then
		If bPupStarted then pupDMDDisplay "default", toptext & "^" & bottomtext, "" ,Duration/1000, 0, 10
	End If 
End Sub


Dim dCharsPerLine(2)
Dim dLine(2)

Sub DMD_Init() 'default/startup values
    Dim i, j

	if bUseUltraDMD then LoadUltraDMD()

    DMDFlush()
    dCharsPerLine(0) = 20
    dCharsPerLine(1) = 20
    dCharsPerLine(2) = 20
    For i = 0 to 2
        dLine(i) = Space(dCharsPerLine(i))
    Next
    DMD dLine(0), dLine(1), dLine(2), eNone, eNone, eNone, 25, True, ""
End Sub

Sub DMDFlush()
	DMDClearQueue
End Sub

Sub DMDScore()
    Dim tmp, tmp1, tmp2
	Dim TimeStr

	if bUseUltraDMD Then 
		If Not UltraDMD.IsRendering Then
            'TODO: This is where we'll display custom text when selecting house, battle, and mystery awards
			' if PlayerMode = -1 Then
			' 	If bSecondMode then
			' 		if PlayerMode2 = -1 then 
			' 			TimeStr = "Select Mode/2nd"
			' 		Else 
			' 			if PlayerMode2 = 7 or PlayerMode2 = 2 Then  ' SwitchHits 
			' 				TimeStr = Mode2Percent(PlayerMode2) & "%  HITS:" & SwitchHitCount & " 2nd"
			' 			else
			' 				TimeStr = Mode2Percent(PlayerMode2) & "% 2nd"
			' 			end If
			' 		End if 
			' 	else 
			' 		TimeStr = "Select Mode"
			' 	End If 
			' elseif PlayerMode = 7 Then  ' SwitchHits 
			' 	TimeStr = "Time:" & ModeCountdownTimer.UserValue & "(" & ModePercent(PlayerMode) & ") Sw:" & SwitchHitCount
			' else
			' 	TimeStr = "Time:" & ModeCountdownTimer.UserValue & "(" & ModePercent(PlayerMode) & ")"
			' end If
			DisplayDMDText RL(0,Score(CurrentPlayer)), "", 1000 
		End If
	End If
End Sub

Sub DMDScoreNow
    DMDFlush
    DMDScore
End Sub

Sub DMD(Text0, Text1, Text2, Effect0, Effect1, Effect2, TimeOn, bFlush, Sound)
	DisplayDMDText Text0, Text1, TimeOn
	'if bUsePUPDMD and bPupStarted Then pupDMDDisplay "default", Text0 & "^" & Text1, "" ,2, 0, 10
	'if (bUsePUPDMD) Then pupDMDDisplay "attract", Text1 & "^" Text2, "@vidIntro.mp4" ,9, 1,		10
	PlaySoundVol Sound, VolDef
End Sub

Function ExpandLine(TempStr, id) 'id is the number of the dmd line
    If TempStr = "" Then
        TempStr = Space(dCharsPerLine(id))
    Else
        if(Len(TempStr) > Space(dCharsPerLine(id)))Then
            TempStr = Left(TempStr, Space(dCharsPerLine(id)))
        Else
            if(Len(TempStr) < dCharsPerLine(id))Then
                TempStr = TempStr & Space(dCharsPerLine(id)- Len(TempStr))
            End If
        End If
    End If
    ExpandLine = TempStr
End Function

Function FormatScore(ByVal Num) 'it returns a string with commas (as in Black's original font)
    dim i
    dim NumString

    NumString = CStr(abs(Num))

    For i = Len(NumString)-3 to 1 step -3
        if IsNumeric(mid(NumString, i, 1))then
            NumString = left(NumString, i) & "," & right(NumString, Len(NumString)-i)
        end if
    Next
    FormatScore = NumString
End function

Function CL(id, NumString) 'center line
    Dim Temp, TempStr
	NumString = LEFT(NumString, dCharsPerLine(id))
    Temp = (dCharsPerLine(id)- Len(NumString)) \ 2
    TempStr = Space(Temp) & NumString & Space(Temp)
    CL = TempStr
End Function

Function RL(id, NumString) 'right line
    Dim Temp, TempStr
	NumString = LEFT(NumString, dCharsPerLine(id))
    Temp = dCharsPerLine(id)- Len(NumString)
    TempStr = Space(Temp) & NumString
    RL = TempStr
End Function

Function FL(id, aString, bString) 'fill line
    Dim tmp, tmpStr
	aString = LEFT(aString, dCharsPerLine(id))
	bString = LEFT(bString, dCharsPerLine(id))
    tmp = dCharsPerLine(id)- Len(aString)- Len(bString)
	If tmp <0 Then tmp = 0
    tmpStr = aString & Space(tmp) & bString
    FL = tmpStr
End Function

'*********
'   LUT
'*********

Dim bLutActive, LUTImage
Sub LoadLUT
    Dim x
    bLutActive = False
    x = LoadValue(cGameName, "LUTImage")
    If(x <> "")Then LUTImage = x Else LUTImage = 0
    UpdateLUT
End Sub

Sub SaveLUT
    SaveValue cGameName, "LUTImage", LUTImage
End Sub

Sub NextLUT:LUTImage = (LUTImage + 1)MOD 10:UpdateLUT:SaveLUT:End Sub

Sub UpdateLUT
    Select Case LutImage
        Case 0:table1.ColorGradeImage = "LUT0"
        Case 1:table1.ColorGradeImage = "LUT1"
        Case 2:table1.ColorGradeImage = "LUT2"
        Case 3:table1.ColorGradeImage = "LUT3"
        Case 4:table1.ColorGradeImage = "LUT4"
        Case 5:table1.ColorGradeImage = "LUT5"
        Case 6:table1.ColorGradeImage = "LUT6"
        Case 7:table1.ColorGradeImage = "LUT7"
        Case 8:table1.ColorGradeImage = "LUT8"
        Case 9:table1.ColorGradeImage = "LUT9"
    End Select
End Sub




'********************************************************************************************
' Only for VPX 10.2 and higher.
' FlashForMs will blink light or a flasher for TotalPeriod(ms) at rate of BlinkPeriod(ms)
' When TotalPeriod done, light or flasher will be set to FinalState value where
' Final State values are:   0=Off, 1=On, 2=Return to previous State
'********************************************************************************************

Sub FlashForMs(MyLight, TotalPeriod, BlinkPeriod, FinalState) 'thanks gtxjoe for the first myVersion

    If TypeName(MyLight) = "Light" Then

        If FinalState = 2 Then
            FinalState = MyLight.State 'Keep the current light state
        End If
        MyLight.BlinkInterval = BlinkPeriod
        MyLight.Duration 2, TotalPeriod, FinalState
    ElseIf TypeName(MyLight) = "Flasher" Then

        Dim steps

        ' Store all blink information
        steps = Int(TotalPeriod / BlinkPeriod + .5) 'Number of ON/OFF steps to perform
        If FinalState = 2 Then                      'Keep the current flasher state
            FinalState = ABS(MyLight.Visible)
        End If
        MyLight.UserValue = steps * 10 + FinalState 'Store # of blinks, and final state

        ' Start blink timer and create timer subroutine
        MyLight.TimerInterval = BlinkPeriod
        MyLight.TimerEnabled = 0
        MyLight.TimerEnabled = 1
        ExecuteGlobal "Sub " & MyLight.Name & "_Timer:" & "Dim tmp, steps, fstate:tmp=me.UserValue:fstate = tmp MOD 10:steps= tmp\10 -1:Me.Visible = steps MOD 2:me.UserValue = steps *10 + fstate:If Steps = 0 then Me.Visible = fstate:Me.TimerEnabled=0:End if:End Sub"
    End If
End Sub

'******************************************
' Change light color - simulate color leds
' changes the light color and state
' 11 colors: red, orange, amber, yellow...
'******************************************
' in this table this colors are use to keep track of the progress during the modes

'colors
Const red = 10
Const orange = 9
Const amber = 8
Const yellow = 7
Const darkgreen = 6
Const green = 5
Const blue = 4
Const darkblue = 3
Const purple = 2
Const white = 1
Const teal = 0
'******************************************
' Change light color - simulate color leds
' changes the light color and state
' colors: red, orange, yellow, green, blue, white, purple, amber
' Note: Colors tweaked slightly to match GoT color scheme
'******************************************


Sub SetLightColor(n, col, stat) 'stat 0 = off, 1 = on, 2 = blink, -1= no change
    Select Case col
        Case red
            n.color = RGB(18, 0, 0)
            n.colorfull = RGB(255, 0, 0)
        Case orange
            n.color = RGB(18, 3, 0)
            n.colorfull = RGB(255, 64, 0)
        Case amber
            n.color = RGB(193, 49, 0)
            n.colorfull = RGB(255, 153, 0)
        Case yellow
            n.color = RGB(18, 18, 0)
            n.colorfull = RGB(255, 255, 0)
        Case darkgreen
            n.color = RGB(0, 8, 0)
            n.colorfull = RGB(0, 64, 0)
        Case green
            n.color = RGB(0, 16, 0)
            n.colorfull = RGB(0, 192, 0)
        Case blue
            n.color = RGB(0, 18, 18)
            n.colorfull = RGB(0, 255, 255)
        Case darkblue
            n.color = RGB(0, 8, 8)
            n.colorfull = RGB(0, 64, 64)
        Case purple
            n.color = RGB(64, 0, 96)
            n.colorfull = RGB(128, 0, 192)
        Case white
            n.color = RGB(255, 197, 143)
            n.colorfull = RGB(255, 252, 224)
        Case teal
            n.color = RGB(1, 64, 62)
            n.colorfull = RGB(2, 128, 126)
    End Select
    If stat <> -1 Then
        n.State = 0
        n.State = stat
    End If
End Sub

Sub SetFlashColor(n, col, stat) 'stat 0 = off, 1 = on, -1= no change - no blink for the flashers
    Select Case col
        Case red
            n.color = RGB(255, 0, 0)
        Case orange
            n.color = RGB(255, 64, 0)
        Case amber
            n.color = RGB(255, 153, 0)
        Case yellow
            n.color = RGB(255, 255, 0)
        Case darkgreen
            n.color = RGB(0, 64, 0)
        Case green
            n.color = RGB(0, 128, 0)
        Case blue
            n.color = RGB(0, 255, 255)
        Case darkblue
            n.color = RGB(0, 64, 64)
        Case purple
            n.color = RGB(128, 0, 192)
        Case white
            n.color = RGB(255, 252, 224)
        Case teal
            n.color = RGB(2, 128, 126)
    End Select
    If stat <> -1 Then
        n.Visible = stat
    End If
End Sub

Sub ChangeGi(col) 'changes the gi color
    Dim bulb
    For each bulb in aGILights
        SetLightColor bulb, col, -1
    Next
End Sub

Sub GiOn
    DOF 118, DOFOn
    Dim bulb
    For each bulb in aGiLights
        bulb.State = 1
    Next
    GameGiOn
End Sub

Sub GiOff
    DOF 118, DOFOff
    Dim bulb
    For each bulb in aGiLights
        bulb.State = 0
    Next
    GameGiOff
End Sub

' GI, light & flashers sequence effects

Sub GiEffect(n)
    Dim ii
    Select Case n
        Case 0 'all off
            LightSeqGi.Play SeqAlloff
        Case 1 'all blink
            LightSeqGi.UpdateInterval = 20
            LightSeqGi.Play SeqBlinking, , 15, 10
        Case 2 'random
            LightSeqGi.UpdateInterval = 20
            LightSeqGi.Play SeqRandom, 50, , 1000
        Case 3 'all blink fast
            LightSeqGi.UpdateInterval = 20
            LightSeqGi.Play SeqBlinking, , 10, 10
        Case 4 'seq up
            LightSeqGi.UpdateInterval = 3
            LightSeqGi.Play SeqUpOn, 25, 3
        Case 5 'seq down
            LightSeqGi.UpdateInterval = 3
            LightSeqGi.Play SeqDownOn, 25, 3
    End Select
End Sub

'********************
' Real Time updates
'********************
'used for all the real time updates

Sub Realtime_Timer
    RollingUpdate
    LeftFlipperTop.RotZ = LeftFlipper.CurrentAngle
    RightFlipperTop.RotZ = RightFlipper.CurrentAngle
    LeftUFlipperTop.RotZ = LeftUFlipper.CurrentAngle
    RightUFlipperTop.RotZ = RightUFlipper.CurrentAngle
' add any other real time update subs, like gates or diverters, flippers
End Sub


'*******************************
' Attract mode support
' (should be table-independent)
'*******************************

Sub StartAttractMode
    Dim a
    'StartRainbow aArrows
    StartLightSeq
    DMDFlush
    ShowTableInfo
    a = RndNbr(2)
    Select Case a
        Case 1:PlaySong "mu_gameover"
        case 2:PlaySong "mu_boom-dp-rap"
    End Select
End Sub

Sub StopAttractMode
    'StopRainbow
    DMDScoreNow
    LightSeqAttract.StopPlay
End Sub

Sub StartLightSeq()
    'lights sequences
    LightSeqAttract.UpdateInterval = 25
    LightSeqAttract.Play SeqBlinking, , 5, 150
    LightSeqAttract.Play SeqAllOff
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 50, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqCircleOutOn, 15, 2
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqCircleOutOn, 15, 3
    LightSeqAttract.UpdateInterval = 5
    LightSeqAttract.Play SeqRightOn, 50, 1
    LightSeqAttract.UpdateInterval = 5
    LightSeqAttract.Play SeqLeftOn, 50, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 50, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 50, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 40, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 40, 1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqRightOn, 30, 1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqLeftOn, 30, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 15, 1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqCircleOutOn, 15, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 5
    LightSeqAttract.Play SeqStripe1VertOn, 50, 2
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqCircleOutOn, 15, 2
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqStripe1VertOn, 50, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqCircleOutOn, 15, 2
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqStripe2VertOn, 50, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqStripe1VertOn, 25, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqStripe2VertOn, 25, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 15, 1
End Sub

Sub LightSeqAttract_PlayDone()
    StartLightSeq()
End Sub

Sub LightSeqTilt_PlayDone()
    LightSeqTilt.Play SeqAllOff
End Sub

Sub LightSeqSkillshot_PlayDone()
    LightSeqSkillshot.Play SeqAllOff
End Sub

Sub TurnOffPlayfieldLights()
    Dim a
    For each a in aLights
        a.State = 0
    Next
End Sub

Sub ShowTableInfo
   Dim tmp
   'info goes in a loop only stopped by the credits and the startkey
   ' TODO: Add Game Of Thrones logo animation and move this to game-specific code
   If Score(1)Then
       DMD CL(0, "LAST SCORE"), CL(1, "PLAYER1 " &FormatScore(Score(1))), "", eNone, eNone, eNone, 3000, False, ""
   End If
   If Score(2)Then
       DMD CL(0, "LAST SCORE"), CL(1, "PLAYER2 " &FormatScore(Score(2))), "", eNone, eNone, eNone, 3000, False, ""
   End If
   If Score(3)Then
       DMD CL(0, "LAST SCORE"), CL(1, "PLAYER3 " &FormatScore(Score(3))), "", eNone, eNone, eNone, 3000, False, ""
   End If
   If Score(4)Then
       DMD CL(0, "LAST SCORE"), CL(1, "PLAYER4 " &FormatScore(Score(4))), "", eNone, eNone, eNone, 3000, False, ""
   End If
   DMD "", CL(1, "GAME OVER"), "", eNone, eNone, eNone, 2000, False, ""
   If bFreePlay Then
       DMD CL(0, "FREE PLAY"), CL(1, "PRESS START"), "", eNone, eNone, eNone, 2000, False, ""
   Else
       If Credits > 0 Then
           DMD CL(0, "CREDITS " & Credits), CL(1, "PRESS START"), "", eNone, eNone, eNone, 2000, False, ""
       Else
           DMD CL(0, "CREDITS " & Credits), CL(1, "INSERT COIN"), "", eNone, eNone, eNone, 2000, False, ""
       End If
   End If
   tmp = chr(35)&chr(36)&chr(37)
   DMD "", "", tmp, eNone, eNone, eNone, 3000, False, "" 'jpsalas presents
   tmp = chr(38)&chr(39)&chr(40)
   DMD "", "", tmp, eNone, eNone, eNone, 4000, False, "" 'title
   'DMD CL(0, "HIGHSCORES"), Space(dCharsPerLine(1)), "", eScrollLeft, eScrollLeft, eNone, 20, False, ""
   'DMD CL(0, "HIGHSCORES"), "", "", eBlinkFast, eNone, eNone, 1000, False, ""
   'DMD CL(0, "HIGHSCORES"), "1> " &HighScoreName(0) & " " &FormatScore(HighScore(0)), "", eNone, eScrollLeft, eNone, 2000, False, ""
   'DMD "_", "2> " &HighScoreName(1) & " " &FormatScore(HighScore(1)), "", eNone, eScrollLeft, eNone, 2000, False, ""
   'DMD "_", "3> " &HighScoreName(2) & " " &FormatScore(HighScore(2)), "", eNone, eScrollLeft, eNone, 2000, False, ""
   'DMD "_", "4> " &HighScoreName(3) & " " &FormatScore(HighScore(3)), "", eNone, eScrollLeft, eNone, 2000, False, ""
   'DMD Space(dCharsPerLine(0)), Space(dCharsPerLine(1)), "", eScrollLeft, eScrollLeft, eNone, 500, False, ""
End Sub

'**************************************
' Non-game-specific Light sequences
'**************************************

Sub LightEffect(n)
    Select Case n
        Case 0 ' all off
            LightSeqInserts.Play SeqAlloff
        Case 1 'all blink
            LightSeqInserts.UpdateInterval = 10
            LightSeqInserts.Play SeqBlinking, , 15, 10
        Case 2 'random
            LightSeqInserts.UpdateInterval = 10
            LightSeqInserts.Play SeqRandom, 50, , 1000
        Case 3 'all blink fast
            LightSeqInserts.UpdateInterval = 10
            LightSeqInserts.Play SeqBlinking, , 10, 10
        Case 4 'center fra lilDP
        ' TODO: Make this one not game-specific
            LightSeqlilDP.UpdateInterval = 4
            LightSeqlilDP.Play SeqCircleOutOn, 15, 2
        Case 5 'top down
            LightSeqPlayfield.UpdateInterval = 4
            LightSeqPlayfield.Play SeqDownOn, 15, 2
        Case 6 'down to top
            LightSeqPlayfield.UpdateInterval = 4
            LightSeqPlayfield.Play SeqUpOn, 15, 1
    End Select
End Sub

' *********************************************************************
'                      Drain / Plunger Functions
' *********************************************************************

' lost a ball :-( check to see how many balls are on the playfield.
' if only one then decrement the remaining count AND test for End of game
' if more than 1 ball (multi-ball) then kill of the ball but don't create
' a new one. This is not table-specific code - calls out to subs specific to this game
'
Sub Drain_Hit()
    ' Destroy the ball
    Drain.DestroyBall
    If bGameInPLay = False Then Exit Sub 'don't do anything, just delete the ball
    ' Exit Sub ' only for debugging - this way you can add balls from the debug window

    BallsOnPlayfield = BallsOnPlayfield - 1

    ' pretend to knock the ball into the ball storage mech
    PlaySoundAt "fx_drain", Drain
    'if Tilted the end Ball Mode
    If Tilted Then
        StopEndOfBallModes
    End If

    ' if there is a game in progress AND it is not Tilted
    If(bGameInPLay = True)AND(Tilted = False)Then

        ' is the ball saver active,
        If(bBallSaverActive = True)Then

            ' yep, create a new ball in the shooters lane
            ' we use the Addmultiball in case the multiballs are being ejected
            AddMultiball 1
            ' we kick the ball with the autoplunger
            bAutoPlunger = True
            ' you may wish to put something on a display or play a sound at this point
            DoBallSaved
        Else
            ' cancel any multiball if on last ball (ie. lost all other balls)
            If(BallsOnPlayfield-RealBallsInLock = 1)Then
                ' AND in a multi-ball??
                If(bMultiBallMode = True)then
                    ' not in multiball mode any more
                    bMultiBallMode = False
                    ' you may wish to change any music over at this point and

                    ' turn off any multiball specific lights
                    ChangeGi white
                    'stop any multiball modes
                    StopMBmodes
                End If
            End If

            ' was that the last ball on the playfield
            If(BallsOnPlayfield-RealBallsInLock = 0)Then
                ' End Mode and timers

                ChangeGi white
                ' Show the end of ball animation
                ' and continue with the end of ball
                ' DMD something?
                StopEndOfBallModes
                vpmtimer.addtimer 200, "EndOfBall '" 'the delay is depending of the animation of the end of ball, if there is no animation then move to the end of ball
            End If
        End If
    End If
End Sub

' The Ball has rolled out of the Plunger Lane and it is pressing down the trigger in the shooters lane
' Check to see if a ball saver mechanism is needed and if so fire it up.

Sub swPlungerRest_Hit()
    'debug.print "ball in plunger lane"
    ' some sound according to the ball position
    PlaySoundAt "fx_sensor", swPlungerRest
    bBallInPlungerLane = True
    ' turn on Launch light is there is one
    'LaunchLight.State = 2

    'be sure to update the Scoreboard after the animations, if any

    ' kick the ball in play if the bAutoPlunger flag is on
    If bAutoPlunger Then
        'debug.print "autofire the ball"
        vpmtimer.addtimer 1000, "PlungerIM.AutoFire:DOF 120, DOFPulse:PlaySoundAt ""fx_kicker"", swPlungerRest:bAutoPlunger = False '"
    End If
    'Start the Selection of the skillshot if ready
    If bSkillShotReady Then
        PlaySong "mu_shooterlane"
        UpdateSkillshot()
        ' show the message to shoot the ball in case the player has fallen sleep
        ' TODO: Should this only happen when SkillShot is lit? GoT LE has no skill shot
        SwPlungerCount = 0
        swPlungerRest.TimerEnabled = 1
    End If
    ' remember last trigger hit by the ball.
    LastSwitchHit = "swPlungerRest"
End Sub

' The ball is released from the plunger turn off some flags and check for skillshot

Sub swPlungerRest_UnHit()
    lighteffect 6
    bBallInPlungerLane = False
    swPlungerRest.TimerEnabled = 0 'stop the launch ball timer if active
    If bSkillShotReady Then
        ChangeSong
        ResetSkillShotTimer.Enabled = 1
    End If
    
    ' if there is a need for a ball saver, then start off a timer
    ' only start if it is ready, and it is currently not running, else it will reset the time period
    If(bBallSaverReady = True)AND(BallSaverTime <> 0)And(bBallSaverActive = False)Then
        EnableBallSaver BallSaverTime
    End If
' turn off LaunchLight
' LaunchLight.State = 0
End Sub

Sub EnableBallSaver(seconds)
    'debug.print "Ballsaver started"
    ' set our game flag
    bBallSaverActive = True
    bBallSaverReady = False
    ' start the timer
    BallSaverTimerExpired.Interval = 1000 * seconds
    BallSaverTimerExpired.Enabled = True
    BallSaverSpeedUpTimer.Interval = 1000 * seconds -(1000 * seconds) / 3
    BallSaverSpeedUpTimer.Enabled = True
    ' if you have a ball saver light you might want to turn it on at this point (or make it flash)
    LightShootAgain.BlinkInterval = 160
    LightShootAgain.State = 2
End Sub

' The ball saver timer has expired.  Turn it off AND reset the game flag
'
Sub BallSaverTimerExpired_Timer()
    'debug.print "Ballsaver ended"
    BallSaverTimerExpired.Enabled = False
    ' clear the flag
    bBallSaverActive = False
    ' if you have a ball saver light then turn it off at this point
    LightShootAgain.State = 0
End Sub

Sub BallSaverSpeedUpTimer_Timer()
    'debug.print "Ballsaver Speed Up Light"
    BallSaverSpeedUpTimer.Enabled = False
    ' Speed up the blinking
    LightShootAgain.BlinkInterval = 80
    LightShootAgain.State = 2
End Sub






















'******************************************
' Local game code starts here
'
'
'
'
'
'
'
'
'
'******************************************

Const Stark = 1
Const Baratheon = 2
Const Lannister = 3
Const Greyjoy = 4
Const Tyrell = 5
Const Martell = 6
Const Targaryen = 7


' Global table-specific variables
Dim PlayerMode          ' Current player's mode. 0=normal, -1 = select house, -2 = select battle, -3 = select mystery, 1 = in battle
Dim HouseColor(7)
Dim HouseSigil(7)
Dim HouseShield(7)
Dim SelectedHouse       ' Current Player's selected house


' TODO: Put this inside the House class
HouseColor = (white,white,yellow,red,purple,green,amber,blue)
' Assignment of centre field shields
HouseSigil = (li38,li38,li41,li44,li47,li50,li53,li32)
' Assignment of "shot" shields
HouseShield = (li141,li141,li26,li114,li86,li77,li156,li98)


' Global game-specific variables - saved across balls and between players

Dim PlayerHouse(4)  ' Each player's chosen starting house
Dim House(4)  ' Current state of each house - some house modes aren't saved, while others are. May need a Class to save detailed state

' Ball-specific variables (not saved across balls)
Dim PlayfieldMultiplierVal


' This class holds everything to do with House logic
Class cHouse
    Dim bSaid(7)             ' Whether the house's name has been said yet during ChooseHouse state
    Dim bQualified(7)        ' Whether the house has qualified for battle
    Dim bCompleted(7)        ' Whether battle has been completed
    Dim BattleState(7)      ' Placeholder for current battle state
    Dim QualifyCount(7)     ' Count of how many times the qualifying shot has been made for each house

    Private Sub Class_Initialize(  )
		dim i
		For i = 0 to 7
			bQualified(i) = False
            bCompleted(i) = False
            bSaid(i) = False
            QualifyCount(i) = 0
		Next
	End Sub

    Public Sub Say(h)
        Dim tmp
        if (Said(h)) Then tmp="" Else tmp="house-"
        PlaySoundVol "say-"&tmp&HouseToString(h), VolDef
    End Sub

    Public Sub StopSay(h)
        Dim tmp
        if (Said(h)) Then tmp="" Else tmp="house-"
        StopSound "say-"&tmp&HouseToString(h)
        Said(cHouse) = True
    End Sub

End Class

Function HouseToString(h)
    Select Case h
        Case Stark
            HouseToString = "stark"
        Case Baratheon
            HouseToString = "baratheon"
        Case Lannister
            HouseToString = "lannister"
        Case Greyjoy
            HouseToString = "greyjoy"
        Case Tyrell
            HouseToString = "tyrell"
        Case Martell
            HouseToString = "martell"
        Case Targaryen
            HouseToString = "targaryen"
End Function

'**************************************************
' Table, Game, and ball initialization code
'**************************************************

Sub VPObjects_Init
'   
End Sub

Sub Game_Init()     'called at the start of a new game
    Dim i, j
    TurnOffPlayfieldLights()
End Sub

' Initialise the Table for a new Game
'
Sub ResetForNewGame()
    Dim i

    bGameInPLay = True

    'resets the score display, and turn off attract mode
    StopAttractMode
    GiOn

    TotalGamesPlayed = TotalGamesPlayed + 1
    CurrentPlayer = 1
    PlayersPlayingGame = 1
    bOnTheFirstBall = True
    For i = 1 To MaxPlayers
        Score(i) = 0
        BonusPoints(i) = 0
        BonusHeldPoints(i) = 0
        BonusMultiplier(i) = 1
        BallsRemaining(i) = BallsPerGame
        PlayerHouse(i) = 0
        Set House(i) = New cHouse
    Next

    ' initialise any other flags
    Tilt = 0

    ' initialise Game variables
    Game_Init()

    ' you may wish to start some music, play a sound, do whatever at this point

    vpmtimer.addtimer 1500, "FirstBall '"
End Sub

' This is used to delay the start of a game to allow any attract sequence to
' complete.  When it expires it creates a ball for the player to start playing with

Sub FirstBall
    ' reset the table for a new ball
    ResetForNewPlayerBall()
    ' create a new ball in the shooters lane
    CreateNewBall()
End Sub

' (Re-)Initialise the Table for a new ball (either a new ball after the player has
' lost one or we have moved onto the next player (if multiple are playing))

Sub ResetForNewPlayerBall()
    ' make sure the correct display is upto date
    AddScore 0

    ' set the current players bonus multiplier back down to 1X
    SetBonusMultiplier 1

    ' reduce the playfield multiplier
    ' reset any drop targets, lights, game Mode etc..

    BonusPoints(CurrentPlayer) = 0
    bBonusHeld = False

    'Reset any table specific
    ResetNewBallVariables

    'This is a new ball, so activate the ballsaver
    bBallSaverReady = True

    'and the skillshot
    bSkillShotReady = True

    if (PlayerHouse(CurrentPlayer) = 0) Then
        PlayerMode = -1
    Else 
        PlayerMode = 0
    End If
        

'Change the music ?
End Sub

Sub ResetNewBallVariables() 'reset variables for a new ball or player
    dim i
    'turn on or off the needed lights before a new ball is released
    TurnOffPlayfieldLights
    ResetDropTargets
    'playfield multipiplier
    pfxtimer.Enabled = 0
    PlayfieldMultiplierVal = 1
    UpdatePFXLights(PlayfieldMultiplierVal)
    ' TODO: Update playfield lights to their correct status based on current player and state
End Sub

' Create a new ball on the Playfield

Sub CreateNewBall()
    ' create a ball in the plunger lane kicker.
    BallRelease.CreateSizedBallWithMass BallSize / 2, BallMass

    ' There is a (or another) ball on the playfield
    BallsOnPlayfield = BallsOnPlayfield + 1

    ' kick it out..
    PlaySoundAt SoundFXDOF("fx_Ballrel", 123, DOFPulse, DOFContactors), BallRelease
    BallRelease.Kick 90, 4

' if there is 2 or more balls then set the multiball flag (remember to check for locked balls and other balls used for animations)
' set the bAutoPlunger flag to kick the ball in play automatically
    If (BallsOnPlayfield-RealBallsInLock > 1) Then
        DOF 143, DOFPulse
        bMultiBallMode = True
        bAutoPlunger = True
    End If
End Sub


' TODO: Add ball-saved animation and sound
Sub DoBallSaved
    DMD "", CL(1, "BALL SAVED"), "", eNone, eNone, eNone, 1000, True, ""
End Sub

Sub AddScore(points)
    ' if there is a need for a ball saver, then start off a timer
    ' only start if it is ready, and it is currently not running, else it will reset the time period
    ResetBallSearch
    If (Tilted = False) Then
        If(bBallSaverReady = True)AND(BallSaverTime <> 0)And(bBallSaverActive = False)Then
            EnableBallSaver BallSaverTime
        End If

        ' TODO: If in a mode (HOTK, Wizard, or 1 of 3 multiball modes), track the points earned in this mode

        Score(CurrentPlayer) = Score(CurrentPlayer) + points * PlayfieldMultiplierVal	'only for this table

        ' update the score displays
        DMDScore

    End If
    


End Sub

sub ResetBallSearch()
	if BallSearchResetting then Exit Sub	' We are resetting jsut exit for now 
	'debug.print "Ball Search Reset"
	tmrBallSearch.Enabled = False	' Reset Ball Search
	BallSearchCnt=0
	tmrBallSearch.Enabled = True
End Sub 

dim BallSearchResetting:BallSearchResetting=False
Sub tmrBallSearch_Timer()	' We timed out
	' See if we are in mode select, a flipper is up that might be holding the ball or a ball is in the lane 

	'debug.print "Ball Search"

	if bGameInPlay and _ 
		tmrEndOfBallBonus.Enabled = False and _
		bBallInPlungerLane = False and _
		LeftFlipper.CurrentAngle <> LeftFlipper.EndAngle and _
		RightFlipper.CurrentAngle <> RightFlipper.EndAngle Then

		debug.print "Ball Search - NO ACTIVITY " & BallSearchCnt

		if BallSearchCnt >= 3 Then
			dim Ball
			debug.print "--- listing balls ---"
			For each Ball in GetBalls
				Debug.print "Ball: (" & Ball.x & "," & Ball.y & ")"
			Next
			debug.print "--- listing balls ---"

'	        TBD Might want to implement this
'			BallsOnPlayfield = 0
'			for each Ball in GetBalls
'				Ball.DestroyBall
'			Next


			BallSearchCnt = 0
			if BallsOnPlayfield > 0 then 	' somehow we might have drained and didnt catch it??
				BallsOnPlayfield = BallsOnPlayfield - 1  ' We cant find the ball (remove one)
			End if
			AddMultiball(1)
			DisplayDMDText "BALL SEARCH FAIL","", 1000
			Exit sub
		End if

		BallSearchResetting=True
		BallSearchCnt = BallSearchCnt + 1
		DisplayDMDText "BALL SEARCH","", 1000
		'if OrbTarget1Disabled.Collidable then  ' They didnt hit the drop target so drop it for them and let the ball go
		'	OrbTarget1Disabled.Collidable = False
		'	OrbTarget1.IsDropped = True
		'	vpmtimer.addtimer 1500, "OrbTargetReset:OrbTarget1Disabled.Collidable = True '"
		'Else 
		'	OrbTarget1.IsDropped = True
		'	vpmtimer.addtimer 1500, "OrbTargetReset '"
		'End If
		'leftScoop.Kick 150, 25
		DOF 123, DOFPulse
		'RocketKicker.Kick 165, 90
		DOF 113, DOFPulse
		DOF 112, DOFPulse
		vpmtimer.addtimer 3000, "BallSearchResetting = False '"
	Else 
		ResetBallSearch
	End if 
End Sub 

'************************************
' End of ball/game processing
'************************************

' The Player has lost his ball (there are no more balls on the playfield).
' Handle any bonus points awarded
Dim tmpBonusTotal
dim bonusCnt
Sub tmrEndOfBallBonus_Timer()
    ' TODO: This is where we'll add up the ball's total bonus. Look at GOTG line 2549 onwards for a good example
    vpmtimer.addtimer 200, "EndOfBall2 '"
End Sub

Sub EndOfBall()
    Dim AwardPoints, TotalBonus, ii
    AwardPoints = 0
    TotalBonus = 0
    ' the first ball has been lost. From this point on no new players can join in
    bOnTheFirstBall = False
	
    'TODO: Stop any playfield timers

    ' only process any of this if the table is not tilted.  (the tilt recovery
    ' mechanism will handle any extra balls or end of game)

    If(Tilted = False)Then

        ' Count the bonus. This table uses several bonus
        DMDflush

		'if bUsePupDMD then PuPlayer.LabelShowPage pBonusScreen,1,0,"":PuPlayer.LabelShowPage pBackglass, 2,0,""
		
		'pDMDEvent(kDMD_BonusBG)
		'playmedia "Video-0x007A-2.mp4", "PupVideos", pBonusScreen, "", -1, "", 1, 1
		'This command merged Black and White background with video 
		'    ffmpeg -i Video-0x007A.mp4  -i BonusScreen-BW2.png -filter_complex "[1:v]scale=1360:768 [ovrl],[0:v][ovrl]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2" -strict -2 ./output.mp4


        ' add a bit of a delay to allow for the bonus points to be shown & added up
		tmrEndOfBallBonus.Interval = 800
		tmrEndOfBallBonus.UserValue = 0		' Timer will start EndOfBall2 when it is done
		tmrEndOfBallBonus.Enabled = true
    Else
        vpmtimer.addtimer 100, "EndOfBall2 '"
    End If
End Sub

' The Timer which delays the machine to allow any bonus points to be added up
' has expired.  Check to see if there are any extra balls for this player.
' if not, then check to see if this was the last ball (of the currentplayer)
'
Sub EndOfBall2()
	dim i
	dim thisMode
    ' if were tilted, reset the internal tilted flag (this will also
    ' set TiltWarnings back to zero) which is useful if we are changing player LOL
    Tilted = False
    Tilt = 0
    DisableTable False 'enable again bumpers and slingshots


    ' has the player won an extra-ball ? (might be multiple outstanding)
    If(ExtraBallsAwards(CurrentPlayer) <> 0) and bBallInPlungerLane=False Then	' Save Extra ball for later if there is a ball in the plunger lane
        debug.print "Extra Ball"

        ' yep got to give it to them
        ExtraBallsAwards(CurrentPlayer) = ExtraBallsAwards(CurrentPlayer)- 1

        ' if no more EB's then turn off any shoot again light
        If(ExtraBallsAwards(CurrentPlayer) = 0)Then
            LightShootAgain.State = 0
        End If

        ' You may wish to do a bit of a song AND dance at this point
        DMD "_", CL(1, ("EXTRA BALL")), "_", eNone, eBlink, eNone, 1000, True, "vo_extraball"

        'TODO: Extra ball song and dance
		'if INT(RND * 2) = 0 then 
		'	pDMDEvent(kDMD_ExtraBall)
		'Else
		'	pDMDEvent(kDMD_ShootAgain)
		'End If 

        ' Create a new ball in the shooters lane
        CreateNewBall()
    Else ' no extra balls

        BallsRemaining(CurrentPlayer) = BallsRemaining(CurrentPlayer)- 1

        ' was that the last ball ?
        If(BallsRemaining(CurrentPlayer) <= 0) Then				' GAME OVER
            debug.print "No More Balls, High Score Entry"
			'if bUsePupDMD then 
			'	PuPlayer.PlayStop pOverVid						' Stop overlay if there is one
			'	PuPlayer.SetLoop pOverVid, 0
			'End If

            'TODO: End of game music/video

			' Turn off DOF so we dont accidently leave it on
			PlaySoundAt SoundFXDOF("fx_flipperdown", 101, DOFOff, DOFFlippers), LeftFlipper
			LeftFlipper.RotateToStart
            LeftUFlipper.RotateToStart

			PlaySoundAt SoundFXDOF("fx_flipperdown", 102, DOFOff, DOFFlippers), RightFlipper
			RightFlipper.RotateToStart
			RightUFlipper.RotateToStart

            ' Submit the currentplayers score to the High Score system
            CheckHighScore()
			' you may wish to play some music at this point
        Else
            ' not the last ball (for that player)
            ' if multiple players are playing then move onto the next one
            EndOfBallComplete()
        End If
    End If
End Sub

' This function is called when the end of bonus display
' (or high score entry finished) AND it either end the game or
' move onto the next player (or the next ball of the same player)
'all of the same player)
'
Sub EndOfBallComplete()
    Dim NextPlayer
	dim Match

    debug.print "EndOfBall - Complete"

    ' are there multiple players playing this game ?
    If(PlayersPlayingGame > 1)Then
        ' then move to the next player
        NextPlayer = CurrentPlayer + 1
        ' are we going from the last player back to the first
        ' (ie say from player 4 back to player 1)
        If(NextPlayer > PlayersPlayingGame-1)Then
            NextPlayer = 0
        End If
    Else
        NextPlayer = CurrentPlayer
    End If

    debug.print "Next Player = " & NextPlayer

    ' is it the end of the game ? (all balls been lost for all players)
    If((BallsRemaining(CurrentPlayer) <= 0)AND(BallsRemaining(NextPlayer) <= 0))Then
        ' you may wish to do some sort of Point Match free game award here
        ' generally only done when not in free play mode

		DisplayDMDText2 "_", "GAME OVER", 20000, 5, 0
		bGameInPLay = False									' EndOfGame sets this but need to set early to disable flippers 
		bShowMatch = True

		' Do Match end score code
		Match=10 * INT(RND * 9)
		'Match = Score(CurrentPlayer) mod 100		' Force Match for testing 
		'If Score(CurrentPlayer) mod 100 = Match Then
		if BigMod(Score(CurrentPlayer), 100) = Match then									' Handles large scores 
			vpmtimer.addtimer 6000, "PlayYouMatched '"
		End If
		'if Match = 0 then 
	'		playmedia "Match-00.mp4", "PupVideos", pOverVid, "", -1, "", 1, 1
		'Else
		'	playmedia "Match-"&Match&".mp4", "PupVideos", pOverVid, "", -1, "", 1, 1
		'End If
		'vpmtimer.addtimer 100, "PlaySoundVol ""Match-Score"", VolDef '"
        ' set the machine into game over mode
		'if osbactive <> 0 then 	' Orbital takes more time 
		'	vpmtimer.addtimer 9000, "if bShowMatch then EndOfGame() '"
		'else 
			vpmtimer.addtimer 8000, "if bShowMatch then EndOfGame() '"
		'End If 

    ' you may wish to put a Game Over message on the desktop/backglass

    Else
        ' set the next player
		'PlayerState(CurrentPlayer).bFirstBall = False
		'PlayerState(CurrentPlayer).Save 
        CurrentPlayer = NextPlayer
		'UpdateNumberPlayers				' Update the Score Sizes
        ' make sure the correct display is up to date
        AddScore 0

        ' reset the playfield for the new player (or new ball)
        ResetForNewPlayerBall()

		'PlayerState(CurrentPlayer).Restore

        ' AND create a new ball
        CreateNewBall()

        ' play a sound if more than 1 player
        If PlayersPlayingGame > 1 Then
            'TODO: Add player <X> sound
            'PlaySoundVol "say-player" &CurrentPlayer+1, VolDef
            DMD "", CL(1, "PLAYER " &CurrentPlayer+1), "", eNone, eNone, eNone, 800, True, ""
        End If
    End If
End Sub

' This function is called at the End of the Game, it should reset all
' Drop targets, AND eject any 'held' balls, start any attract sequences etc..

Sub EndOfGame()
    debug.print "End Of Game"	
	
    bGameInPLay = False	
	bShowMatch = False
	tmrBallSearch.Enabled = False
    
    ' ensure that the flippers are down
    SolLFlipper 0
    SolRFlipper 0

	' Drop the lock walls just in case the ball is behind it (just in Case)
	SwordWall.collidable = False
    LockWall.collidable = False
	vpmtimer.addtimer 1000, "LockWallReset'"

    ' terminate all modes - eject locked balls
    ' most of the modes/timers terminate at the end of the ball

	'PlaySong "m_end"
	'playmedia "m_end.mp3", MusicDir, pAudio, "", -1, "", 1, 1

    ' set any lights for the attract mode
    GiOff
	'bFlash1Enabled = True
	'bFlash2Enabled = True
	'bFlash3Enabled = True
	'bFlash4Enabled = True

' you may wish to light any Game Over Light you may have
End Sub

Sub PlayYouMatched
    'TODO: Play a 'Matched!' sound/video
	'PlaySoundVol "YouMatchedPlayAgain", VolDef
	DOF 140, DOFOn
	DMDFlush
	DMD "_", CL(1, "CREDITS: " & Credits), "", eNone, eNone, eNone, 500, True, "fx_coin"
End Sub 

' Set the virtual lock wall ready to lock a ball
Sub LockWallReset
    SwordWall.collidable = False
    LockWall.collidable = True
End Sub



' Add extra balls to the table with autoplunger
' Use it as AddMultiball 4 to add 4 extra balls to the table

Sub AddMultiball(nballs)
    mBalls2Eject = mBalls2Eject + nballs
    CreateMultiballTimer.Enabled = True
End Sub
Sub AddMultiballFast(nballs)
	if CreateMultiballTimer.Enabled = False then 
		CreateMultiballTimer.Interval = 100		' shortcut the first time through 
	End If 
   AddMultiball(nballs)
End Sub

' Eject the ball after the delay, AddMultiballDelay
Sub CreateMultiballTimer_Timer()
    ' wait if there is a ball in the plunger lane
	CreateMultiballTimer.Interval = 2000
    If bBallInPlungerLane Then
        Exit Sub
    Else
        If BallsOnPlayfield < MaxMultiballs Then
            CreateNewBall()
            mBalls2Eject = mBalls2Eject -1
            If mBalls2Eject = 0 Then 'if there are no more balls to eject then stop the timer
                Me.Enabled = False
            End If
        Else 'the max number of multiballs is reached, so stop the timer
            mBalls2Eject = 0
            Me.Enabled = False
        End If
    End If
End Sub

Sub StopEndOfBallModes() 'this sub is called after the last ball is drained

End Sub

' Called when the last ball of multiball is lost
Sub StopMBmodes
' TODO: Need to do anything here? E.g.
'  - reset lighting
'  - restore pre-mb state?
End Sub

Sub ResetDropTargets
    ' PlaySoundAt "fx_resetdrop", Target010
    If Target7.IsDropped OR Target8.IsDropped OR Target9.IsDropped Then
        PlaySoundAt SoundFXDOF("fx_resetdrop", 119, DOFPulse, DOFcontactors), Target8
        Target7.IsDropped = 0
        Target8.IsDropped = 0
        Target9.IsDropped = 0
    End If
    ' TODO: Set LoL target lights based on how many times bank has been completed
End Sub

Sub GameGiOn
    PlaySoundAt "fx_GiOn", li108 'about the center of the table
    Fi001.Visible = 1
    Fi002.Visible = 1
    Fi003.Visible = 1
    Fi004.Visible = 1
    Fi005.Visible = 1
    Fi006.Visible = 1
End Sub

Sub GameGiOff
    PlaySoundAt "fx_GiOff", li108 'about the center of the table
    Fi001.Visible = 0
    Fi002.Visible = 0
    Fi003.Visible = 0
    Fi004.Visible = 0
    Fi005.Visible = 0
    Fi006.Visible = 0
End Sub

' Set the Bonus Multiplier to the specified level AND set any lights accordingly
' There is no bonus multiplier lights in this table

Sub SetBonusMultiplier(Level)
    ' Set the multiplier to the specified level
    BonusMultiplier(CurrentPlayer) = Level
End Sub

Sub UpdatePFXLights(Level)
    ' Update the playfield multiplier lights
    Select Case Level
        Case 1:li56.State = 0:li59.State = 0:li62.State = 0:li65.State = 0
        Case 2:li56.State = 1:li59.State = 0:li62.State = 0:li65.State = 0
        Case 3:li56.State = 1:li59.State = 1:li62.State = 0:li65.State = 0
        Case 4:li56.State = 1:li59.State = 1:li62.State = 1:li65.State = 0
        Case 5:li56.State = 1:li59.State = 1:li62.State = 1:li65.State = 1
    End Select
' show the multiplier in the DMD?
End Sub

Sub CheckActionButton
'TODO
End Sub


' Check for key presses specific to this game.
' If PlayerMode is < 0, in a 'Select' state, so use flippers to toggle
Function CheckLocalKeydown(ByVal keycode)
    if PlayerMode < 0 and (keycode = LeftFlipperKey or keycode = RightFlipperKey) Then
        CheckLocalKeydown = True
        if PlayerMode = -1 Then ChooseHouse(keycode)
        ElseIf PlayerMode = -2 Then ChooseBattle(keycode)
        Else ChooseMystery(keycode)
        End If    
    Else
        CheckLocalKeydown = False
End Function


Sub ChooseHouse(ByVal keycode)
    If keycode = LeftFlipperKey Then
        FlashShields(SelectedHouse,False)
        House(CurrentPlayer).StopSay(SelectedHouse)
        If SelectedHouse = Stark Then 
            SelectedHouse = Targaryen
        Else
            SelectedHouse = SelectedHouse - 1
        End If
        FlashShields(SelectedHouse,True)
        House(CurrentPlayer).Say(SelectedHouse)
    ElseIf keycode = RightFlipperKey Then
        FlashShields(SelectedHouse,False)
        House(CurrentPlayer).StopSay(SelectedHouse)
        If SelectedHouse = Targaryen Then 
            SelectedHouse = Stark
        Else
            SelectedHouse = SelectedHouse + 1
        End If
        FlashShields(SelectedHouse,True)
        House(CurrentPlayer).Say(SelectedHouse)
    End If
End Sub


Sub FlashShields(h,State)
    if State Then
        SetLightColor(HouseSigil(h),HouseColor(h),2)
        SetLightColor(HouseShield(h),HouseColor(h),2)
    Else
        HouseSigil(h).State = 0
        HouseShield(h).State = 0
    Else
        
End Sub





Sub ChooseBattle(ByVal keycode)
'TODO: implemement battle mode
End Sub

Sub ChooseMystery(ByVal keycode)
'TODO: implement mystery selection
End Sub






















'*****************
' PinUP Support
'*****************

Class PinupNULL	' Dummy Pinup class so I dont have to keep adding if cases when people dont choose pinup
	Public Sub LabelShowPage(screen, pagenum, vis, Special)
	End Sub
	Public Sub LabelSet(screen, label, text, vis, Special)
	End Sub
	Public Sub playlistplayex(screen, dir, fname, volume, priority)
	End Sub 
End Class 