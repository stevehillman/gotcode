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
Const BallMass = 1.5    ' standard ball mass in JP's VPX Physics 3.0

'***********TABLE VOLUME LEVELS ********* 
' [Value is from 0 to 1 where 1 is full volume. 
' NOTE: you can go past 1 to amplify sounds]

' Desktop Volumes
'Const VolBGMusic = 0.5  ' Volume for Video Clips   
'Const VolMusic1 = 0.4	' Volume for Cleland or Original Gameplay music
' Cab Volumes
Const VolBGMusic = 0.15  ' Volume for Video Clips   
Const VolMusic1 = 0.7	' Volume forOriginal Gameplay music

Const VolDef = 0.9		' Default volume for callouts 
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
Const BallSaverTime = 2000      ' in seconds of the first ball
Const MaxMultiplier = 5       ' limit playfield multiplier
Const MaxBonusMultiplier = 50 'limit Bonus multiplier
Const BallsPerGame = 3        ' usually 3 or 5
Const MaxMultiballs = 5       ' max number of balls during multiballs

'*****************************************************************************************************
' FlexDMD constants
Const 	FlexDMD_RenderMode_DMD_GRAY_2 = 0, _
		FlexDMD_RenderMode_DMD_GRAY_4 = 1, _
		FlexDMD_RenderMode_DMD_RGB = 2, _
		FlexDMD_RenderMode_SEG_2x16Alpha = 3, _
		FlexDMD_RenderMode_SEG_2x20Alpha = 4, _
		FlexDMD_RenderMode_SEG_2x7Alpha_2x7Num = 5, _
		FlexDMD_RenderMode_SEG_2x7Alpha_2x7Num_4x1Num = 6, _
		FlexDMD_RenderMode_SEG_2x7Num_2x7Num_4x1Num = 7, _
		FlexDMD_RenderMode_SEG_2x7Num_2x7Num_10x1Num = 8, _
		FlexDMD_RenderMode_SEG_2x7Num_2x7Num_4x1Num_gen7 = 9, _
		FlexDMD_RenderMode_SEG_2x7Num10_2x7Num10_4x1Num = 10, _
		FlexDMD_RenderMode_SEG_2x6Num_2x6Num_4x1Num = 11, _
		FlexDMD_RenderMode_SEG_2x6Num10_2x6Num10_4x1Num = 12, _
		FlexDMD_RenderMode_SEG_4x7Num10 = 13, _
		FlexDMD_RenderMode_SEG_6x4Num_4x1Num = 14, _
		FlexDMD_RenderMode_SEG_2x7Num_4x1Num_1x16Alpha = 15, _
		FlexDMD_RenderMode_SEG_1x16Alpha_1x16Num_1x7Num = 16

Const 	FlexDMD_Align_TopLeft = 0, _
		FlexDMD_Align_Top = 1, _
		FlexDMD_Align_TopRight = 2, _
		FlexDMD_Align_Left = 3, _
		FlexDMD_Align_Center = 4, _
		FlexDMD_Align_Right = 5, _
		FlexDMD_Align_BottomLeft = 6, _
		FlexDMD_Align_Bottom = 7, _
		FlexDMD_Align_BottomRight = 8

Const   UltraDMD_Animation_None = 14
Dim FlexDMD
'********* End FlexDMD **************


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
Dim LastSwitchHit

' flags
Dim bMultiBallMode
Dim bAutoPlunger
Dim bAutoPlunged
Dim bBallSaved
Dim bInstantInfo
Dim bAttractMode
Dim bFreePlay
Dim bGameInPlay
Dim bOnTheFirstBall
Dim bBallInPlungerLane
Dim bBallSaverActive
Dim bBallSaverReady
Dim bTableReady
Dim	bUseFlexDMD
Dim	bUsePUPDMD
Dim	bPupStarted
Dim bBonusHeld
Dim bJustStarted            ' Not sure what this is used for
Dim bShowMatch
Dim bSkillShotReady


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
	bUseFlexDMD=False
	bUsePUPDMD=False
	bPupStarted=False
	if DMDMode = 1 then 
		bUseFlexDMD= True
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

Private Function BigMod(Value1, Value2)
    BigMod = Value1 - (Int(Value1 / Value2) * Value2)
End Function

Sub Table1_Exit()
    If Not FlexDMD is Nothing Then
		FlexDMD.Show = False
		FlexDMD.Run = False
		FlexDMD = NULL
    End If
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
				CheckActionButton				
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

' Play an already playing sound (starts anew if not playing). Restart=whether to restart the sound. Presumably 0 = just let it keep playing
Sub PlayExistingSoundVol(soundname, Volume, Restart)
  PlaySound soundname, 1, Volume, 0, 0, 0, 1, Restart
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
Const maxvel = 60 'max ball velocity
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
'Sub aTriggers_Hit(idx):PlaySfx:End Sub

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
        Case 3:LeftSLing2.Visible = 0:LeftSling1.Visible = 1:Lemk.RotX = -10:LeftSlingShot.TimerEnabled = False
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
        Case 3:RightSLing2.Visible = 0:RightSLing1.Visible = 1:Remk.RotX = -10:RightSlingShot.TimerEnabled = False
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
' DMD Support. Updated to FlexDMD-specific API calls
' and eventually PuP
'******************************************************** 

Const eNone = 0        ' Instantly displayed

Dim FlexPath
Dim UltraDMD
Sub LoadFlexDMD
    Dim curDir
	Set FlexDMD = CreateObject("FlexDMD.FlexDMD")
    If FlexDMD is Nothing Then
        MsgBox "No FlexDMD found. This table will not be as good without it."
        bUseFlexDMD = False
        Exit Sub
    End If
	SetLocale(1033)
	With FlexDMD
		.GameName = cGameName
		.TableFile = Table1.Filename & ".vpx"
		.Color = RGB(255, 88, 32)
		.RenderMode = FlexDMD_RenderMode_DMD_GRAY_4
		.Width = 128
		.Height = 32
		.Clear = True
		.Run = True
	End With	

    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    curDir = fso.GetAbsolutePathName(".")
    FlexPath = curDir & "\"&cGameName &".FlexDMD\"

    ' Let's try this while we transition to FlexDMD
    Set UltraDMD = FlexDMD.NewUltraDMD()
End Sub

Sub DMD_Clearforhighscore()
	DMDClearQueue
End Sub

Sub DMDClearQueue				
	if bUseFlexDMD Then
		DMDqHead=0:DMDqTail=0
        FlexDMD.Stage.RemoveAll
        bDefaultScene = False
        DisplayingScene = Empty
	End If
End Sub

Sub PlayDMDScene(video, timeMs)
	if bUseFlexDMD and UltraDMDVideos Then
		' Note Video needs to not have sounds and must be more then 3 seconds (Export from iMovie, I chose 540p, high quality, Faster compression.
		UltraDMD.DisplayScene00 video, "", 15, "", 15, UltraDMD_Animation_None, timeMs, UltraDMD_Animation_None
		'UltraDMD.DisplayScene00ExWithId video, False, video, "", 15, 15, "", 15, 15, 14, 4000, 14
	End If
End Sub

Sub DisplayDMDText(Line1, Line2, duration)
	debug.print "OldDMDText " & Line1 & " " & Line2
	if bUseFlexDMD Then
		UltraDMD.DisplayScene00 "", Line1, 15, Line2, 15, 14, duration, 14
	Elseif bUsePUPDMD Then
		If bPupStarted then 
			if Line1 = "" or Line1 = "_" then 
				pupDMDDisplay "-", Line2, "" ,Duration/1000, 0, 10
			else
				pupDMDDisplay "-", Line1 & "^" & Line2, "" ,Duration/1000, 0, 10
			End If 
		End If
    Else
        'TODO: Display on built-in DMD device 
	End If
End Sub

Sub DisplayDMDText2(Line1, Line2, duration, pri, blink)
	if bUseFlexDMD Then
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
	if bUseFlexDMD then 
		UltraDMD.DisplayScene00ExwithID id, false, "", toptext, 15, 0, bottomtext, 15, 0, 14, duration, 14
	Elseif bUsePUPDMD Then
		If bPupStarted then pupDMDDisplay "default", toptext & "^" & bottomtext, "" ,Duration/1000, 0, 10
	End If 
End Sub

Sub DMDMod(id, toptext, bottomtext, duration) 'used in the highscore entry routine
	if bUseFlexDMD then 
		UltraDMD.ModifyScene00Ex id, toptext, bottomtext, duration
	Elseif bUsePUPDMD Then
		If bPupStarted then pupDMDDisplay "default", toptext & "^" & bottomtext, "" ,Duration/1000, 0, 10
	End If 
End Sub


Dim dCharsPerLine(2)
Dim dLine(2)

Sub DMD_Init() 'default/startup values
    Dim i, j

	if bUseFlexDMD then LoadFlexDMD()

    DMDFlush()
    dCharsPerLine(0) = 12
    dCharsPerLine(1) = 12
    dCharsPerLine(2) = 12
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

	if bUseFlexDMD Then 
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
			DisplayDMDText RL(0,FormatScore(Score(CurrentPlayer))), "", 1000 
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


'*************************
' FlexDMD Queue Management
'*************************
'
' FlexDMD supports queued scenes using its built-in Sequence class. However, there's no way to set priorities
' to allow new scenes to override playing scenes. In addition, there's no support for 'minimum play time' vs
' 'total play time', or for playing a sound with a scene. We want the ability to let a scene of a given priority play for at least 'minimum play time'
' as long as no scene of higher priority gets queued. If another scene of equal priority is queued, the playing scene
' will be replaced once it has played for 'minimum play time' ms.
' Queued higher priority scenes immediately replace playing lower priority scenes
' When no scenes are queued, show default scene (Score, "Choose..." or GameOver)
'
' If a scene gets queued that would take too long before it can be played due to items ahead of it, it gets dropped

Dim DMDSceneQueue(64,6)     ' Queue of scenes. Each entry has 7 fields: 0=Scene, 1=priority, 2=mintime, 3=maxtime, 4=waittime, 5=optionalSound, 6=timestamp
Dim DMDqHead,DMDqTail
Dim DMDtimestamp

'Queue up a FlexDMD scene in a virtual queue. 

Sub DMDEnqueueScene(scene,pri,mint,maxt,waitt,sound)
    Dim i
    If bDefaultScene = False And Not IsEmpty(DisplayingScene) Then
        If DisplayingScene is scene Then
            ' Already playing. Update it
            DMDSceneQueue(DMDqHead,1) = pri
            DMDSceneQueue(DMDqHead,2) = mint
            DMDSceneQueue(DMDqHead,3) = maxt
            DMDSceneQueue(DMDqHead,4) = DMDtimestamp + waitt
            DMDSceneQueue(DMDqHead,5) = sound
            DMDSceneQueue(DMDqHead,6) = DMDtimestamp
            Exit Sub
        End If
    End If

    ' Check to see whether the scene is worth queuing
    If Not DMDCheckQueue(pri,waitt) Then 
        debug.print "Discarding scene request with priority " & pri & " and waitt "&waitt
        Exit Sub
    End If

    ' Check to see if this is an update to an existing queued scene (e.g pictopops)
    Dim found:found=False
    If DMDqTail <> 0 Then
        For i = DMDqHead to DMDqTail-1
            If DMDSceneQueue(i,0) Is scene Then 
                Found=True
                debug.print "Updating existing scene "&i
                Exit For
            End If
        Next
    End If
    'Otherwise add to end of queue
    If Not Found Then i = DMDqTail:DMDqTail = DMDqTail + 1
    Set DMDSceneQueue(i,0) = scene
    DMDSceneQueue(i,1) = pri
    DMDSceneQueue(i,2) = mint
    DMDSceneQueue(i,3) = maxt
    DMDSceneQueue(i,4) = DMDtimestamp + waitt
    DMDSceneQueue(i,5) = sound
    DMDSceneQueue(i,6) = 0
    If DMDqTail > 64 Then       ' Ran past the end of the queue!
        debug.print "DMDSceneQueue too big! Discarding new queued items"
        DMDqTail = 64
    End if
    debug.print "Enqueued scene at "&i
End Sub

' Check the queue to see whether a scene willing to wait 'waitt' time would play
Function DMDCheckQueue(pri,waitt)
    Dim i,wait:wait=0
    If DMDqTail=0 Then DMDCheckQueue = True: Exit Function
    DMDCheckQueue = False
    For i = DMDqHead to DMDqTail
        If DMDSceneQueue(i,4) > DMDtimestamp Then 
            If DMDSceneQueue(i,1) = pri Then        'equal priority queued scene
                wait = wait + DMDSceneQueue(i,2)    ' so use mintime
            ElseIf DMDSceneQueue(i,1) < pri Then    'higher priority queued scene
                wait = wait + DMDSceneQueue(i,3)
            End If
            If wait > waitt Then Exit Function
        End If
        
    Next
    DMDCheckQueue = True
End Function
            
' Update DMD Scene. Called every 100ms
' Most of the work is done here. If scene queue is empty, display default scene (score, Game Over, etc)
' If scene queue isn't empty, check to see whether current scene has been on long enough or overwridden by a higher priority scene
' If it has, move to next spot in queue and search all of the queue for scene with highest priority, skipping any scenes that have timed out while waiting
Dim bDefaultScene,DefaultScene
Sub tmrDMDUpdate_Timer
    Dim i,j,bHigher,bEqual
    DMDtimestamp = DMDtimestamp + 100   ' Set this to whatever frequency the timer uses
    If DMDqTail = 0 Then ' Queue is empty - show default scene
        ' Exit fast if defaultscene is already showing
        if bDefaultScene or IsEmpty(DefaultScene) then Exit Sub
        bDefaultScene = True
        If TypeName(DefaultScene) = "Object" Then
            DMDDisplayScene DefaultScene
        Else
            debug.print "DefaultScene is not an object!"
        End If
    Else
        ' Process queue
        ' Check to see if queue is idle (default scene on). If so, immediately play first item
        If bDefaultScene or (IsEmpty(DisplayingScene) And DMDqHead = 0) Then
            bDefaultScene = False
            debug.print "Displaying scene at " & DMDqHead
            DMDDisplayScene DMDSceneQueue(DMDqHead,0)
            DMDSceneQueue(DMDqHead,6) = DMDtimestamp
            If DMDSceneQueue(DMDqHead,5) <> ""  Then PlaySoundVol DMDSceneQueue(DMDqHead,5),VolDef
        Else
            ' Check to see whether there are any queued scenes with equal or higher priority than currently playing one
            bEqual = False: bHigher = False
            If DMDqTail > DMDqHead+1 Then
                For i = DMDqHead+1 to DMDqTail-1
                    If DMDSceneQueue(i,1) < DMDSceneQueue(DMDqHead,1) Then bHigher=True:Exit For
                    If DMDSceneQueue(i,1) = DMDSceneQueue(DMDqHead,1) Then bEqual = True:Exit For
                Next
            End If
            If bHigher Or (bEqual And (DMDSceneQueue(DMDqHead,6)+DMDSceneQueue(DMDqHead,2) <= DMDtimestamp)) Or _ 
                    (DMDSceneQueue(DMDqHead,6)+DMDSceneQueue(DMDqHead,3) <= DMDtimestamp) Then 'Current scene has played for long enough

                ' Skip over any queued scenes whose wait times have expired
                Do 
                    DMDqHead = DMDqHead+1
                Loop While DMDSceneQueue(DMDqHead,4) < DMDtimestamp And DMDqHead < DMDqTail
                    
                If DMDqHead > 64 Then       ' Ran past the end of the queue!
                    debug.print "DMDSceneQueue too big! Resetting"
                    DMDqHead = 0:DMDqTail = 0
                    Exit Sub
                End If
                If DMDqHead = DMDqTail Then ' queue is empty
                    DMDqHead = 0:DMDqTail = 0
                    Exit Sub
                End If

                ' Find the next scene with the highest priority
                j = DMDqHead
                For i = DMDqHead to DMDqTail-1
                    If DMDSceneQueue(i,1) < DMDSceneQueue(j,1) Then j=i
                Next

                ' Play the scene, and a sound if there's one to accompany it
                bDefaultScene = False
                debug.print "Displaying scene at " &j
                DMDDisplayScene DMDSceneQueue(j,0)
                DMDSceneQueue(j,6) = DMDtimestamp
                If DMDSceneQueue(j,5) <> ""  Then PlaySoundVol DMDSceneQueue(j,5),VolDef
            End If
        End If
    End If
End Sub
    
Dim DisplayingScene     ' Currently displaying scene
Sub DMDDisplayScene(scene)
    If TypeName(scene) <> "Object" then
		debug.print "DMDDisplayScene: scene is not an object! Type=" & TypeName(scene)
		exit sub
	ElseIf scene Is Nothing or IsEmpty(scene) Then
		debug.print "DMDDisplayScene: scene is empty!"
		exit Sub
	End If
    If Not IsEmpty(DisplayingScene) Then If DisplayingScene Is scene Then Exit Sub
    FlexDMD.LockRenderThread
    FlexDMD.RenderMode = FlexDMD_RenderMode_DMD_GRAY_4
    FlexDMD.Stage.RemoveAll
    FlexDMD.Stage.AddActor scene
    FlexDMD.Show = True
    FlexDMD.UnlockRenderThread
    Set DisplayingScene = scene
End Sub

' Create a new scene with a video file. If the video file
' is not found, look for an image file. If that's not found, 
' create a new blank scene
Function NewSceneWithVideo(name,videofile)
    Dim actor
    Set NewSceneWithVideo = FlexDMD.NewGroup(name)
    Set actor = FlexDMD.NewVideo(name&"vid",FlexPath & videofile & ".gif")
    If actor is Nothing Then
        debug.print "Warning: "&videofile&".gif not found in "&FlexPath
        Set actor = FlexDMD.NewImage(name&"img","VPX."&videofile)
        if actor is Nothing Then Exit Function
    End If
    NewSceneWithVideo.AddActor actor
End Function

' Create a new scene with an image file. If that's not found, 
' create a new blank scene
Function NewSceneWithImage(name,imagefile)
    Dim actor
    Set NewSceneWithImage = FlexDMD.NewGroup(name)
    Set actor = FlexDMD.NewImage(name&"img","VPX."&imagefile)
    if actor is Nothing Then Exit Function
    NewSceneWithImage.AddActor actor
End Function

' Add a blink action to an Actor in a FlexDMD scene. 
' Usage: BlinkActor scene.GetActor("name"),blink-interval-in-seconds,repetitions 
' Blink action is only natively supported in FlexDMD 1.9+
' poplabel.AddAction af.Blink(0.1, 0.1, 5)
Sub BlinkActor(actor,interval,times)
    Dim af,blink
    Set af = actor.ActionFactory
    Set blink = af.Sequence()
    blink.Add af.Show(True)
    blink.Add af.Wait(interval)
    blink.Add af.Show(False)
    blink.Add af.Wait(interval)
    actor.AddAction af.Repeat(blink,times)
End Sub


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
Const ice = 11
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
        Case ice
            n.color = RGB(0, 18, 18)
            n.colorfull = RGB(192, 255, 255)
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
            bBallSaved = True
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
        vpmtimer.addtimer 1000, "PlungerIM.AutoFire:DOF 120, DOFPulse:PlaySoundAt ""fx_kicker"", swPlungerRest:bAutoPlunger = False:bAutoPlunged = True '"
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

    GameDoBallLaunched
    bAutoPlunged = False
    bBallSaved = False
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


' Constants we might need to tweak later
Const SpinnerAddValue = 500      ' Base amount that Spinner's value increases by for each target hit. TODO: Figure out right value

' Global table-specific variables
Dim HouseColor
Dim HouseSigil
Dim HouseShield
Dim HouseAbility
Dim LoLLights
Dim ComboLaneMap
Dim GoldTargetLights
Dim BattleObjectives

' Global variables with player data - saved across balls and between players
Dim PlayerMode          ' Current player's mode. 0=normal, -1 = select house, -2 = select battle, -3 = select mystery, 1 = in battle
Dim SelectedHouse       ' Current Player's selected house
Dim bTopLanes(2)        ' State of top lanes
Dim LoLTargetsCompleted ' Number of times the target bank has been completed
Dim WildfireTargetsCompleted ' Number of times wildfire target bank has been completed
Dim BWMultiballsCompleted
Dim bBWMultiballActive
Dim bLockIsLit
Dim bEBisLit            ' TODO: Find out whether this carries over
Dim bWildfireTargets(2) ' State of Wildfire targets
Dim bLoLLit             ' Whether Lord of Light Outlanes are lit
Dim bLoLUsed            ' Whether Lord of Light has been used this game
Dim CompletedHouses     ' Number of completed houses - determines max spinner level and triggers HOTK and Iron Throne modes
Dim TotalGold           ' Total gold collected in the game
Dim CurrentGold         ' Current gold balance
Dim TotalWildfire
Dim bGoldTargets(5)

' Support for game timers
Dim GameTimeStamp       ' Game time in 1/10's of a second, since game start
Dim bGameTimersEnabled  ' Flag for whether any timers are enabled
Dim TimerFlags(30)      ' Flags for each timer's state
Dim TimerTimestamp(30)  ' Each timer's end timestamp
Dim TimerSubroutine     ' Names of subroutines to call when each timer's time expires
Dim TimerReference(30)  ' Object references to above subroutines (built at table start)
Const MaxTimers = 6     ' Total number of defined timers. There MUST be a corresponding subroutine for each
TimerSubroutine = Array("","UpdateChooseBattle","LaunchBattleMode","BattleModeTimer1","BattleModeTimer1","MartellBattleTimer","HurryUpTimer")
Const tmrUpdateChooseBattle = 1
Const tmrChooseBattle = 2
Const tmrBattleMode1 = 3
Const tmrBattleMode2 = 4
Const tmrMartellBattle = 5
Const tmrHurryUp = 6

'HurryUp Support
Dim HurryUpValue
Dim bHurryUpActive
Dim HurryUpCounter
Dim HurryUpGrace
Dim HurryUpScene
Dim HurryUpChange

' Player state data
Dim House(4)  ' Current state of each house - some house modes aren't saved, while others are. May need a Class to save detailed state
Dim PlayerState(4) ' Structure to save global player-specific variables across balls

' Ball-specific variables (not saved across balls)
Dim PlayfieldMultiplierVal
Dim SpinnerValue
Dim SpinnerLevel
Dim DroppedTargets      ' Number of targets dropped
Dim ComboMultiplier(5)
Dim bWildfireLit
Dim bMysteryLit
Dim bSwordLit           ' TODO: Saved across balls?
Dim HouseBattle1        ' When in battle, the primary (top) House
Dim HouseBattle2        ' When in two-way battle, the second House

HouseColor = Array(white,white,yellow,red,purple,green,amber,blue)
' Assignment of centre playfield shields
HouseSigil = Array(li38,li38,li41,li44,li47,li50,li53,li32)
' Assignment of "shot" shields
HouseShield = Array(li141,li141,li26,li114,li86,li77,li156,li98)
' House Ability strings, used during House Selection
HouseAbility = Array("","increase winter is coming","advance wall multiball","collect more gold","plunder rival abilities","increase hand of the king","action button = add a ball","")

BattleObjectives = Array("", _ 
            "ARYA BECOMES AN ASSASSIN"&vbLf&"RAMPS BUILD VALUE"&vbLf&"ORBITS COLLECT VALUE", _
            "STANNIS VS THE WILDLINGS"&vbLf&"SPINNER BUILDS VALUE"&vbLf&"COLLECT AT THE 3 TARGETS", _
            "BRING BACK MYRCELLA"&vbLf&"GOLD TARGETS LIGHT RED SHOTS"&vbLf&"5 RED SHOTS TO FINISH", _
            "GREYJOY TAKES WINTERFELL"&vbLf&"5 SHOTS TO FINISH"&vbLf&"TIMER RESETS AFTER EACH", _
            "LORD LORAS JOUSTING THE MOUNTAIN"&vbLf&"TWO BANK WILL SCORE HITS"&vbLf&"SCORE 3 HITS TO WIN", _
            "VIPER VERSUS THE MOUNTAIN"&vbLf&"SHOOT 3 ORBITS IN A ROW"&vbLf&"LEFT RAMP COLLECTS",_
            "DEFEAT VISERION"&vbLf&"SHOOT 3 HURRY UPS"&vbLf&"TO DEFEAT VISERION", _
            "DEFEAT DROGON"&vbLf&"SHOOT 5 HURRY UPS"&vbLf&"TO DEFEAT DROGON", _
            "DEFEAT RHAEGAL"&vbLf&"SHOOT 3 HURRY UPS"&vbLf&"TO DEFEAT RHAEGAL")


' Assignment of Lol Target lights
LoLLights = Array(li17,li20,li23)
'Assignment of Gold target lights
GoldTargetLights = Array(li92,li105,li120,li135,li147)
' Map of house name to combo lane (Greyjoy is combo lane1, Targaryen is Combo lane2, etc)
ComboLaneMap = Array(0,4,0,3,1,0,5,2)




' This class holds player state that is carried over across balls
Class cPState
    Dim bWFTargets(2)
    Dim WFTargetsCompleted
    Dim LTargetsCompleted
    Dim myLoLLit
    Dim myLoLUsed
    Dim myLockIsLit
    Dim myBWMultiballsCompleted
    Dim myBallsInLock
    Dim myGoldTargets(5)
    Dim myTotalGold
    Dim myCurrentGold
    Dim myTotalWildfire

    Public Sub Save
        Dim i
        bWFTargets(0) = bWildfireTargets(0):bWFTargets(1) = bWildfireTargets(1)
        WFTargetsCompleted = WildfireTargetsCompleted
        LTargetsCompleted = LoLTargetsCompleted
        myLoLLit = bLoLLit
        myLoLUsed = bLoLUsed
        myLockIsLit = bLockIsLit
        myBWMultiballsCompleted = BWMultiballsCompleted
        myBallsInLock = BallsInLock
        myTotalGold = TotalGold
        myCurrentGold = CurrentGold
        myTotalWildfire = TotalWildfire
        For i = 0 to 5:myGoldTargets(i) = bGoldTargets(i):Next
    End Sub

    Public Sub Restore
        bWildfireTargets(0) = bWFTargets(0):bWildfireTargets(1) = bWFTargets(1)
        WildfireTargetsCompleted = WFTargetsCompleted
        LoLTargetsCompleted = LTargetsCompleted
        bLoLLit = myLoLLit
        bLoLUsed = myLoLUsed
        bLockIsLit = myLockIsLit
        BWMultiballsCompleted = myBWMultiballsCompleted
        BallsInLock = myBallsInLock
        For i = 0 to 5:bGoldTargets(i) = myGoldTargets(i):Next

    End Sub
End Class

' This class holds everything to do with House logic
Class cHouse
    Dim bSaid(7)             ' Whether the house's name has been said yet during ChooseHouse state
    Dim bQualified(7)        ' Whether the house has qualified for battle
    Dim bCompleted(7)        ' Whether battle has been completed
    Dim BattleState(7)      ' Placeholder for current battle state
    Dim QualifyCount(7)     ' Count of how many times the qualifying shot has been made for each house
    Dim HouseSelected
    Dim QualifyValue        ' Hold the current value for a qualifying target hit
    Dim bBattleReady 

    Private Sub Class_Initialize(  )
		dim i
		For i = 0 to 7
			bQualified(i) = False
            bCompleted(i) = False
            bSaid(i) = False
            QualifyCount(i) = 0
            Set BattleState(i) = New cBattleState
		Next
        HouseSelected = 0
        QualifyValue = 100000
        bBattleReady = True
        LockWall.collidable = True
	End Sub

    Public Property Let MyHouse(h) 
        HouseSelected = h
        bQualified(h) = True
        if (h = Greyjoy or h = Targaryen) Then bCompleted(h) = True 
        'TODO: Set all house-specific settings when House is Set. E.g. Persistent and Action functions
    End Property
	Public Property Get MyHouse : MyHouse = HouseSelected : End Property

    Public Property Let BattleReady(e) 
        bBattleReady = e
        if (e) Then LockWall.collidable = True
    End Property

    Public Property Get Qualified(h) : Qualified = bQualified(h) : End Property

    Public Property Get Completed(h) : Completed = bCompleted(h) : End Property

    ' Say the house name. Include "house " if not said before
    Public Sub Say(h)
        Dim tmp
        if (bSaid(h)) Then tmp="" Else tmp="house-"
        PlaySoundVol "say-" & tmp & HouseToString(h) & "1", VolDef
    End Sub

    Public Sub StopSay(h)
        Dim tmp
        if (bSaid(h)) Then tmp="" Else tmp="house-"
        StopSound "say-" & tmp & HouseToString(h) & "1"
        bSaid(h) = True
    End Sub

    ' Set the shield/sigil lights to the houses' current state
    Public Sub ResetLights
        If HouseSelected = 0 Then Exit Sub       ' Do nothing if we're still in Choose House mode
        If PlayerMode = 1 Then SetModeLights : Exit Sub
        Dim i
        Dim j
        j=0
        For i = Stark to Targaryen
            If bCompleted(i) Then 
                SetLightColor HouseSigil(i),HouseColor(HouseSelected),1
                HouseShield(i).State = 0        ' TODO: What color do shields turn for completed houses
                j = j + 1
            ElseIf bCompleted(i) = False and (bQualified(i)) Then 
                SetLightColor HouseSigil(i),HouseColor(i),2
                SetLightColor HouseShield(i), ice, 1
            Else
                HouseSigil(i).State = 0
                SetLightColor HouseShield(i),HouseColor(i),1       
            End If
        Next
        CompletedHouses = j
        if bBattleReady Then SetLightColor li108,white,2 Else SetLightColor li108,white,0
        'TODO: Set HOTK and IronThrone lights too
    End Sub


    ' Main function that handles processing the 7 main shots in the game.
    ' These shots have 3 major modes of operation
    '  - qualifying a house for battle
    '  - after qualifying, advancing Winter Is Coming
    '  - during House Battle mode, completing battles
    '
    ' In addition, functions are stacked on top of those modes at various times:
    '  - at any time, making a shot advances combo multiplier for all other shots
    '  - during multiball, shots award jackpots and lead to super jackpot
    Public Sub RegisterHit(h)
        Dim line0,line1,line2
        Dim i
        Dim combo:combo=1
        Dim combotext: combotext=""

        if PlayerMode = 0 Then
            Dim cbtimer: cbtimer=1000
            'TODO: Do Winter-Is-Coming check before ChooseBattle, so we can delay CB
            ' for WiC animation if needed
            if bBattleReady and h = Lannister Then    ' Kick off House Battle selection
                PlayerMode = -2
                If BallsInLock < 2 And bLockIsLit Then ' Multiball not about to start, lock the ball first
                    vpmtimer.addtimer 400, "LockBall '"     ' Slight delay to give ball time to settle
                    cbtimer = 1400
                End If
                vpmtimer.addtimer cbtimer, "StartChooseBattle '"
            End If
            if QualifyCount(h) < 3 Then
                QualifyCount(h) = QualifyCount(h) + 1

                If ComboLaneMap(h) Then combo = ComboMultiplier(ComboLaneMap(h))

                line0 = "house " & HouseToString(h)
                if QualifyCount(h) = 3 Then
                    bQualified(h) = True
                    bBattleReady = True
                    ResetLights
                    line2 = "house is lit"
                    'TODO: Play an animation on house lit, some with sound
                Else
                    line2 = (3 - QualifyCount(h)) & " more to light"
                    'TODO: sometimes play an animation and optional sound effect on house advance
                End If
                line1 = FormatScore(QualifyValue*combo*PlayfieldMultiplierVal)

                AddScore(QualifyValue*combo)
                If combo > 1 and PlayfieldMultiplierVal > 1 Then
                    combotext = "mixed"
                Elseif combo > 1 Then
                    combotext = "combo"
                Elseif PlayfieldMultiplierVal > 1 Then
                    combotext = "playfield"
                End If
                DMDComboScene line0,line1,line2,combo*PlayfieldMultiplierVal,combotext,3000,"gotfx-qualify-sword-hit1"

                 ' Increase Qualify value for next shot. Lots of randomness seems to factor in here
                if QualifyValue = 100000 Then
                    QualifyValue = 430000
                Else
                    i = RndNbr(5)
                    if i = 1 Then
                        ' Use a wide range for random increase
                        QualifyValue = QualifyValue + 100000 + (RndNbr(50)*10000)
                    Else
                        ' Use a narrower range for increase
                        QualifyValue = QualifyValue + 275000 + (RndNbr(30)*5000)
                    End If
                End If
            Else
                ' TODO: Not in a Mode and house already Qualified. Handle "Iced" targets for Winter-Is-Coming
            End If
        Else
            ' TODO: hits do completely different things during Modes
        End If
    End Sub

    Public Sub GoldHit(n)
        Dim i,j
        AddScore 30
        If PlayerMode > 0 Then
            If HouseBattle1 = Lannister Then
                BattleState(HouseBattle1).RegisterGoldHit n
            ElseIf HouseBattle2 = Lannister Then
                BattleState(HouseBattle2).RegisterGoldHit n
            End If
        Else
            ' Regular mode
            If HouseSelected = Lannister Then AddGold 22 Else AddGold 15
            If Not bGoldTargets(n) Then
                bGoldTargets(n) = True
                SetLightColor GoldTargetLights(n),yellow,1
                j = True
                For i = 0 to 4 
                    If bGoldTargets(i) = False Then j=False
                Next
                If j Then
                    ' Target bank completed. Light mystery, turn off target lights 
                    ' Probably need to play a sound here
                    For i = 0 to 4: bGoldTargets(n) = False: Next
                    bMysteryLit = True              ' Does this get saved across balls?
                    SetLightColor li153, white, 2  ' Turn on Mystery light
                    ' tell the gold target lights to turn off in 1 second. There's a timer on the first light
                    GoldTargetLights(0).TimerInterval = 1000: GoldTargetLights(0).TimerEnabled = True
                End If
            End If
        End If
    End Sub

    Sub HouseCompleted(h)
        bCompleted(h) = True
        bQualified(h) = False
        ' TODO Add support for Greyjoy gaining other houses' abilities
    End Sub

End Class

Dim ModeLightPattern
Dim AryaKills
'Each number is a bit mask of which shields light up for the given mode
'TODO Initial mode light pattern could be affected by saved state
'TODO Targaryen light pattern needs more investigation
ModeLightPattern = Array(0,10,16,0,218,138,80,10)

AryaKills = Array("","","joffrey","cercai","walder frey","tywin","the red woman","beric dondarrion","Thoros of Myr", _
                "meryn trant","the hound", "the mountain","rorge","ilyn payne","polliver")

Class cBattleState
    Dim CompletedShots          ' Total shots accumulated for this battle
    Dim ShotMask           ' bitmask of shots that have been lit up
    Dim LannisterGreyjoyMask    ' bitmask of shots completed
    Dim GreyjoyMask             ' Mask of shots completed
    Dim CompletedDragons
    Dim MyHouse                 ' The house associated with this BattleState instance
    Dim State                   ' Current state of this house's battle
    Dim bComplete               ' Battle is complete
    Dim TotalScore              ' Total score accumulated battling this house
    Dim HouseValue              ' Most houses build value as the battle progresses. Stored here
    Dim HouseValueIncrement     ' Amount house value builds by, per shot, if machine-generated
    Dim MyHurryUps(3)           ' Holds the index values of any running HurryUps. Only Targaryen has more than one concurrently 

    
    Private Sub Class_Initialize(  )
        CompletedShots = 0
        LannisterGreyjoyMask = 0
        GreyjoyMask = 0
        CompletedDragons = 0
        ShotMask = 0
        State = 0
        bComplete = False
        TotalScore = 0
        HouseValueIncrement = 0
    End Sub

    Public Property Let House(h) 
        MyHouse = h
    End Property
	Public Property Get House : House = MyHouse : End Property

    Public Sub SetBattleLights
        Dim mask
        ' Load the starting state mask
        mask = ModeLightPattern(MyHouse)
        ' Adjust based on house and state
        Select Case MyHouse
            Case Stark
                If State = 2 Then mask = mask or 80     ' Light the orbits for State 2
            Case Baratheon
                If SelectedHouse=GreyJoy And State = 2 Then mask = mask or 16
                If State = 2 Then mask = mask or 128    ' Light dragon shot
                If State = 3 Then mask = mask or 4      ' Light LoL target bank
            Case Lannister
                mask = ShotMask
            Case Greyjoy
                mask = mask xor GreyjoyMask             ' Turn off lights that have been completed
            Case Tyrell
                Select Case State
                    Case 2,4,6: mask = 32
                    Case 3: mask = 10
                    Case 5: mask = 2
                End Select
            Case Martell
                If State = 2 Then mask = 10
            Case Targaryen
                Select Case State
                    Case 2,5: mask = 80
                    Case 3,6,8: mask = 128
                    Case 4: mask = 10
                    Case 7
                        ' TODO: How are Drogon's shots chosen
                End Select
        End Select

        For i = 1 to 7
            If mask & (2^i) > 0 Then 
                ModeLightState(i,(ModeLightState(i,0))) = HouseColor(HouseBattle1) 
                ModeLightState(i,0) = ModeLightState(i,0) + 1
            End If
        Next
    End Sub

    ' Called to initialize battle mode for this house. Only certain houses need setup done
    Public Sub StartBattleMode
        Dim tmr: tmr=400    ' 10ths of a second
        Select Case MyHouse
            Case Stark
                State = 1
                HouseValue = 500000
                If HouseValueIncrement = 0 Then HouseValueIncrement = 3000000 + RndNbr(15) * 125000 
                If CompletedShots > 0 Then CompletedShots = 2
            Case Baratheon: State = 1 : OpenTopGates : HouseValue = 500000 : SpinnerValue = 25000 ' TODO Figure out right value
            Case Lannister: State=1:ShotMask = 0
            Case Greyjoy: OpenTopGates : tmr = 150
            Case Martell: tmr = 300 : State = 1 : CompletedShots = 0 : OpenTopGates
            Case Targaryen
                tmr = 0
                ' TODO in States 3,6,8 start a Hurry-Up
        End Select
        If tmr > 0 Then 
            If MyHouse = HouseBattle2 Then SetGameTimer tmrBattleMode2,tmr Else SetGameTimer tmrBattleMode1,tmr
        End If

    ' TODO: Are there any other lights/sounds assocaited with starting battle for a specific house?
    ' TODO: If not in multiball, create a scene for tracking progress. Scene is split with other battle if two battles
    End Sub

    ' Update the state machine based on the ball hitting a target
    Public Sub RegisterHit(h)
        Dim hit,done
        if bComplete Then Exit Sub
        Select Case MyHouse
            Case Stark
                If h = Lannister or h = Stark Then
                    ' Process ramp shot
                    HouseValue = HouseValue + HouseValueIncrement
                    HouseValueIncrement = HouseValueIncrement + 750000
                    CompletedShots = CompletedShots + 1
                    If CompletedShots = 3 Then
                        State = 2
                        SetModeLights
                    End If
                    If CompletedShots >= 3 Then
                        ' Show Arya's kill list scene. 
                        ' Photos alternate between right and left side of scene so adjust text alignment
                        Dim just1, just2
                        just1 = FlexDMD_Align_TopRight:just2 = FlexDMD_Align_BottomLeft
                        Select Case CompletedShots
                            Case 5,6,8,10,12,13,14: just1=FlexDMD_Align_TopLeft:just2 = FlexDMD_Align_BottomRight
                        End Select
                        ' Render battle hit scene. 'House,Scene #, Score, Text1, Text2, Score+Text1 text justification, text2 justification,sound
                        DMDBattleHitScene Stark,CompletedShots-2,HouseValue,"Stark Value Grows",AryaKills(CompletedShots),just1,just2,"say-aryakill"&CompletedShots-2
                    End If
                ElseIf State = 2 And (h = Greyjoy or h = Martell) Then
                    DoCompleteMode h
                End if

            Case Baratheon
                If State = 2 Then
                    If ShotMask And 2^h > 0 Then
                        ShotMask = ShotMask And (2^h Xor 255)
                        ' TODO: Play a scene when Shot needed for State 3 is made?
                        ' TODO: how much does a lit shot score in Baratheon battle mode?
                        If ShotMask = 0 Then
                            State = 3
                            ResetDropTargets
                            SetModeLights
                        End If
                    End If
                End If

            Case Lannister
                If ShotMask And 2^h > 0 Then
                    ShotMask = ShotMask And (2^h Xor 255)
                    LannisterGreyjoyMask = LannisterGreyjoyMask Or 2^h
                    ' TODO: Does making a lit shot score value during Lannister, or just increase HouseValue? 
                    ' TODO: Increase HouseValue by how much?
                    CompletedShots = CompletedShots + 1
                    If (SelectedHouse = GreyJoy And LannisterGreyjoyMask = 218) or (SelectedHouse <> Greyjoy And CompletedShots >= 5) Then
                        DoCompleteMode 0
                    End If
                End If
            
            Case Greyjoy
                If GreyjoyMask And 2^h = 0 Then
                    ' Completed shot
                    GreyjoyMask = GreyjoyMask Or 2^h
                    If GreyjoyMask = 218 Then 'Completed req'd shots!
                        DoCompleteMode h
                    Else
                        ' TODO: Play scene for this Grejoy shot?
                        ' TODO: Add score - how much?
                        ' Reset mode timer
                        If MyHouse = HouseBattle2 Then SetGameTimer tmrBattleMode2,150 Else SetGameTimer tmrBattleMode1,150
                    End If
                End If

            Case Tyrell
                hit=False
                Select Case State
                    Case 1
                        If h = Targaryen or h = Stark or h = Lannister Then hit = true
                    Case 2,4,6
                        If h = Tyrell Then hit = true
                    Case 3
                        If h = Stark or h = Lannister Then hit = true
                    Case 5
                        If h = Stark then hit = true
                End Select
                If hit Then
                    State = State + 1
                    If State = 7 Then
                        DoCompleteMode 0
                    Else
                        ' TODO: Play an animation, add score
                        SetModeLights
                    End If
                End If

            Case Martell
                Dim huvalue
                If State = 1 And (h = Greyjoy or h = Martell) Then
                    CompletedShots = CompletedShots + 1
                    If CompletedShots = 3 Then 'State 1 complete
                        TimerFlags(tmrMartellBattle) = 0
                        State = 2
                        'TODO: Start a Hurry-Up. Maybe stretch mode timeout timer
                        SetModeLights
                    Else
                        ' Start or reset a 10 second timer
                        SetGameTimer tmrMartellBattle,100
                        ' Reset mode timer if less than 10 seconds left
                        If (MyHouse = HouseBattle1 And TimerTimestamp(tmrBattleMode1)-GameTimeStamp < 100) Then 
                            SetGameTimer tmrBattleMode1,300
                        ElseIf (MyHouse = HouseBattle2 And TimerTimestamp(tmrBattleMode2)-GameTimeStamp < 100) Then
                            SetGameTimer tmrBattleMode2,300
                        End If
                    End If
                End if
                If State = 2 And (h = Stark or h = Lannister) Then
                    huvalue = HurryUpValue(MyHurryUps(0))
                    If huvalue > 0 Then
                        'Hurry-up hit in time
                        huvalue = huvalue * ComboMultiplier(ComboLaneMap(h)) * PlayfieldMultiplierVal
                        HouseValue = HouseValue + huvalue
                        DoCompleteMode 0
                    End If
                End If

            Case Targaryen 'TODO
                hit = False:done=False
                Select Case State
                    Case 1
                        If h = Stark or h = Lannister Then hit=true:done=True
                    Case 2
                        If h = Greyjoy or h = Martell Then hit=true:done=True
                    Case 3,6
                        If h = Targaryen Then
                            hit=true:done=true
                            huvalue = HurryUpValue(MyHurryUps(0))
                            ShotMask = 10
                        End If
                    Case 4
                        If h = Stark or h = Lannister Then
                            hit=true
                            ShotMask = ShotMask And (2^h Xor 255)
                            If ShotMask = 0 Then done=true:ShotMask=80
                        End If
                    Case 5
                        If h = Greyjoy or h = Martell Then
                            hit=true
                            ShotMask = ShotMask And (2^h Xor 255)
                            If ShotMask = 0 Then done=true:ShotMask=80
                        End If
                    Case 7  'TODO: Shoot all 3 hurry-ups. Shooting Dragon spots a hurry-up
                    Case 8
                        If h = Targaryen Then
                            hit=true:done=true
                            huvalue = HurryUpValue(MyHurryUps(0))
                        End If
                End Select
                If hit Then
                    ' Do some scoring, animation
                End If
                If done Then
                    State = State + 1
                    Select Case State
                        Case 3,6
                            ' Start Dragon HurryUp
                        Case 7
                            ' Start 3 random Hurry Ups from a choice of 6 shots (Dragon can't be one of them)
                        Case 8
                            ' Start Drogon HurryUp
                        Case 9: DoCompleteMode 0
                    End Select
                    SetModeLights
                End If  

            ' Targaryen: 3 LEVELS, each with 3 states except last which has 2? - 8 states total
                ' Level 1 Start: light 2 ramps
                ' State 1: Shoot lit 1 lit ramp to advance to State 2
                ' State 2: Light 2 loops. Shoot one to advance to dragon
                ' State 3: Start hurry-up on Dragon. 
                ' Level 2: Repeat Level 1, but require all 4 shots in State 1 & 2
                ' Level 3: Light 3 random shots as hurry-ups (mode ends if hurry-ups timeout?)
                ' State 1: Shoot all 3 hurry-ups. Shooting Dragon spots a hurry-up
                ' State 2: Shoot Dragon hurry-up
                ' Repeat States 1 & 2 for 4 waves. After 4th wave, mode is complete!
                ' Timer on Level 3: If you take too long, you are attacked with “DRAGON FIRE”, and wave restarts with new randomly chosen shots (State 1, but same Wave)
                ' Greyjoy players have a Hurry-Up to hit any target to start State 1 on each Level
        End Select

    End Sub

    ' Finish the mode. 'Shot' is the shot # that completed the mode, in case a combo multiplier is involved
    Public Sub DoCompleteMode(shot)
        Dim comboval

        bComplete = True
        House(CurrentPlayer).HouseCompleted MyHouse

        EndBattleMode

        SetLightColor HouseSigil(MyHouse),HouseColor(SelectedHouse),1

        If shot > 0 And MyHouse <> Baratheon Then
            comboval = ComboMultiplier(ComboLaneMap(shot)) * PlayfieldMultiplierVal
        Else
            comboval = PlayfieldMultiplierVal
        End If
        TotalScore = TotalScore + HouseValue * comboval
        
        ' Award score
        If shot > 0 Then
            AddScore TotalScore
        Else
            AddScore HouseValue * comboval
        End If
        'TODO Add a sound here. Sound is same as qualifying hit
        'TODO: Do any other battles only award points upon completion? Use comboval as indicator of whether all points were awarded at once or spread out
        If MyHouse <> Stark And MyHouse <> Baratheon Then comboval = 0
        DMDBattleEndScene MyHouse,TotalScore,comboval
    End Sub

    ' Return to normal play. TODO: Anything else to do?
    Public Sub EndBattleMode
        CloseTopGates
        ' Disable mode timer and HouseBattle
        If MyHouse = HouseBattle1 Then 
            TimerFlags(tmrBattleMode1) = 0
            HouseBattle1 = 0 
        Else 
            TimerFlags(tmrBattleMode2) = 0
            HouseBattle2 = 0
        End If

        If HouseBattle1 = 0 And HouseBattle2 = 0 Then PlayerMode = 0
        ' TODO: Maybe need to modify Scene to remove one or both battle scenes
    End Sub

    ' Called by the timer when the mode timer has expired
    Public Sub BattleTimerExpired
        If MyHouse = Martell And State = 2 Then 
            DoCompleteMode 
        Else 
            EndBattleMode
        End if
    End Sub

    ' Some battles involve the spinner
    Public Sub RegisterSpinnerHit
        If MyHouse <> Baratheon Then Exit Sub
        ShotMask = ShotMask And 239 ' turn off bit 4
        HouseValue = HouseValue + SpinnerValue
        If State = 1 And HouseValue > 1000000 Then   ' TODO Spinner value needs to build how high before advancing to State 2?
            State = 2
            If SelectedHouse = Greyjoy Then ShotMask = 144 Else ShotMask = 128
            SetModeLights
        End If
    End Sub

    ' Some battles need to know about individual target hits
    ' Right now we don't care about individual targets, just which bank. 0 = Left, 1 = Right
    Public Sub RegisterTargetHit(tgt)
        If MyHouse = Baratheon And State = 3 And tgt = 0 Then
            ' Mode completed!
            DoCompleteMode Baratheon
        End if
    End Sub

    ' Lannister battle mode needs to know about gold target hits
    Public Sub RegisterGoldHit(tgt)
        If MyHouse <> Lannister Then Exit Sub
        Select Case tgt
            Case 0: ShotMask = ShotMask Or 144
            Case 1: ShotMask = ShotMask Or 136
            Case 2,3: ShotMask = ShotMask Or 10
            Case 4: ShotMask = ShotMask Or 66
        End Select
        SetModeLights
    End Sub

    ' Called when the 10 second timer runs down
    Public Sub MartellTimer: CompletedShots = 0: End Sub

End Class

Function HouseToString(h)
    Select Case h
        Case 0
            HouseToString = ""
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
    End Select
End Function

'**************************************************
' Table, Game, and ball initialization code
'**************************************************

Sub VPObjects_Init
    Dim i
    BumperWeightTotal = 0
    For i = 1 To BumperAwards:BumperWeightTotal = BumperWeightTotal + PictoPops(i)(2): Next
    'For i = 0 to MaxTimers: Set TimerReference(i) = GetRef(TimerSubroutine(i)) : Next
End Sub

Sub Game_Init()     'called at the start of a new game
    TurnOffPlayfieldLights()
    ResetComboMultipliers
End Sub

' Initialise the Table for a new Game
'
Sub ResetForNewGame()
    Dim i

    bGameInPLay = True
    GameTimeStamp = 0
    'resets the score display, and turn off attract mode
    StopAttractMode
    GiOn

    TotalGamesPlayed = TotalGamesPlayed + 1
    CurrentPlayer = 1
    PlayersPlayingGame = 1
    bOnTheFirstBall = True
    WildfireTargetsCompleted = 0
    LoLTargetsCompleted = 0
    CompletedHouses = 0
    TotalGold = 0
    CurrentGold = 0
    TotalWildfire = 0
    bLockIsLit = False
    BWMultiballsCompleted = 0
    bWildfireTargets(0) = False:bWildfireTargets(1) = False
    For i = 1 To MaxPlayers
        Score(i) = 0
        BonusPoints(i) = 0
        BonusHeldPoints(i) = 0
        BonusMultiplier(i) = 1
        BallsRemaining(i) = BallsPerGame
        Set House(i) = New cHouse
        Set PlayerState(i) = New cPState
    Next

    ' initialise any other flags
    Tilt = 0

    ' initialise Game variables
    Game_Init()

    tmrGame.Interval = 100
    tmrGame.Enabled = 1

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

    'This table doesn't use a skill shot
    bSkillShotReady = False

    bHurryUpActive = False
    bBWMultiballActive = False

    bMysteryLit = False     ' TODO: Are these carried over across balls?
    bSwordLit = False

    HouseBattle1 = 0 : HouseBattle2 = 0

    ' Reset Combo multipliers
    ResetComboMultipliers

    if (House(CurrentPlayer).MyHouse = 0) Then
        PlayerMode = -1
        SelectedHouse = 1
        FlashShields SelectedHouse,1
        ChooseHouse 0
    Else 
        PlayerState(CurrentPlayer).Restore
        PlayerMode = 0
        SelectedHouse = House(CurrentPlayer).MyHouse
        House(CurrentPlayer).ResetLights
    End If
    PlaySong("got-track1")
End Sub

Sub ResetNewBallVariables() 'reset variables for a new ball or player
    dim i
    'turn on or off the needed lights before a new ball is released
    TurnOffPlayfieldLights
    ResetPictoPops
    ResetDropTargets
     ' Top lanes start out off on the Premium/LE
    For i = 0 to 1 : bTopLanes(i) = False : Next
    'playfield multipiplier
    pfxtimer.Enabled = 0
    PlayfieldMultiplierVal = 1
    SpinnerLevel = 1
    SpinnerValue = 500 + (BallsPerGame-BallsRemaining(CurrentPlayer))*2000 ' Appears to start at 2500 on ball 1 and 4500 on ball 2
    UpdatePFXLights(PlayfieldMultiplierVal)
    bWildfireLit = False
    ' TODO: Update playfield lights to their correct status based on current player and state
    SetLockLight
    SetOutlaneLights
    SetMysteryLight
    SetSwordLight
    SetGoldTargetLights
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

        ' update the score display
        DMDLocalScore

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

		'tmrEndOfBallBonus.Enabled = False and _
	if bGameInPlay and _ 
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


        'TODO: Figure out how to do bonuses. For now, skip
        ' Below is how GOTG does it
        ' add a bit of a delay to allow for the bonus points to be shown & added up
		'tmrEndOfBallBonus.Interval = 800
		'tmrEndOfBallBonus.UserValue = 0		' Timer will start EndOfBall2 when it is done
		'tmrEndOfBallBonus.Enabled = true
        vpmtimer.addtimer 100, "EndOfBall2 '"
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

    ' Save the current player's state
    PlayerState(CurrentPlayer).Save

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
' TODO: Need to do anything here? E.g. reset lighting, restore pre-mb state?
    bBWMultiballActive = False
    PlaySong "got-track1"
End Sub

Sub RotateLaneLights(dir)
    If bTopLanes(0) or bTopLanes(1) Then
        bTopLanes(0) = Not bTopLanes(0)
        bTopLanes(1) = Not bTopLanes(1)
        SetLightColor li162, white, bTopLanes(0)
        SetLightColor li165, white, bTopLanes(1)
    End If
End Sub

Sub SetLockLight
    If bLockIsLit Then
        ' Flash the lock light
        li111.BlinkInterval = 300
        SetLightColor li111,darkgreen,2
    Else
        SetLightColor li111,darkgreen,0
    End If
End Sub

Sub SetSwordLight
    If bSwordLit Then
        li138.BlinkPattern = 110
        li138.BlinkInterval = 150
        SetLightColor li138,yellow,2
    Else
        SetLightColor li138,yellow,0
    End If
End Sub

Sub SetMysteryLight
    ' TODO: Figure out mystery light's blink pattern
    if bMysteryLit Then
        li153.BlinkInterval = 250
        SetLightColor li153,white,2
    Else
        SetLightColor li153,white,0
    End If
End Sub

Sub SetGoldTargetLights
    Dim i
    For i=0 to 4
        SetLightColor GoldTargetLights(i),yellow,ABS(bGoldTargets(i))
    Next
End Sub

Sub setEBLight
    if bEBisLit Then
        SetLightColor li150,amber,1
    Else
        SetLightColor li150,white,0
    End If
End Sub

Sub OpenTopGates: topgatel.open = True: topgater.open = True: End Sub
Sub CloseTopGates
    topgater.open = False
    If bEBisLit or bMysteryLit Then Exit Sub
    topgatel.open = False
End Sub

Sub ResetDropTargets
    ' PlaySoundAt "fx_resetdrop", Target010
    If Target7.IsDropped OR Target8.IsDropped OR Target9.IsDropped Then
        PlaySoundAt SoundFXDOF("fx_resetdrop", 119, DOFPulse, DOFcontactors), Target8
        Target7.IsDropped = 0
        Target8.IsDropped = 0
        Target9.IsDropped = 0
    End If
    DroppedTargets = 0
    SetTargetLights
End Sub

Sub ResetComboMultipliers
    Dim i
    For i = 0 to 5: ComboMultiplier(i) = 1: Next
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

' During Battle mode, Shield lights may be in one of several states
' They may also alternate colour. To deal with this, create an array of
' light states and set a timer on each light to cycle through its states
' 1st element of array is number of states for this light
' This Sub sets the jackpot light. The SetModeLights in the BattleState class
' handles all of the battle-related colours
Dim ModeLightState(7,10)
Sub SetModeLights
    Dim i,j
    For i = 1 to 7
        if bBWMultiballActive = False or i = Baratheon or i = Tyrell Then     ' Drop targets don't get jackpots
            ModeLightState(i,0) = 1
            ModeLightState(i,1) = 0
        Elseif bBWMultiballActive Then
            ModeLightState(i,1) = green
            ModeLightState(i,2) = 0
            ModeLightState(i,0) = 2
        
        'TODO Jackpot light states for other multiball modes
        End If
    Next

    If HouseBattle1 > 0 Then House(CurrentPlayer).BattleState(HouseBattle1).SetBattleLights
    If HouseBattle2 > 0 Then House(CurrentPlayer).BattleState(HouseBattle2).SetBattleLights

    For i = 1 to 7
        If ModeLightState(i,0) < 2 Then HouseShield(i).TimerEnabled = False Else HouseShield(i).TimerEnabled = True
        HouseShield(i).TimerInterval = 100
        HouseShield(i).UserValue = 1
    Next
End Sub

' House Shield light timers. Used to cycle through color states during battle mode
'HouseShield = Array(li141,li141,li26,li114,li86,li77,li156,li98)
Sub li141_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(1,uv) > 0 Then SetLightColor Me,ModeLightState(1,uv),1 Else Me.state=0
    uv = uv + 1
    If uv >= ModeLightState(1,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li26_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(2,uv) > 0 Then SetLightColor Me,ModeLightState(2,uv),1 Else Me.state=0
    uv = uv + 1
    If uv >= ModeTotalLightStates Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li114_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(3,uv) > 0 Then SetLightColor Me,ModeLightState(3,uv),1 Else Me.state=0
    uv = uv + 1
    If uv >= ModeTotalLightStates Then uv = 0
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li86_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(4,uv) > 0 Then SetLightColor Me,ModeLightState(4,uv),1 Else Me.state=0
    uv = uv + 1
    If uv >= ModeTotalLightStates Then uv = 0
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li77_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(5,uv) > 0 Then SetLightColor Me,ModeLightState(5,uv),1 Else Me.state=0
    uv = uv + 1
    If uv >= ModeTotalLightStates Then uv = 0
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li156_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(6,uv) > 0 Then SetLightColor Me,ModeLightState(6,uv),1 Else Me.state=0
    uv = uv + 1
    If uv >= ModeTotalLightStates Then uv = 0
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li98_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(7,uv) > 0 Then SetLightColor Me,ModeLightState(7,uv),1 Else Me.state=0
    uv = uv + 1
    If uv >= ModeTotalLightStates Then uv = 0
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub


Sub CheckActionButton
    If PlayerMode = -2 Then LaunchBattleMode
'TODO: Check Actions
End Sub

' Set the Bonus Multiplier to the specified level AND set any lights accordingly
' There is no bonus multiplier lights in this table

Sub SetBonusMultiplier(Level)
    ' Set the multiplier to the specified level
    BonusMultiplier(CurrentPlayer) = Level
End Sub

Sub IncreaseBonusMultiplier(bx)
    BonusMultiplier(CurrentPlayer) = BonusMultiplier(CurrentPlayer) + bx
    'TODO: Play increase bonus animation (and sound?)
End Sub

Sub AddGold(g)
    TotalGold = TotalGold + g
    CurrentGold = CurrentGold + g
    'TODO: Play IncreasedGold image w/ gold score
End Sub

' Check for key presses specific to this game.
' If PlayerMode is < 0, in a 'Select' state, so use flippers to toggle
Function CheckLocalKeydown(ByVal keycode)
    if PlayerMode < 0 and (keycode = LeftFlipperKey or keycode = RightFlipperKey) Then
        CheckLocalKeydown = True
        if PlayerMode = -1 Then 
            ChooseHouse(keycode)
        ElseIf PlayerMode = -2 Then 
            ChooseBattle(keycode)
        Else 
            ChooseMystery(keycode)
        End If    
    Else
        CheckLocalKeydown = False
    End If
End Function


Sub ChooseHouse(ByVal keycode)
    If keycode = LeftFlipperKey Then
        FlashShields SelectedHouse,False
        House(CurrentPlayer).StopSay(SelectedHouse)
        If SelectedHouse = Stark Then 
            SelectedHouse = Targaryen
        Else
            SelectedHouse = SelectedHouse - 1
        End If
        FlashShields SelectedHouse,True
        House(CurrentPlayer).Say(SelectedHouse)
    ElseIf keycode = RightFlipperKey Then
        FlashShields SelectedHouse,False
        House(CurrentPlayer).StopSay(SelectedHouse)
        If SelectedHouse = Targaryen Then 
            SelectedHouse = Stark
        Else
            SelectedHouse = SelectedHouse + 1
        End If
        FlashShields SelectedHouse,True
        House(CurrentPlayer).Say(SelectedHouse)
    End If
    DMDChooseScene1 "choose your house",HouseToString(SelectedHouse), HouseAbility(SelectedHouse),"got-sigil-" & HouseToString(SelectedHouse)
End Sub

' Turn on the flashing shield sigils when choosing a house
Sub FlashShields(h,State)
    if State Then
        SetLightColor HouseSigil(h),HouseColor(h),2
        SetLightColor HouseShield(h),HouseColor(h),2
    Else
        HouseSigil(h).State = 0
        HouseShield(h).State = 0
    End If     
End Sub

' Handle game-specific processing when ball is launched
Sub GameDoBallLaunched
    If PlayerMode = -1 Then
        House(CurrentPlayer).MyHouse = SelectedHouse
        House(CurrentPlayer).ResetLights
        PlayerMode = 0
        ' TODO: Display additional text about house chosen on ball launch
        DMDScoreNow
    End If
    If bBallSaved = False Then  PlaySoundVol "gotfx-balllaunch",VolDef
End Sub


Sub ChooseBattle(ByVal keycode)
    If keycode = LeftFlipperKey or keycode = RightFlipperKey Then
        If keycode = LeftFlipperKey Then
            PlaySoundVol "gotfx-choosebattle-left",VolDef
            CurrentBattleChoice = CurrentBattleChoice - 1
            if CurrentBattleChoice < 0 Then CurrentBattleChoice = TotalBattleChoices - 1
        Else
            PlaySoundVol "gotfx-choosebattle-right",VolDef
            CurrentBattleChoice = CurrentBattleChoice + 1
            if CurrentBattleChoice >= TotalBattleChoices Then CurrentBattleChoice = 0
        End If
        UpdateChooseBattle
    End If
End Sub

Sub ChooseMystery(ByVal keycode)
'TODO: implement mystery selection
End Sub

Sub InstantInfo
'TODO
End Sub

Sub SetTargetLights
    Dim i
    For i = 0 to 2
        if i >= LoLTargetsCompleted Then LoLLights(i).State = 0 Else SetLightColor LoLLights(i),yellow,1
    Next
End Sub

Sub SetOutlaneLights
    SetLightColor li11,white,bLoLLit
    SetLightColor li74,white,bLoLLit
End Sub

'*****************************
'  Handle target hits
'*****************************

' LoL Drop Targets
' Any target increases spinner value. 
Sub Target9_Dropped 'LoL target 1
    PlaySoundAt "fx_droptarget", Target9
    If Tilted Then Exit Sub
    DoTargetsDropped
End Sub

Sub Target8_Dropped 'LoL target 2
    PlaySoundAt "fx_droptarget", Target8
    If Tilted Then Exit Sub
    DoTargetsDropped
End Sub

Sub Target7_Dropped 'LoL target 3
    PlaySoundAt "fx_droptarget", Target7
    If Tilted Then Exit Sub
    DoTargetsDropped
End Sub

Sub DoTargetsDropped
    Dim i
    Addscore 330
    ' In case two targets were hit at once, stop the sound for the first target before playing the one for the second
    StopSound "gotfx-loltarget-hit" & DroppedTargets
    DroppedTargets = DroppedTargets + 1
    PlaySoundVol "gotfx-loltarget-hit" & DroppedTargets, VolDef
    SpinnerValue = SpinnerValue + (SpinnerAddValue * RndNbr(10) * SpinnerLevel)
    If PlayerMode > 0 Then
        'TODO: In a mode. See if it's House Baratheon, and if so, target may collect value
    End If
    If DroppedTargets = 3 Then
        ' Target bank completed
        LoLTargetsCompleted = LoLTargetsCompleted + 1
        ResetDropTargets
        If bLoLLit = False and bLoLUsed = False Then bLoLLit = True : SetOutlaneLights 'TODO: Is there a sound to play with LoL lights?
        For i = 0 to 2
            'TODO: Revisit this to see whether LoL lights that are on solid still flash when bank is completed
            FlashForMs LoLLights(i),500,100,2
        Next
        If SpinnerLevel <= CompletedHouses Then SpinnerLevel = SpinnerLevel + 1
        House(CurrentPlayer).RegisterHit(Baratheon)
    End If
End Sub

'*********************
' Wildfire target hits
'*********************
Sub Target43_Hit
    doWFTargetHit 0
End Sub

Sub Target44_Hit
    doWFTargetHit 1
End Sub

Sub doWFTargetHit(t)
    If Tilted then Exit Sub
    Dim t1:t1=1
    If t Then t1=0
    AddScore 230
    PlayExistingSoundVol "gotfx-wftarget-hit", VolDef, 0

    debug.print "wftarget " & t & " hit"
    debug.print "prev hitstate 0: " & bWildfireTargets(0) & " 1: " & bWildfireTargets(1)
    if bWildfireTargets(t) then Exit Sub
    bWildfireTargets(t) = True

    If BWMultiballsCompleted = 0 or bWildfireTargets(t1) Then LightLock
    if bWildfireTargets(t1) Then
        'Target bank completed
        'Light both lights for 1 second, then shut them off
        debug.print "wf targets completed"
        FlashForMs li80,1000,1000,0
        FlashForMs li83,1000,1000,0
        ' Lights don't always seem to restore their state properly after flashing, so stick a timer on it
        li80.TimerInterval = 1100
        li80.TimerEnabled = True
        bWildfireTargets(0)=False:bWildfireTargets(1)=False
        House(CurrentPlayer).RegisterHit(Tyrell)
        bWildfireLit = True: SetLightColor li126, darkgreen, 1
    Else
        Select Case t
            Case 0
                SetLightColor li80,green,1
                FlashForMs li80,1000,100,2
            Case 1
                SetLightColor li83,green,1
                FlashForMs li83,1000,100,2
        End Select
    End If
End Sub

'WF target light timer
Sub li80_Timer
    if li80.State <> ABS(bWildfireTargets(0)) or li83.State <> ABS(bWildfireTargets(1)) Then
        li80.State = ABS(bWildfireTargets(0))
        li83.State = ABS(bWildfireTargets(1))
        debug.print "WF target lights were out of sync"
    End If
    Me.TimerEnabled = False
End Sub

'Gold target light timer
Sub li92_Timer
    Me.TimerEnabled = False
    SetGoldTargetLights
End Sub

Sub LightLock
    Dim i

    if bLockIsLit or bMultiBallMode Then Exit Sub
    bLockIsLit = True
    ' Flash the lock light
    li111.BlinkInterval = 300
    SetLightColor li111,darkgreen,2

    ' Enable the lock wall
    LockWall.collidable = 1
    If RealBallsInLock > 0 Then SwordWall.collidable = 1

    i = RndNbr(3)
    if i > 1 Then i = ""
    PlaySoundVol "say-lock-is-lit"&i, VolDef

    ' Ensure Battle is enabled for the start of multiball, as long as at least one house is qualified
    If BallsInLock = 2 Then
        For i = Stark to Targaryen
            If House(CurrentPlayer).Qualified(i) and House(CurrentPlayer).Completed(i) = False Then
                House(CurrentPlayer).BattleReady = True
                SetLightColor li108,white,2
                Exit For
            End If
        Next
    End If 
End Sub


'******************
' 5 main shot hits
'******************
Sub LOrbitSW30_Hit
    If Tilted then Exit Sub
    AddScore 1000
    If LastSwitchHit <> "ROrbitsw31" Then House(CurrentPlayer).RegisterHit(Greyjoy)
    LastSwitchHit = "LOrbitSW30"
End Sub

' Left ramp switch
Sub sw39_Hit
    If Tilted then Exit Sub
    AddScore 1000
    House(CurrentPlayer).RegisterHit(Lannister)
    'TODO: This ramp shot kicks off lots of other actions too
    LastSwitchHit = "sw39"
    sw48.UserValue = "sw39"
End Sub

'Right ramp switch
Sub sw42_Hit
    If Tilted then Exit Sub
    AddScore 1000
    House(CurrentPlayer).RegisterHit(Stark)
    LastSwitchHit = "sw40"
End Sub

Sub ROrbitsw31_Hit
    If Tilted then Exit Sub
    If LastSwitchHit <> "swPlungerRest" Then 
        AddScore 1000
        If LastSwitchHit <> "LOrbitsw30" Then House(CurrentPlayer).RegisterHit(Martell)
    End If
    LastSwitchHit = "ROrbitsw31"
End Sub

'******************
' CastleWall Kicker
'******************

Sub Kicker37_Hit
    If Tilted then Exit Sub
    AddScore 1000
    House(CurrentPlayer).RegisterHit(Targaryen)
    PlaySoundAt "fx_kicker",kicker37
    Kicker37.Kick 190,30    'Angle,Power
End Sub

'******************
' lock switch
'******************
Sub sw48_Hit
    If Tilted then Exit Sub
    ' Debounce - ignore if the ramp switch wasn't just hit
    If sw48.UserValue <> "sw39" Then Exit Sub
    sw48.UserValue = ""

    if bMultiBallMode Then
        BallsInLock = BallsInLock + 1
        RealBallsInLock = RealBallsInLock + 1
        tmrBWmultiballRelease.Enabled = True
        Exit Sub
    End If

    If PlayerMode < 0 Then Exit Sub     ' ChooseBattle mode already started - let it take care of doing ball lock when done
    If bLockIsLit Then 
        vpmtimer.addtimer 400, "LockBall '"     ' Slight delay to give ball time to settle
    ElseIf RealBallsInLock > 0 Then     ' Lock isn't lit but we have a ball locked
        ReleaseLockedBall 0
    End If
        
End Sub

'*****************
' Gold targets hit
'*****************
Sub Target32_Hit
    GoldHit 0
End Sub
Sub Target33_Hit
    GoldHit 1
End Sub
Sub Target34_Hit
    GoldHit 2
End Sub
Sub Target35_Hit
    GoldHit 3
End Sub
Sub Target36_Hit
    GoldHit 4
End Sub

Sub GoldHit(n)
    If Tilted then Exit Sub
    PlaySoundVol "gotfx-coins" & n+1,VolDef
    House(CurrentPlayer).GoldHit(n)
End Sub


'**************
'Bumper Hits
'**************
Sub Bumper1_Hit
    If Tilted then Exit Sub
    PlaySoundAt "fx_bumper",Bumper1
    doPictoPops 0
End Sub

Sub Bumper2_Hit
    If Tilted then Exit Sub
    PlaySoundAt "fx_bumper",Bumper1
    doPictoPops 1
End Sub

Sub Bumper3_Hit
    If Tilted then Exit Sub
    PlaySoundAt "fx_bumper",Bumper1
    doPictoPops 2
End Sub

'********************************
' PictoPops support!
' (that's what Stern calls their 
'  rotating award pop bumpers)
'********************************
' From the GoT ROM code, here's the awards seen:
' Add_A_Ball
' Add_Mode_Time
' Advance_Toward_Wall_Multiball
' Award_3_Bonus_Multipliers
' Award_5_Wild_Fire
' Award_Big_Points
' Award_Bonus_Multiplier
' Award_Gold
' Award_Special
' Bump_Wall_Jackpot_Value
' Bump_Winter_Is_Coming_Value
' LIGHT_SWORDS
' Light_Extra_ball
' Light_Lock
' Light_Lord_Of_Light
' Light_Mystery
' Light_Wild_Fire
'
' Here's how the algorithm works:
' Each award carries a weight indicating how preferred it is as a random selection
' Whenever a pop bumper is hit, a random number is generated between 0 and the sum of all weights
' Each weight is subtracted from the random number until the number is less than the weight of the next item.
' That item is the selected choice.
' If a chosen item can't be awarded at this time (e.g. Add a Ball during regular play), repeat the process
'
' Once an award has been given, generate 3 new random awards for the bumpers. At least one should be different
'
' The weights are predefined in an array and the sum can be calculated at table_init

Const BumperAwards = 17
Dim BumperWeightTotal
Dim BumperVals(2)
Dim PictoPops(17) 'Each element represents one pop award which is an array of 'long name','short name','weight', and 'mode'
                  'Mode determines when the award can be won. 0=anytime, 1=during multiball, 2=not multiball and not LockIsLit, 
                  ' 3=during mode or hurry-up, 4=after LoLused, 5=mystery not lit, 6=swords not lit, 7=wild-fire not lit
PictoPops(1) = Array("+1 BONUS X","+1X",20,0)
PictoPops(2) = Array("+5 "&vbLf&"WILDFIRE","+WFIRE",20,0)
PictoPops(3) = Array("+150"&vbLf&"GOLD","+GOLD",20,0)
PictoPops(4) = Array("LIGHT "&vbLf&"SWORDS","L.SWORD",20,6)
PictoPops(5) = Array("INCREASE"&vbLf&"WINTER IS"&vbLf&"COMING","+WINTER",20,0) ' may need to change this if winter has come
PictoPops(6) = Array("INCREASE"&vbLf&"WALL"&vbLf&"JACKPOT","+POT",20,0) ''Battle for Wall Value Increases. Value=xxx'
PictoPops(7) = Array("LIGHT"&vbLf&"LOCK","L.LOCK",20,2)
PictoPops(8) = Array("BIG"&vbLf&"POINTS","+1M",20,0)
PictoPops(9) = Array("+3 BONUS X","+3X",12,0)
PictoPops(10) = Array("ADD TIME","+TIME",50,3) ' Higher weight, but only valid during Modes
PictoPops(11) = Array("ADD A BALL","+BALL",20,1)
PictoPops(12) = Array("ADVANCE"&vbLf&"WALL"&vbLf&"MULTIBALL","+WALL MB",20,0) '
PictoPops(13) = Array("LIGHT"&vbLf&"EXTRA"&vbLf&"BALL","EB LIT",12,0)
PictoPops(14) = Array("LORD"&vbLf&"OF"&vbLf&"LIGHT","LoL",10,4)
PictoPops(15) = Array("LIGHT"&vbLf&"MYSTERY","MYSTERY",20,5)
PictoPops(16) = Array("LIGHT"&vbLf&"WILDFIRE","WF LIT",20,7)
PictoPops(17) = Array("AWARD"&vbLf&"SPECIAL","SPECIAL",5,0)


Sub doPictoPops(b)
    Dim i,tmp
    ' Pick a random drum sound effect
    i = RndNbr(10)
    PlaySoundVol "gotfx-drum"&i,VolDef
    AddScore 1000

    Dim b1,b2:b1=1:b2=2
    Select Case b
        Case 1
            b1=0
        Case 2
            b2=0            
    End Select

    If (BumperVals(b) = BumperVals(b1) or BumperVals(b) = BumperVals(b2)) Then
        ' This bumper already matches one other. Check to make sure the value they're locked to is still valid
        If Not CheckPictoAward(BumperVals(b1)) Then GeneratePictoAward b1
        If Not CheckPictoAward(BumperVals(b2)) Then GeneratePictoAward b2
        DMDPictoScene
        Exit Sub
    End If
    GeneratePictoAward b
    DMDPictoScene

    ' Check to see whether all 3 match
    If (BumperVals(b) <> BumperVals(b1) or BumperVals(b) <> BumperVals(b2)) Then Exit Sub
    ' We have a winner!
    i = BumperVals(0)
    debug.print "PictoPops: Award " & PictoPops(i)(0)
    ResetPictoPops  ' Get em ready for the next round
    Select Case i    
        Case 1      ' Increase bonus multiplier
            IncreaseBonusMultiplier 1
        Case 2      ' Increase wildfire
            TotalWildfire = TotalWildfire + 5
        Case 3      ' Increase Gold
            If SelectedHouse = Lannister Then AddGold 250 Else AddGold 150
        Case 4      ' Light Swords
            bSwordLit = True: SetSwordLight
        Case 5      ' Increase Winter Is Coming value
            IncreaseWinterIsComing
        Case 6      ''Battle for Wall Value Increases. Value=xxx'
            IncreaseWallJackpot
        Case 7
            LightLock
        Case 8
            AddScore 1000000
            DMD "BIG POINTS",FormatScore(1000000*PlayfieldMultiplierVal),"",eNone,eNone,eNone,1000,True,""
        Case 9
            IncreaseBonusMultiplier 3
        Case 10     ' Add Time (to mode or Hurry Up)
            If PlayerMode = 1 Then
                If TimerFlags(tmrBattleMode1) And 1 = 1 Then TimerTimestamp(tmrBattleMode1) = TimerTimestamp(tmrBattleMode1) + 100
                If TimerFlags(tmrBattleMode2) And 1 = 1 Then TimerTimestamp(tmrBattleMode2) = TimerTimestamp(tmrBattleMode2) + 100
            End IF
            If bHurryUpActive Then
                'TODO: Add "Time" to HurryUp
            End if
            'TODO: pLay an "Add Time" scene with two hourglasses
        Case 11
            If bMultiBallMode Then
                AddMultiballFast 1
                DMD "","ADD A BALL","",eNone,eNone,eNone,1000,True,""
                'TODO Add-A-Ball: Set BallSaver timers
            End If
        Case 12
            DecreaseWallMultiball
        Case 13
            bEBisLit = True:SetEBLight
            'TODO: Play an animation?
        Case 14
            bLoLLit = True:SetOutlaneLights
            'TODO: Play sound or animation?
        Case 15
            bMysteryLit = True: SetMysteryLight
        Case 16
            bWildfireLit = True: SetLightColor li126, darkgreen, 1
        Case 17
            AwardSpecial
    End Select
End Sub

Sub GeneratePictoAward(b)
    Dim i,tmp,foundval: foundval = False
    Do While foundval = False
        tmp = RndNbr(BumperWeightTotal)-1
        For i = 1 to BumperAwards
            If tmp < PictoPops(i)(2) Then Exit For
            tmp = tmp - PictoPops(i)(2)
        Next
        ' Check to see if the new award is valid right now
debug.print "pictopops: b=" & b & "; i="&i
        foundval = CheckPictoAward(i)
    Loop 
    BumperVals(b) = i
End Sub

Function CheckPictoAward(val)
    CheckPictoAward = True
    Select Case PictoPops(val)(3)
        Case 1
            CheckPictoAward = bMultiBallMode
        Case 2
            CheckPictoAward = Not bMultiBallMode And Not bLockIsLit
        Case 3
            If PlayerMode <> 1 And bHurryUpActive = False Then CheckPictoAward = False
        Case 4
            CheckPictoAward = bLoLUsed
        Case 5
            CheckPictoAward = Not bMysteryLit
        Case 6
            CheckPictoAward = Not bSwordLit
        Case 7
            CheckPictoAward = Not bWildfireLit
    End Select
End Function

' Set new random values on the Pictopops. Ensure at least one is different
Sub ResetPictoPops
    Dim i
    Do
        For i = 0 to 2:GeneratePictoAward i: Next
    Loop While BumperVals(0) = BumperVals(1) And BumperVals(0) = BumperVals(2)
End Sub

Sub LockBall
    Dim i
    BallsInLock = BallsInLock + 1
    RealBallsInLock = RealBallsInLock + 1
    bLockIsLit = False
    SetLightColor li111,darkgreen,0     ' Turn off Lock light
    i = RndNbr(3)
    if i > 1 Then i = ""
    PlaySoundVol "say-ball-" & BallsInLock & "-locked" & i, VolDef
    If BallsInLock = 3 Then
        'Start BW multiball in 1 second - gives a chance to say 'ball locked'
        vpmtimer.addtimer 1000, "StartBWMultiball '"
    Else
        If RealBallsInLock > BallsInLock Then
            RealBallsInLock = RealBallsInLock - 1
            ReleaseLockedBall 0
        Else
            bAutoPlunger = True
            CreateNewBall
        End If
    End If

End Sub

Sub StartBWMultiball
    bMultiBallMode = True
    Dim scene
    Set scene = NewSceneWithVideo("bwmb","got-blackwatermb")
    scene.AddActor FlexDMD.NewLabel("balllock", FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0) ,"Ball 3"&vbLf&"Locked")
    scene.GetLabel("balllock").SetAlignedPosition 126,30,FlexDMD_Align_BottomRight
    BlinkActor scene.GetLabel("balllock"),0.1,12
    DMDEnqueueScene scene,0,2000,4000,500,"gotfx-blackwater-multiball-start"
    'PlaySoundVol "gotfx-blackwater-multiball-start",VolDef
    PlaySong "got-track4"
    'TODO Trigger a light sequence
  	tmrBWmultiballRelease.Interval = 5000	' Long initial delay to give sequence time to complete
    tmrBWmultiballRelease.Enabled = True
    bBWMultiballActive = True
End Sub

' Handle physically releasing a locked ball, as well as any sound effects needed
Sub ReleaseLockedBall(sword)
    SwordWall.TimerInterval = 330   ' how long the release solenoid stays down for
    SwordWall.TimerEnabled = True
    SwordWall.Collidable = True
    SwordWall.UserValue = sword
    LockWall.Collidable = False
    'TODO move the actuator primitive down
    'ActuatorPrimitive.TransZ = -50
    PlaySoundAt "fx_kicker",sw46
    If sword Then
        'TODO Rotate sword primitive to "chop off" the ball
        'SwordPrimitive.RotY = 30
        'TODO Play sword chopping sound
    End If
    'TODO: Any lighting effect to do when releasing individual balls?
End Sub

' Called after the release solenoid has been down for ~300ms. Re-opens the invisible sword wall to let the
' next ball through
Sub SwordWall_Timer
    Me.TimerEnabled = False
    If RealBallsInLock > 0 Then LockWall.Collidable = True
    SwordWall.Collidable = False
    'TODO move the actuator primitive back up
    'ActuatorPrimitive.TransZ = 0
    If SwordWall.UserValue = 1 Then
        'TODO Rotate sword primitive back to "open"
        'SwordPrimitive.RotY = 0
    End If
End Sub


Sub tmrBWmultiballRelease_Timer
    tmrBWmultiballRelease.Enabled = False
    tmrBWmultiballRelease.Interval = 1000
    ReleaseLockedBall 1
    BallsInLock = BallsInLock - 1
    RealBallsInLock = RealBallsInLock - 1
    If RealBallsInLock > 0 Then tmrBWmultiballRelease.Enabled = True: Exit Sub
    If BallsInLock > 0 Then AddMultiball BallsInLock
End Sub

Sub tmrGame_Timer
    Dim i
    GameTimeStamp = GameTimeStamp + 1
    if bGameTimersEnabled = False Then Exit Sub
    bGameTimersEnabled = False
    For i = 1 to MaxTimers
        If (TimerFlags(i) AND 1) = 1 Then 
            bGameTimersEnabled = True
            If TimerTimestamp(i) <= GameTimeStamp Then
                TimerFlags(i) = TimerFlags(i) AND 254   ' Set bit0 to 0: Disable timer
                'Call TimerReference(i)
                Execute(TimerSubroutine(i))
            End If
        End if
        If (TimerFlags(i) AND 2) = 2 Then TimerTimestamp(i) = TimerTimestamp(i) + 1 ' "Frozen" timer - increase its expiry by 1 step
    Next
End Sub

Sub SetGameTimer(tmr,val)
    TimerTimestamp(tmr) = GameTimeStamp + val
    TimerFlags(tmr) = TimerFlags(tmr) or 1
    bGameTimersEnabled = True
End Sub

Sub MartellBattleTimer
    Dim h
    If HouseBattle2 = Martell Then h = HouseBattle2 else h = HouseBattle1
    House(CurrentPlayer).BattleState(h).MartellTimer
End Sub

'*********************
' HurryUp Support
'*********************

' Called every 200ms by the GameTimer to update the HurryUp value
Sub HurryUpTimer
    Dim lbl
    HurryUpCounter = HurryUpCounter + 1
    If HurryUpCounter < HurryUpGrace Then Exit Sub
    If IsEmpty(HurryUpScene) Or HurryUpScene is Nothing Then
        'Update regular DMD somehow. Not yet supported
    Else
        lbl = HurryUpScene.GetLabel("HurryUp")
        If Not lbl is Nothing Then lbl.Text = FormatScore(HurryUpValue)
    End If
    HurryUpValue = HurryUpValue - HurryUpChange
    If HurryUpValue <= 0 Then
        HurryUpValue = 0
        EndHurryUp
    Else
        SetGameTimer tmrHurryUp,2
    End If
End Sub

' Start a HurryUp
'  value: Starting value of HurryUp
'  scene: A FlexDMD scene containing a Label named "HurryUp". The text of the label will be
'         updated every HurryUp period (200ms)
'  grace: Grace period in 200ms ticks. Value will start declining after this many ticks have elapsed
'
' HurryUpChange value calculated by watching change value of numerous Hurry Ups on real GoT tables. Ratio of change to original value was always the same
' The real GoT table sometimes introduces variability to the change value (e.g  alternating between +10K and -10K from base value) but we're not
' going to bother
Sub StartHurryUp(value,scene,grace)
    if bHurryUpActive Then
        debug.print "HurryUp already active! Can't have two!"
        Exit Sub
    End If
    Set HurryUpScene = scene
    HurryUpGrace = grace
    HurryUpValue = value
    HurryUpCounter = 0
    HurryUpChange = Int(HurryUpValue / 1033.32) * 10
    bHurryUpActive = True
    SetGameTimer tmrHurryUp,2
End Sub

' Called when the HurryUp runs down, or by another subroutine if the HurryUp has been scored
' HurryUps can be frozen, so preserve the "frozen" flags
Sub EndHurryUp
    bHurryUpActive = False
    TimerFlags(tmrHurryUp) = TimerFlags(tmrHurryUp) And 254
    If IsEmpty(HurryUpScene) Or HurryUpScene is Nothing Then
        'Update regular DMD somehow. Not yet supported
    Else
        lbl = HurryUpScene.GetLabel("HurryUp")
        If Not lbl is Nothing Then lbl.Visible = False
    End If
End Sub

Sub IncreaseWinterIsComing
    'TODO Handle Winter Is Coming increase (likely move inside House Class)
    ' Play sound & animation
End Sub

Sub IncreaseWallJackpot
    ' Increase the Battle Of the Wall Value (by how much?)
    ' Play animation (Jon Snow waving sword)
End Sub

Sub DecreaseWallMultiball
    'Countdown to Wall Multiball
    ' Play rotating clock animation based on where we're at
    ' If we're at Zero then
End Sub

Sub AwardSpecial
    'TODO Play Special animation and sound
    ' Knock Knocker
End Sub

'********************************
' Support for Battle (Mode) Start
'********************************

' StartChooseBattle: Called when BattleReady is lit and ball is shot up left ramp
'   - Create the array of battle choices
'   - Create the Instructions and Choose Battle scenes
'   - Play the Choose Battle song
'   - Set a timer to display the Choose Battle scene

Dim BattleChoices(49)   ' Max possible number of choices
Dim TotalBattleChoices,CurrentBattleChoice
Sub StartChooseBattle
    Dim i,j,tmrval
    HouseBattle1 = Empty
    HouseBattle2 = Empty

    PlayerMode = -2

    TurnOffPlayfieldLights
    
    DMDChooseBattleScene "","","",10

    ' Create the array of choices
    if CompletedHouses < 6 Then 
        BattleChoices(0) = 0:TotalBattleChoices = 1 ' Pass For Now is allowed
    Else
        TotalBattleChoices = 0
    End if
    For i = 0 to 7
        If (SelectedHouse <> Greyjoy And House(CurrentPlayer).Qualified(i)) or i = 0 then   ' Greyjoy can't stack house battles
            For j = 1 to 7
                If House(CurrentPlayer).Qualified(j) And House(CurrentPlayer).Completed(j) = False And j<>i Then 
                    BattleChoices(TotalBattleChoices) = i*7+j
                    TotalBattleChoices = TotalBattleChoices + 1
                End If
            Next
        End If
    Next
    CurrentBattleChoice = 1

    If TotalBattleChoices < 3 Then
        tmrval = 70
    ElseIf TotalBattleChoices < 5 Then
        tmrval = 120
    Else
        tmrval = 200
    End if

    ' Set up the launch timer
    SetGameTimer tmrChooseBattle,tmrval
        
    ' Set up the update timer to update after instructions have been displayed for 1.5 seconds
    vpmTimer.AddTimer 1500, "UpdateChooseBattle() '"
    PlaySong "got-track-choosebattle"
End Sub

' UpdateChooseBattle
' Set House string values based on the currently selected BattleChoice
' Update timers
' Update DMD

Sub UpdateChooseBattle
    Dim house1, house2, tmr, i

    ' Enable the game timer to call this sub again in 1 second
    SetGameTimer tmrUpdateChooseBattle,10

    If IsEmpty(CBScene) Then Exit Sub
    Set DefaultScene = CBScene

    HouseBattle1 = BattleChoices(CurrentBattleChoice) MOD 7
    HouseBattle2 = Int(BattleChoices(CurrentBattleChoice)/7)
    house2 = ""
    If HouseBattle1 = 0 Then
        house1 = "PASS FOR NOW"
    Else
        house1 = "HOUSE "&HouseToString(HouseBattle1)
        house2 = HouseToString(HouseBattle2)
        If house2 <> "" Then house2 = "HOUSE "&house2
    End If

    ' Flash the shield(s) of the currently selected house(s)
    For i = 1 to 7
        If i = HouseBattle1 or i = HouseBattle2 Then
            SetLightColor HouseSigil(i),HouseColor(i),2
        Else
            HouseSigil(i).State = 0
        End If
    Next
    tmr = Int( (TimerTimestamp(tmrChooseBattle)-GameTimeStamp) / 10) + 1
    DMDChooseBattleScene "CHOOSE YOUR BATTLE", house1, house2, tmr
End Sub

' LaunchBattleMode
' Shut off ChooseBattle timers
' Play animation with sound for housebattle1 & 2. Show objective for housebattle1 for length of sound 
' Start battle:
'   Set mode timer(s) 
' Check if we locked a ball and if so, do lock ball processing

Sub LaunchBattleMode
    Dim scene,tmr
    TimerFlags(tmrUpdateChooseBattle) = 0
    TimerFlags(tmrChooseBattle) = 0
    If BattleChoices(CurrentBattleChoice) = 0 Then ' Pass for now
        PlayerMode = 0 
        AddScore 0
        PlaySoundVol "gotfx-passfornow",VolDef
        PlaySong "got-track1"
        If bLockIsLit Then 
            LockBall
        Else                        ' Lock isn't lit but we have a ball locked
            vpmTimer.AddTimer 1500, "ReleaseLockedBall 0'"
        End If
        Exit Sub
    End If

    ' Start battle!
    DMDHouseBattleScene HouseBattle1
    DMDHouseBattleScene HouseBattle2

    tmr = 7000
    If HouseBattle2 > 0 Then tmr=12000
    
    PlayerMode = 1
    Set DefaultScene = ScoreScene
    ' TODO: Set up Mode timer(s)
    ' TODO: ScoreScene changes during a mode

    PlaySong "got-track5"   ' guessing at the right song here

    If bLockIsLit Then
        vpmTimer.AddTimer tmr, "LockBall '"
    Else                            ' Lock isn't lit but we have a ball locked
        vpmTimer.AddTimer 5000, "ReleaseLockedBall 0'"
    End If
End Sub

'**************************
' Game-specific DMD support
'**************************

' Combo Scene is used to display the results of combo shots. They are formatted as:
'
'     LINE 1 7x3 Charset
'      SCORE 12x7 digits     X multi (10x18 (or so) charset)
'     LINE 3 5x3 Charset
'

Sub DMDComboScene(line0,line1,line2,combox,combotext,duration,sound)
    Dim ComboScene,HouseFont,ScoreFont,ActionFont,ComboFont,CombotextFont
    if bUseFlexDMD Then
        Set ComboScene = FlexDMD.NewGroup("ComboScene")
        Set HouseFont  = FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0)
        Set ActionFont = FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0)
        Set ScoreFont  = FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbWhite, 0) 
        Set ComboFont  = FlexDMD.NewFont("FlexDMD.Resources.udmd-f12by24.fnt", vbWhite, vbWhite, 0) 
    
        ' Add Text labels
        ComboScene.AddActor FlexDMD.NewLabel("House", HouseFont, "0")
        ComboScene.AddActor FlexDMD.NewLabel("Score", ScoreFont, "0")
        ComboScene.AddActor FlexDMD.NewLabel("Action", ActionFont, "0")
        ComboScene.AddActor FlexDMD.NewLabel("ComboText", ActionFont, "0")
        ComboScene.AddActor FlexDMD.NewLabel("Combo", ComboFont, "0")
        ' Fill in text and align
        With ComboScene.GetLabel("House")
            .Text = line0
            .SetAlignedPosition 40,4,FlexDMD_Align_Center
        End With
        With ComboScene.GetLabel("Score")
            .Text = line1
            .SetAlignedPosition 40,16,FlexDMD_Align_Center
        End With
        With ComboScene.GetLabel("Action")
            .Text = line2
            .SetAlignedPosition 40,25,FlexDMD_Align_Center
        End With
        With ComboScene.GetLabel("ComboText")
            .Text = combotext
            .SetAlignedPosition 104,3,FlexDMD_Align_Center
        End With
        With ComboScene.GetLabel("Combo")
            .Text = combox & "X"
            .SetAlignedPosition 104,19,FlexDMD_Align_Center
        End With
        DMDEnqueueScene ComboScene,1,1000,2000,2500,sound
    Else
        DisplayDMDText line0 & "  " & combotext, line1 & "   " & combox & "X", duration
        PlaySoundVol sound,VolDef
    End If
End Sub

' Choose Scene is used for choosing your house at the beginning of game. Format is
'
'   house    CHOOSE YOUR HOUSE 8x5 charset
'   sigil    <|  House Name 9x5 charset  |>
'             house action button 5x3 charset
'
' Once house is selected, bottom row goes away and top two rows give more detail on house action
Dim ChooseHouseScene
Sub DMDChooseScene1(line0,line1,line2,sigil)    ' sigil is an image name
    Dim sigilimage
    If bUseFlexDMD Then
        If IsEmpty(ChooseHouseScene) Then
            Set ChooseHouseScene = FlexDMD.NewGroup("choosehouse")
            Set sigilimage = FlexDMD.NewImage("sigil",sigil)
            If Not (sigilimage Is Nothing) Then ChooseHouseScene.AddActor sigilimage
            ChooseHouseScene.AddActor FlexDMD.NewLabel("choosetxt", FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0) ,"CHOOSE YOUR HOUSE")
            ChooseHouseScene.AddActor FlexDMD.NewLabel("house", FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0) ,line1)
            ChooseHouseScene.AddActor FlexDMD.NewLabel("action", FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0) ,line2)
            ChooseHouseScene.GetLabel("choosetxt").SetAlignedPosition 78,5,FlexDMD_Align_Center
            ChooseHouseScene.GetLabel("house").SetAlignedPosition 78,16,FlexDMD_Align_Center
            ChooseHouseScene.GetLabel("action").SetAlignedPosition 78,27,FlexDMD_Align_Center
            Set DefaultScene = ChooseHouseScene
            DMDFlush
        Else
			Set sigilimage = ChooseHouseScene.GetImage("sigil")
            If Not sigilimage Is Nothing Then ChooseHouseScene.RemoveActor(sigilimage)
            Set sigilimage = FlexDMD.NewImage("sigil",sigil)
            If Not (sigilimage Is Nothing) Then ChooseHouseScene.AddActor sigilimage
            ChooseHouseScene.GetLabel("house").Text = line1
            ChooseHouseScene.GetLabel("action").Text = line2
            Set DefaultScene = ChooseHouseScene
        End If
    Else
        DisplayDMDText line0, line1, 0
    End if
End Sub

' DMDChooseBattleScene is used for choosing your House Battle(s). Format is
'
'    CHOOSE YOUR BATTLE (5x6 font)
'         HOUSE NAME (8x6 font)
'(optional)  and
' tmr     HOUSE NAME       tmr

Dim CBScene
Sub DMDChooseBattleScene(line0,line1,line2,tmr)
    Dim font,fatfont,smlfont,instscene
    If line0 = "" Then  ' Initial screen
        If bUseFlexDMD Then
            ' Create the instructions scene first
            Set instscene = FlexDMD.NewGroup("choosebattleinstr")
            instscene.AddActor FlexDMD.NewLabel("instructions",FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0), _ 
                    "CHOOSE YOUR BATTLE" & vbLf & "USE FLIPPERS TO" & vbLf & "CHANGE YOUR CHOICE" )
            instscene.GetLabel("instructions").SetAlignedPosition 64,16,FlexDMD_Align_Center
            DMDFlush
            DMDEnqueueScene instscene,0,1500,1500,100,""

            ' Create ChooseBattle scene
            If IsEmpty(CBScene) Then
                Set CBScene = FlexDMD.NewGroup("choosebattle")
                Set font = FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0)
                Set fatfont = FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by5.fnt", vbWhite, vbWhite, 0)
                Set smlfont = FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0)
                CBScene.AddActor FlexDMD.NewLabel("choose",font,"CHOOSE YOUR BATTLE") 
                CBScene.GetLabel("choose").SetAlignedPosition 64,4,FlexDMD_Align_Center
                CBScene.AddActor FlexDMD.NewLabel("house1",font,"")   ' TODO: needs fatter font
                CBScene.GetLabel("house1").SetAlignedPosition 64,20,FlexDMD_Align_Center
                CBScene.AddActor FlexDMD.NewLabel("and",fatfont,"AND")
                With CBScene.GetLabel("and")
                    .SetAlignedPosition 64,20,FlexDMD_Align_Center
                    .Visible = False
                End With
                CBScene.AddActor FlexDMD.NewLabel("house2",font,"")   ' TODO: needs fatter font
                With CBScene.GetLabel("house2")
                    .SetAlignedPosition 64,28,FlexDMD_Align_Center
                    .Visible = False
                End With
                CBScene.AddActor FlexDMD.NewLabel("tmrl",smlfont,"")
                CBScene.GetLabel("tmrl").SetAlignedPosition 3,28,FlexDMD_Align_BottomLeft
                CBScene.AddActor FlexDMD.NewLabel("tmrr",smlfont,"")
                CBScene.GetLabel("tmrr").SetAlignedPosition 123,28,FlexDMD_Align_BottomRight
            End If
            Set DefaultScene = CBScene
        Else ' No FlexDMD
            DisplayDMDText "USE FLIPPERS TO","CHOOSE YOUR BATTLE",1500
        End If
    Else ' Update existing screen
        If bUseFlexDMD Then
            CBScene.GetLabel("house1").Text = line1
            If line2 = "" Then
                CBScene.GetLabel("house1").SetAlignedPosition 64,20,FlexDMD_Align_Center
                CBScene.GetLabel("and").Visible = False
                CBScene.GetLabel("house2").Visible = False
            Else
                CBScene.GetLabel("house1").SetAlignedPosition 64,12,FlexDMD_Align_Center
                CBScene.GetLabel("and").Visible = True
                With CBScene.GetLabel("house2")
                    .Visible = True
                    .Text = line2
                    .SetAlignedPosition 64,28,FlexDMD_Align_Center
                End With
            End If
            CBScene.GetLabel("tmrl").Text = CStr(abs(tmr))
            CBScene.GetLabel("tmrl").SetAlignedPosition 3,28,FlexDMD_Align_BottomLeft
            CBScene.GetLabel("tmrr").Text = CStr(abs(tmr))
            CBScene.GetLabel("tmrr").SetAlignedPosition 123,28,FlexDMD_Align_BottomRight
        Else
            If line2="" Then
                DisplayDMDText line0, line1, 0
            Else
                DisplayDMDText line1, line2, 0
            End if
        End If
    End If
End Sub

' Play the intro video, music, and goals for a House Battle Mode
' We create a single scene consisting of the animation followed by the objective.
' The total scene play length is the same as the music
Dim SceneSoundLengths: SceneSoundLengths = Array(0,5654,5355,7805,4868,5165,5202,6000)  ' Battle sound lengths in 1/1000th's of a second
Sub DMDHouseBattleScene(h)
    Dim scene,vid,af,blink,hname

    If h = 0 Then Exit Sub    
    If bUseFlexDMD Then
        hname = HouseToString(h)
        Set scene = NewSceneWithVideo(hname&"battleintro","got-"&hname&"battleintro")
        Set vid = scene.GetVideo(hname&"battleintrovid")
        If vid is Nothing Then Set vid = scene.getImage(hname&"battleintroimg")
        scene.AddActor FlexDMD.NewLabel("objective",FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0),BattleObjectives(h))
        With scene.GetLabel("objective")
            .SetAlignedPosition 64,16, FlexDMD_Align_Center
            .Visible = False
        End With
        ' After 3 seconds, disable video/image and enable text objective
        If Not (vid Is Nothing) Then
            Set af = vid.ActionFactory
            Set blink = af.Sequence()
            blink.Add af.Wait(3)
            blink.Add af.Show(False)
            vid.AddAction blink
            Set af = scene.GetLabel("objective").ActionFactory
            Set blink = af.Sequence()
            blink.Add af.Wait(3)
            blink.Add af.Show(True)
            scene.GetLabel("objective").AddAction blink
        Else
            scene.GetLabel("objective").Visible = True
        End If
        DMDEnqueueScene scene,0,SceneSoundLengths(h),SceneSoundLengths(h),10000,"gotfx-"&hname&"battleintro"
    Else
        DisplayDMDText BattleObjectives(h),"",SceneSoundLengths(h)
        PlaySoundVol "gotfx-"&hname&"battleintro",VolDef
    End If
End Sub

' PictoPops Scene is a 3-frame layout with award for each
' pop in each frame. If all 3 awards match, flash text for 1 second
' If no FlexDMD, use short text on one line
Dim PictoScene
Sub DMDPictoScene
    Dim matched:matched=False
    Dim i
    Dim Frame(2)
    Dim pri,mintime:mintime=250:pri=3
    Dim PopsFont
    If BumperVals(0) = BumperVals(1) And BumperVals(0) = BumperVals(2) Then matched=True:mintime=1000:pri=1 'And Flash too
    If bUseFlexDMD Then
        If IsEmpty(PictoScene) Then
            ' Create the scene
            Set PictoScene = FlexDMD.NewGroup("pops")

            ' Create 3 frames. In each frame, put the text of the corresponding bumper award
            Dim poplabel
            For i = 0 to 2
                PictoScene.AddActor FlexDMD.NewFrame("popbox" & i)
                With PictoScene.GetFrame("popbox" & i)
                    .Thickness = 2
                    .SetBounds i*42, 0, 43, 32      ' Each frame is 43W by 32H, and offset by 0, 42, or 84 pixels
                End With
                PictoScene.AddActor FlexDMD.NewLabel("pop"&i, FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0), PictoPops(BumperVals(i))(0))
                
                ' Place the text in the middle of the frame and let FlexDMD figure it out
                Set poplabel = PictoScene.GetLabel("pop"&i)
                poplabel.SetAlignedPosition i*42+21, 16, FlexDMD_Align_Center
                If matched Then BlinkActor poplabel,0.1,5
            Next
        Else
            ' Existing scene. Update the text
            FlexDMD.LockRenderThread
            For i = 0 to 2
                Set poplabel = PictoScene.GetLabel("pop"&i)
                With poplabel
                    .Text = PictoPops(BumperVals(i))(0)
                    .SetAlignedPosition i*42+21, 16, FlexDMD_Align_Center
                ' Remove any existing action
                    .ClearActions()
                End With
                ' If the bumpers all match, flash the text and keep scene on screen for a second
                If matched Then BlinkActor poplabel,0.1,5:mintime=1000:pri=1
                debug.print "pop"&i&": X:" & poplabel.X & " Y:" & poplabel.Y
            Next
            FlexDMD.UnlockRenderThread
        End If

        DMDEnqueueScene PictoScene,pri,mintime,1000,300,""
    Else
        'TODO: Needs work, as default DMD display may have too big a font for 24 chars across
        DMD "",CL(0,PictoPops(BumperVals(0))(1) & " " &  PictoPops(BumperVals(1))(1) & " " & PictoPops(BumperVals(2))(1)),"",eNone,eNone,eNone,250,True,""
    End If
End Sub

' Summarize Battle. 2 scenes - animation and then summary. Format:
'
'   Battle Objective
'      SCORE             Combo X
'    "COMPLETED"
'
' Scenes: Stark: Arya stabbing guy on floor

' There's actually no standard for battle ending scenes. Needs further exploration
Sub DMDBattleEndScene(house,score,combo,combotext)

End Sub

' Battle Mode Target Hit Scene. Layout Might be unique to Stark
Sub DMDStarkBattleScene(house,num,score,line1,line2,just1,just2,sound)
    Dim scene,j3,x1,x2
    if bUseFlexDMD Then
        j3 = just1 + 6  ' Put Score on the same side as Line1 text, but at the bottom
        x1 = 2: x2 = 126
        If just1 = FlexDMD_Align_TopRight Then x1=126:x2=2
        Set scene = NewSceneWithVideo(HouseToString(house)&"hit","got-"&HouseToString(house)&"battlehit"&num)
        scene.AddActor FlexDMD.NewLabel("score",FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbWhite, 0),score)
        scene.AddActor FlexDMD.NewLabel("line1", FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0),line1)
        scene.AddActor FlexDMD.NewLabel("line2", FlexDMD.NewFont("FlexDMD.Resources.udmd-f3by5.fnt", vbWhite, vbWhite, 0),line2)
        scene.GetLabel("score").SetAlignedPosition x1,30,j3
        scene.GetLabel("line1").SetAlignedPosition x1,5,j3
        scene.GetLabel("line2").SetAlignedPosition x2,30,j3
        DMDEnqueueScene scene,1,1000,2000,1000,sound
    Else
        DisplayDMDText line1,score,2000
        PlaySoundVol sound,VolDef
    End If
End Sub

Dim ScoreScene
Sub DMDLocalScore
    Dim ComboFont,ScoreFont,i
    If IsEmpty(ScoreScene) Then
        Set ScoreScene = FlexDMD.NewGroup("ScoreScene")
        Set ComboFont = FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0)
	    Set ScoreFont = FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbWhite, 0) 
        ' Score text
        ScoreScene.AddActor FlexDMD.NewLabel("Score", ScoreFont, "0")
        ' Ball, credits
        ScoreScene.AddActor FlexDMD.NewLabel("Ball", ComboFont, "0")
        ScoreScene.AddActor FlexDMD.NewLabel("Credit", ComboFont, "0")
        If bFreePlay Then ScoreScene.GetLabel("Credit").Text = "Free Play"
        ' Align them 
        ScoreScene.GetLabel("Score").SetAlignedPosition 80,0, FlexDMD_Align_TopRight
        ScoreScene.GetLabel("Ball").SetAlignedPosition 32,20, FlexDMD_Align_Center
        ScoreScene.GetLabel("Credit").SetAlignedPosition 96,20, FlexDMD_Align_Center
        ' Divider
        ScoreScene.AddActor FlexDMD.NewFrame("HSeparator")
	    ScoreScene.GetFrame("HSeparator").Thickness = 1
	    ScoreScene.GetFrame("HSeparator").SetBounds 0, 24, 128,1
        ' Combo Multipliers
        For i = 0 to 4
            ScoreScene.AddActor FlexDMD.NewLabel("combo"&i, ComboFont, "0")
        Next
    End If
    FlexDMD.LockRenderThread
    ' Update fields
    ScoreScene.GetLabel("Score").Text = FormatScore(Score(CurrentPlayer))
    ScoreScene.GetLabel("Score").SetAlignedPosition 80,0, FlexDMD_Align_TopRight
    ScoreScene.GetLabel("Ball").Text = "Ball " & CStr(BallsRemaining(CurrentPlayer) - BallsPerGame + 1)
    If Not bFreePlay Then ScoreScene.GetLabel("Credit").Text = "Credits " & CStr(Credits)
    ' Update combo x
    For i = 0 to 4
        With ScoreScene.GetLabel("combo"&i)
            .Text = ComboMultiplier(i)&"X"
            .SetAlignedPosition i*25,31,FlexDMD_Align_BottomLeft
        End With
    Next        
    'TODO: During modes, the Score scene has a different layout - smaller score, and text objectives in the middle
    FlexDMD.UnlockRenderThread
    Set DefaultScene = ScoreScene
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