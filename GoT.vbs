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
Const BallSaverTime = 20      ' in seconds of the first ball
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
Const   FDsep = ","     ' The latest, not yet published, version has switched to "|"
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
Dim HighScore(16)
Dim HighScoreName(16)
Dim ReplayScore
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
Dim LightSaveState(100,4)   ' Array for saving state of lights. We save state, colour, fade to restore after Sequences (sequences only save state)
Dim TotalPlayfieldLights

' flags
Dim bMultiBallMode
Dim bAutoPlunger
Dim bAutoPlunged
Dim bJustPlunged
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
Dim bMysteryAwardActive     ' Table specific - used by Mystery Award for flipper control


' *********************************************************************
'                Visual Pinball Defined Script Events
' *********************************************************************

Sub Table1_Init()
    LoadEM
    Dim i
    Randomize

	' TODO need to look into right tilt settings
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

    'TODO. For debugging. Comment in once HS entry is debugged
    'If HighScore(0) = 100000 Then Reseths

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
    bMysteryAwardActive = False

	
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
        If(Tilted = False)Then GameAddCredit
    End If

    If keycode = PlungerKey Then
        Plunger.Pullback
        PlaySoundAt "fx_plungerpull", plunger
    End If

    If hsbModeActive Then
        EnterHighScoreKey(keycode)
        Exit Sub
    End If

    If bMysteryAwardActive Then
        UpdateMysteryAward(keycode)
        Exit Sub
    End If

    ' Normal flipper action

    If bGameInPlay AND NOT Tilted Then

        If keycode = LeftTiltKey Then CheckTilt 'only check the tilt during game
        If keycode = RightTiltKey Then CheckTilt
        If keycode = CenterTiltKey Then CheckTilt

        If keycode = LeftFlipperKey Then 
            SolLFlipper 1
            InstantInfoTimer.Enabled = True
            RotateLaneLights 1
            If InstantInfoTimer.UserValue = 0 Then 
                InstantInfoTimer.UserValue = keycode ' Record which key triggered the InstantInfo
            ElseIf InstantInfoTimer.UserValue <> keycode And bInstantInfo Then
                InfoPage = InfoPage + 1:InstantInfo
            End If
        ElseIf keycode = RightFlipperKey Then 
            SolRFlipper 1
            InstantInfoTimer.Enabled = True
            RotateLaneLights 0
            If InstantInfoTimer.UserValue = 0 Then 
                InstantInfoTimer.UserValue = keycode ' Record which key triggered the InstantInfo
            ElseIf InstantInfoTimer.UserValue <> keycode And bInstantInfo Then
                InfoPage = InfoPage + 1:InstantInfo
            End if
        End If

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
            If InstantInfoTimer.UserValue = keycode Then
                InstantInfoTimer.UserValue = 0
                InstantInfoTimer.Enabled = False
                If bInstantInfo Then
                    tmrDMDUpdate.Enabled = true
                    DMDFlush : AddScore 0
                    bInstantInfo = False
                End If
            End If
        ElseIf keycode = RightFlipperKey Then
            SolRFlipper 0
            If InstantInfoTimer.UserValue = keycode Then
                InstantInfoTimer.UserValue = 0
                InstantInfoTimer.Enabled = False
                If bInstantInfo Then
                    tmrDMDUpdate.Enabled = true
                    DMDFlush : AddScore 0
                    bInstantInfo = False
                End If
            End If
        End If
    End If
End Sub

Dim InfoPage
Sub InstantInfoTimer_Timer
    InstantInfoTimer.Enabled = False
    If NOT hsbModeActive Then
        bInstantInfo = True
        tmrDMDUpdate.Enabled = False
        DMDFlush
        InfoPage = 0
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
    HighScore(0) = 150000000
    HighScore(1) = 140000000
    HighScore(2) = 130000000
    HighScore(3) = 120000000
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
Dim HSscene

Sub CheckHighscore()
    Dim tmp
    tmp = Score(CurrentPlayer)

    If tmp> HighScore(1)Then 'add 1 credit for beating the highscore
        Credits = Credits + 1
        DOF 125, DOFOn
    End If

    ' TODO add support for all the other champions that GoT saves

    If tmp> HighScore(4)Then
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
    If bUseFlexDMD Then
        Set HSscene = FlexDMD.NewGroup("highscore")
        tmrDMDUpdate.Enabled = False
        ' Note, these fonts aren't included with FlexDMD. Change to stock fonts for other tables
        HSscene.AddActor FlexDMD.NewLabel("name",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite, vbWhite, 0),"YOUR NAME:")
        HSScene.GetLabel("name").SetAlignedPosition 2,2,FlexDMD_Align_TopLeft
        HSscene.AddActor FlexDMD.NewLabel("initials",FlexDMD.NewFont("skinny10x12.fnt", vbWhite, vbWhite, 0),"> ___ <")
        HSScene.GetLabel("initials").SetAlignedPosition 40,16,FlexDMD_Align_TopLeft
        DMDFlush()
        DMDDisplayScene HSscene
    End If
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
    TempBotStr = "> "
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
    
    If bUseFlexDMD Then
        FlexDMD.LockRenderThread
        With HSscene.GetLabel("initials")
            .Text = TempBotStr
            .SetAlignedPosition 40,16,FlexDMD_Align_TopLeft
        End With
        FlexDMD.UnlockRenderThread
    Else
        dLine(0) = ExpandLine(TempTopStr, 0)
        dLine(1) = ExpandLine(TempBotStr, 1)
        'DMDUpdate 0
        'DMDUpdate 1
    End If
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
    Savehs
    tmrDMDUpdate.Enabled = True
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
Const eBlink = 1

'Dim FlexPath
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
        .ProjectFolder = ".\"&cGameName&".FlexDMD\"
		.Color = RGB(255, 88, 32)
		.RenderMode = FlexDMD_RenderMode_DMD_GRAY_4
		.Width = 128
		.Height = 32
		.Clear = True
		.Run = True
	End With	

    'Dim fso
    'Set fso = CreateObject("Scripting.FileSystemObject")
    'curDir = fso.GetAbsolutePathName(".")
    'FlexPath = curDir & "\"&cGameName &".FlexDMD\"
End Sub

Sub DMD_Clearforhighscore()
	DMDClearQueue
End Sub

Sub DMDClearQueue				
	if bUseFlexDMD Then
		DMDqHead=0:DMDqTail=0
        FlexDMD.LockRenderThread
        FlexDMD.Stage.RemoveAll
        FlexDMD.UnlockRenderThread
        bDefaultScene = False
        DisplayingScene = Empty
	End If
End Sub

Sub PlayDMDScene(video, timeMs)
	if bUseFlexDMD and UltraDMDVideos Then
		' Note Video needs to not have sounds and must be more then 3 seconds (Export from iMovie, I chose 540p, high quality, Faster compression.
		'UltraDMD.DisplayScene00 video, "", 15, "", 15, UltraDMD_Animation_None, timeMs, UltraDMD_Animation_None
		'UltraDMD.DisplayScene00ExWithId video, False, video, "", 15, 15, "", 15, 15, 14, 4000, 14
	End If
End Sub

Sub DisplayDMDText(Line1, Line2, duration)
	debug.print "OldDMDText " & Line1 & " " & Line2
	if bUseFlexDMD Then
		'UltraDMD.DisplayScene00 "", Line1, 15, Line2, 15, 14, duration, 14
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
		'UltraDMD.DisplayScene00 "", Line1, 15, Line2, 15, 14, duration, 14
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
		'UltraDMD.DisplayScene00ExwithID id, false, "", toptext, 15, 0, bottomtext, 15, 0, 14, duration, 14
	Elseif bUsePUPDMD Then
		If bPupStarted then pupDMDDisplay "default", toptext & "^" & bottomtext, "" ,Duration/1000, 0, 10
	End If 
End Sub

Sub DMDMod(id, toptext, bottomtext, duration) 'used in the highscore entry routine
	if bUseFlexDMD then 
		'UltraDMD.ModifyScene00Ex id, toptext, bottomtext, duration
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
        debug.log "Call to old DMDScore routine" 
		'	DisplayDMDText RL(0,FormatScore(Score(CurrentPlayer))), "", 1000 
	End If
End Sub

Sub DMDScoreNow
    DMDFlush
    DMDScore
End Sub

Sub DMD(Text0, Text1, Text2, Effect0, Effect1, Effect2, TimeOn, bFlush, Sound)
    Dim scene,line0
    if bUseFlexDMD Then
        Set scene = FlexDMD.NewGroup("dmd")
        If Text0 <> "" Then
            scene.AddActor FlexDMD.NewLabel("line0",FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0), Text0)
            Set line0 = scene.GetLabel("line0")
            line0.SetAlignedPosition 0,0,FlexDMD_Align_TopLeft
            if Effect0 = eBlink Then BlinkActor line0,100,int(TimeOn/200)
        End If
        If Text1 <> "" Then
            scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbWhite, 0), Text1)
            Set line0 = scene.GetLabel("line1")
            line0.SetAlignedPosition 0,9,FlexDMD_Align_TopLeft
            if Effect1 = eBlink Then BlinkActor line0,100,int(TimeOn/200)
        End If
        If Text2 <> "" Then
            scene.AddActor FlexDMD.NewLabel("line2",FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0), Text2)
            Set line0 = scene.GetLabel("line2")
            line0.SetAlignedPosition 0,30,FlexDMD_Align_BottomLeft
            if Effect2 = eBlink Then BlinkActor line0,100,int(TimeOn/200)
        End If
        if bFlush Then DMDClearQueue
        DMDEnqueueScene scene,0,TimeOn,TimeOn,1000,Sound
    Else
        DisplayDMDText Text0, Text1, TimeOn
        'if bUsePUPDMD and bPupStarted Then pupDMDDisplay "default", Text0 & "^" & Text1, "" ,2, 0, 10
        'if (bUsePUPDMD) Then pupDMDDisplay "attract", Text1 & "^" Text2, "@vidIntro.mp4" ,9, 1,		10
        PlaySoundVol Sound, VolDef
    End If
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
    i = InStr(NumString,"+")
    If i > 0 Then
        Dim exp
        ' We got a scientific notation number, convert to a string
        exp = right(Numstring,Len(NumString)-i)
        Numstring = left(NumString,i-1)
        'Get rid of the period between the first and second digit
        NumString = Replace(NumString,".","")
        ' And add 0s to the right length
        For i = Len(NumString)-1 to exp : NumString = NumString & "0" : Next
    End If

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
    debug.print "Enqueued scene at "&i& " name: "&scene.Name
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

' Return the total length of the display queue, in ms
' Mainly used by end-of-ball processing to delay Bonus until all scenes have shown
' This isn't 100% accurate, as the last scene at a given priority level will play for maxtime
' before allowing a scene at a lower priority level play. We just add up all the mintimes
Function DMDGetQueueLength
    Dim i,j,len
    DMDGetQueueLength = 0
    j=0:len=0
    If DMDqTail = 0 Then Exit Function
    For j = 0 to 3  ' We don't care about really low priority scenes in this context
        For i = DMDqHead to DMDqTail
            If DMDSceneQueue(i,4) > DMDtimestamp Then 
                If DMDSceneQueue(i,1) = j And DMDSceneQueue(i,4) > DMDtimestamp+len Then        'equal priority queued scene
                    len = len + DMDSceneQueue(i,2)    ' so use mintime
                End If
            End If
        Next
    Next
    DMDGetQueueLength = len
End Function      

' Update DMD Scene. Called every 100ms
' Most of the work is done here. If scene queue is empty, display default scene (score, Game Over, etc)
' If scene queue isn't empty, check to see whether current scene has been on long enough or overwridden by a higher priority scene
' If it has, move to next spot in queue and search all of the queue for scene with highest priority, skipping any scenes that have timed out while waiting
Dim bDefaultScene,DefaultScene
Sub tmrDMDUpdate_Timer
    Dim i,j,bHigher,bEqual
    tmrDMDUpdate.Enabled = False
    DMDtimestamp = DMDtimestamp + 100   ' Set this to whatever frequency the timer uses
    If DMDqTail <> 0 Then
        ' Process queue
        ' Check to see if queue is idle (default scene on). If so, immediately play first item
        If bDefaultScene or (IsEmpty(DisplayingScene) And DMDqHead = 0) Then
            bDefaultScene = False
            debug.print "Idle: Displaying scene at " & DMDqHead & " Tail: "&DMDqTail
            DMDDisplayScene DMDSceneQueue(DMDqHead,0)
            DMDSceneQueue(DMDqHead,6) = DMDtimestamp
            If DMDSceneQueue(DMDqHead,5) <> ""  Then 
                PlaySoundVol DMDSceneQueue(DMDqHead,5),VolDef
            ' Note, code below is game-specific - triggers the SuperJackpot scene update timer as soon as the scene plays
            ElseIf DMDSceneQueue(DMDqHead,0).Name = "bwsjp" Then
                tmrSJPScene.UserValue = 0
                tmrSJPScene.Interval = 300
                tmrSJPScene.Enabled = True
            End If
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
                    tmrDMDUpdate.Enabled = True
                ElseIf DMDqHead = DMDqTail Then ' queue is empty
                    DMDqHead = 0:DMDqTail = 0
                    tmrDMDUpdate.Enabled = True
                Else
                    ' Find the next scene with the highest priority
                    j = DMDqHead
                    For i = DMDqHead to DMDqTail-1
                        If DMDSceneQueue(i,1) < DMDSceneQueue(j,1) Then j=i:DMDqHead=i
                    Next

                    ' Play the scene, and a sound if there's one to accompany it
                    bDefaultScene = False
                    debug.print "Displaying scene at " &j & " name: "&DMDSceneQueue(j,0).Name & " Head: "&DMDqHead & " Tail: "&DMDqTail
                    DMDSceneQueue(j,6) = DMDtimestamp
                    DMDDisplayScene DMDSceneQueue(j,0)
                    If DMDSceneQueue(j,5) <> ""  Then 
                        PlaySoundVol DMDSceneQueue(j,5),VolDef
                    ' Note, code below is game-specific - triggers the SuperJackpot scene update timer as soon as the scene plays
                    ElseIf DMDSceneQueue(j,0).Name = "bwsjp" Then
                        tmrSJPScene.UserValue = 0
                        tmrSJPScene.Interval = 600
                        tmrSJPScene.Enabled = True
                    End If
                End If
            End If
        End If
    End If
    If DMDqTail = 0 Then ' Queue is empty
        ' Exit fast if defaultscene is already showing
        if bDefaultScene or IsEmpty(DefaultScene) then tmrDMDUpdate.Enabled = True : Exit Sub
        bDefaultScene = True
        If TypeName(DefaultScene) = "Object" Then
            DMDDisplayScene DefaultScene
        Else
            debug.print "DefaultScene is not an object!"
        End If
    End If
    tmrDMDUpdate.Enabled = True
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
    Set actor = FlexDMD.NewVideo(name&"vid",videofile & ".gif")
    If actor is Nothing Then
        Set actor = FlexDMD.NewImage(name&"img",videofile&".png")
        if actor is Nothing Then 
            debug.print "Warning: "&videofile&" image not found"
            Exit Function
        End if
    End If
    NewSceneWithVideo.AddActor actor
End Function

' Create a new scene with an image file. If that's not found, 
' create a new blank scene
Function NewSceneWithImage(name,imagefile)
    Dim actor
    Set NewSceneWithImage = FlexDMD.NewGroup(name)
    Set actor = FlexDMD.NewImage(name&"img",imagefile&".png")
    if actor is Nothing Then Exit Function
    NewSceneWithImage.AddActor actor
End Function

' Create a scene from a series of images. The only reason to use this
' function is if you need to use transparent images. If you don't, use
' an animated GIF - much easier. However, this does have one other advantage over
' an animated GIF: FlexDMD will loop animated GIFs, regardless of what the loop attribute is set to in the GIF
'  name   - name of the scene object returned
'  imgdir - directory inside the FlexDMD project folder where the images are stored
'  start  - number of first image
'  num    - number of images, numbered from image1..image<num>
'  fps    - frames per second - a delay of 1/fps is used between frames
'  hold   - if non-zero, how long to hold the last frame visible. If 0, the last scene will end with the last frame visible
'  repeat - Number of times to repeat. 0 or 1 means don't repeat
Function NewSceneFromImageSequence(name,imgdir,num,fps,hold,repeat)
    Set NewSceneFromImageSequence = NewSceneFromImageSequenceRange(name,imgdir,1,num,fps,hold,repeat)
End Function

Function NewSceneFromImageSequenceRange(name,imgdir,start,num,fps,hold,repeat)
    Dim scene,i,actor,af,blink,total,delay,e
    total = num/fps + hold
    delay = 1/fps
    e = start+num-1
    Set scene = FlexDMD.NewGroup(name)
    For i = start to e
        Set actor = FlexDMD.NewImage(name&i,imgdir&"\image"&i&".png")
        actor.Visible = 0
        Set af = actor.ActionFactory
        Set blink = af.Sequence()
        blink.Add af.Wait((i-start)*delay)
        blink.Add af.Show(True)
        blink.Add af.Wait(delay*1.2)    ' Slightly longer than one frame length to ensure no flicker
        if i=e And hold > 0 Then blink.Add af.Wait(hold)
        if repeat > 1 or i<e Then 
            blink.Add af.Show(False)
            blink.Add af.Wait((e-i)*delay)
        End If
        If repeat > 1 Then actor.AddAction af.Repeat(blink,repeat) Else actor.AddAction blink
        scene.AddActor actor
    Next
    Set NewSceneFromImageSequenceRange = scene
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

' Add action to delay toggling the state of an actor
' If on=true then delay then show, otherwise, delay then hide
Sub DelayActor(actor,delay,bOn)
    Dim af,blink
    Set af = actor.ActionFactory
    Set blink = af.Sequence()
    blink.Add af.Wait(delay)
    blink.Add af.Show(bOn)
    actor.AddAction blink
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

Sub NxtLUT:LUTImage = (LUTImage + 1)MOD 10:UpdateLUT:SaveLUT:End Sub

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
Const cyan = 13
Const midblue = 12
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
        Case cyan
            n.color = RGB(0,18,18)
            n.colorfull = RGB(0, 224, 240)
        Case midblue
            n.color = RGB(0,0,18)
            n.colorfull = RGB(0,0,255)
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
            n.colorfull = RGB(0, 160, 255)
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

Sub GiIntensity(i)
    Dim bulb
    For each bulb in aGiLights
        bulb.IntensityScale = i
    Next
    For each bulb in aFiLights
        bulb.IntensityScale = i
    Next
End Sub

Sub SavePlayfieldLightState
    Dim i,a
    i = 0
    For each a in aPlayfieldLights
        LightSaveState(i,0) = a.State
        LightSaveState(i,1) = a.Color
        LightSaveState(i,2) = a.Colorfull
        LightSaveState(i,3) = a.FadeSpeedUp
        LightSaveState(i,4) = a.FadeSpeedDown
        i = i + 1
    Next
End Sub

Sub RestorePlayfieldLightState(state)
    Dim i,a
    i = 0
    For each a in aPlayfieldLights
        If state Then a.State = LightSaveState(i,0)
        a.Color = LightSaveState(i,1)
        a.ColorFull = LightSaveState(i,2)
        a.FadeSpeedUp = LightSaveState(i,3)
        a.FadeSpeedDown = LightSaveState(i,4)
        i = i + 1
    Next
End Sub

' Set Playfield lights to slow fade a color
Sub PlayfieldSlowFade(color,fadespeed)
    Dim a
    For each a in aPlayfieldLights
        SetLightColor a,color,-1
        a.FadeSpeedUp = fadespeed
        a.FadeSpeedDown = fadespeed
    Next
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
    'StartLightSeq
    GameStartAttractMode
End Sub

Sub StopAttractMode
    GameStopAttractMode
    'LightSeqAttract.StopPlay
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
    RestorePlayfieldLightState False    ' Restore color and fade speed but not state. Sequencer takes care of that
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

' Not used for GoT table. See GameStartAttractMode()
Sub ShowTableInfo
   Dim tmp
   'info goes in a loop only stopped by the credits and the startkey
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

        ' is the ball saver active, (or ready to be activated but the ball sewered right away)
        If(bBallSaverActive = True and bEarlyEject = False) Or (bBallSaverReady = True AND BallSaverTime <> 0 And bBallSaverActive = False) Then
            DoBallSaved 0
        Else
        	bEarlyEject = False
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
    ' GoT Premium/LE has no skill shot
    If bSkillShotReady Then
        PlaySong "mu_shooterlane"
        UpdateSkillshot()
        ' show the message to shoot the ball in case the player has fallen sleep
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
    bJustPlunged = True
    tmrJustPlunged.Interval = 2500
    tmrJustPlunged.Enabled = 1

    GameDoBallLaunched
    bAutoPlunged = False
    bBallSaved = False
End Sub

Sub tmrJustPlunged_Timer : bJustPlunged = False : End Sub

' Not used in this game. GoT has its own BallSaver logic
' Sub EnableBallSaver(seconds)
'     'debug.print "Ballsaver started"
'     ' set our game flag
'     bBallSaverActive = True
'     bBallSaverReady = False
'     ' start the timer
'     BallSaverTimerExpired.Interval = 1000 * seconds
'     BallSaverTimerExpired.Enabled = True
'     BallSaverSpeedUpTimer.Interval = 1000 * seconds -(1000 * seconds) / 3
'     BallSaverSpeedUpTimer.Enabled = True
'     ' if you have a ball saver light you might want to turn it on at this point (or make it flash)
'     LightShootAgain.BlinkInterval = 160
'     LightShootAgain.State = 2
' End Sub

' ' The ball saver timer has expired.  Turn it off AND reset the game flag
' '
' Sub BallSaverTimerExpired_Timer()
'     'debug.print "Ballsaver ended"
'     BallSaverTimerExpired.Enabled = False
'     ' clear the flag
'     bBallSaverActive = False
'     ' if you have a ball saver light then turn it off at this point
'     LightShootAgain.State = 0
' End Sub

' Sub BallSaverSpeedUpTimer_Timer()
'     'debug.print "Ballsaver Speed Up Light"
'     BallSaverSpeedUpTimer.Enabled = False
'     ' Speed up the blinking
'     LightShootAgain.BlinkInterval = 80
'     LightShootAgain.State = 2
' End Sub






















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
Const SpinnerAddValue = 500      ' Base amount that Spinner's value increases by for each target hit.

' Global table-specific variables
Dim HouseColor
Dim HouseSigil
Dim HouseShield
Dim HouseAbility
Dim LoLLights
Dim ComboLaneMap
Dim ComboLights
Dim GoldTargetLights
Dim pfmuxlights
Dim BattleObjectives
Dim BattleObjectivesShort
Dim QAnimateTimes       ' Length of each qualifying shot's animation time
Dim SwordNames

' Global variables with player data - saved across balls and between players
Dim PlayerMode          ' Current player's mode. 0=normal, -1 = select house, -2 = select battle, -3 = select mystery, 1 = in battle
Dim SelectedHouse       ' Current Player's selected house
Dim bTopLanes(2)        ' State of top lanes
Dim LoLTargetsCompleted ' Number of times the target bank has been completed
Dim WildfireTargetsCompleted ' Number of times wildfire target bank has been completed
Dim BWMultiballsCompleted
Dim bBWMultiballActive
Dim bBlackwaterSJPMode
Dim WallMBCompleted
Dim WallMBLevel
Dim bWallMBReady
Dim WallJPValue
Dim bLockIsLit
Dim bEBisLit            ' TODO: Find out whether this carries over
Dim bWildfireTargets(2) ' State of Wildfire targets
Dim bLoLLit             ' Whether Lord of Light Outlanes are lit
Dim bLoLUsed            ' Whether Lord of Light has been used this game
Dim bEarlyEject         ' Indicates whether outlanes caused an early eject of a new ball
Dim CompletedHouses     ' Number of completed houses - determines max spinner level and triggers HOTK and Iron Throne modes
Dim TotalGold           ' Total gold collected in the game
Dim CurrentGold         ' Current gold balance
Dim TotalWildfire
Dim CurrentWildfire
Dim SwordMask
Dim SwordsCollected
Dim CastlesCollected
Dim BlackwaterScore
Dim bGoldTargets(5)
Dim bTargaryenInProgress
Dim bMysteryLit
Dim bSwordLit

' Support for game timers
Dim GameTimeStamp       ' Game time in 1/10's of a second, since game start
Dim bGameTimersEnabled  ' Flag for whether any timers are enabled
Dim TimerFlags(30)      ' Flags for each timer's state
Dim TimerTimestamp(30)  ' Each timer's end timestamp
Dim TimerSubroutine     ' Names of subroutines to call when each timer's time expires
' Timers 1 - 4 can't be frozen. if adding more unfreezable timers, put them next and adjust the number in tmrGame_Timer sub
TimerSubroutine = Array("","UpdateChooseBattle","PreLaunchBattleMode","LaunchBattleMode","UpdateBattleMode","MysteryAwardTimer", _
                        "BattleModeTimer1","BattleModeTimer2", _ 
                        "MartellBattleTimer","HurryUpTimer","ResetComboMultipliers","ModePauseTimer","BlackwaterSJPTimer","WildfireModeTimer", _
                        "UPFMultiplierTimer","PFMStateTimer","PFMultiplierTimer","BallSaveTimer","BallSaverSpeedUpTimer")
Const tmrUpdateChooseBattle = 1 ' Update DMD timers during Choose Your Battle
Const tmrChooseBattle   = 2       ' Countdown timer for choosing your Battle
Const tmrLaunchBattle   = 3       ' After battle is chosen, countdown to launch while scenes play. Can be aborted with flippers
Const tmrUpdateBattleMode = 4   ' Update DMD during battle mode
Const tmrMysteryAward   = 5
Const tmrBattleMode1    = 6        ' "Top" house battle countdown timer
Const tmrBattleMode2    = 7        ' "Bottom" house battle countdown timer
Const tmrMartellBattle  = 8      ' 10-second timer for Martell orbits
Const tmrHurryUp        = 9            ' When HurryUp is active, update DMD 5 times/second
Const tmrComboMultplier = 10     ' Timeout timer for Combo multipliers
Const tmrModePause      = 11         ' "no activity" timer that will pause battle mode timers if it elapses
Const tmrBlackwaterSJP  = 12     ' SuperJackpot battering ram countdown timer
Const tmrWildfireMode   = 13      ' Wildfire Mini Mode timer
Const tmrUPFMultiplier  = 14
Const tmrPFMState       = 15
Const tmrPFMultiplier   = 16
Const tmrBallSave       = 17
Const tmrBallSaveSpeedUp= 18
Const MaxTimers         = 18     ' Total number of defined timers. There MUST be a corresponding subroutine for each

'HurryUp Support
Dim HurryUpValue
Dim bHurryUpActive
Dim HurryUpCounter
Dim HurryUpGrace
Dim HurryUpScene
Dim HurryUpChange
Dim TGHurryUpValue
Dim bTGHurryUpActive
Dim TGHurryUpCounter
Dim TGHurryUpGrace
Dim TGHurryUpScene
Dim TGHurryUpChange

' Player state data
Dim House(4)  ' Current state of each house - some house modes aren't saved, while others are. May need a Class to save detailed state
Dim PlayerState(4) ' Structure to save global player-specific variables across balls

'Other
Dim bBattleInstructionsDone ' Whether Battle selection instructions have been shown this game

' Ball-specific variables (not saved across balls)
Dim PlayfieldMultiplierVal
Dim SpinnerValue
Dim AccumulatedSpinnerValue ' Amount that has accumulated in the last 2 seconds
Dim SpinnerLevel
Dim DroppedTargets      ' Number of targets dropped
Dim ComboMultiplier(5)
Dim bWildfireLit
Dim bPlayfieldValidated
Dim bElevatorShotUsed   ' Whether a shot to the upper playfield via the right orbit has been made this ball yet or not
Dim bCastleShotAvailable ' Whether the ball has just been plunged to the upper PF
Dim HouseBattle1        ' When in battle, the primary (top) House
Dim HouseBattle2        ' When in two-way battle, the second House
Dim PFMState

HouseColor = Array(white,white,yellow,red,purple,green,amber,blue)
' Assignment of centre playfield shields
HouseSigil = Array(li38,li38,li41,li44,li47,li50,li53,li32)
' Assignment of "shot" shields. Last 3 are Upper PF target lights
HouseShield = Array(li141,li141,li26,li114,li86,li77,li156,li98,li189,li192,li195)
' House Ability strings, used during House Selection
HouseAbility = Array("","INCREASE WINTER IS COMING","ADVANCE WALL MULTIBALL","COLLECT MORE GOLD","PLUNDER RIVAL ABILITIES","INCREASE HAND OF THE KING","ACTION BUTTON=ADD A BALL","")

BattleObjectives = Array("", _ 
            "ARYA BECOMES AN ASSASSIN"&vbLf&"RAMPS BUILD VALUE"&vbLf&"ORBITS COLLECT VALUE", _
            "STANNIS VS THE WILDLINGS"&vbLf&"SPINNER BUILDS VALUE"&vbLf&"COLLECT AT THE 3 TARGETS", _
            "BRING BACK MYRCELLA"&vbLf&"GOLD TARGETS LIGHT RED SHOTS"&vbLf&"5 RED SHOTS TO FINISH", _
            "GREYJOY TAKES WINTERFELL"&vbLf&"5 SHOTS TO FINISH"&vbLf&"TIMER RESETS AFTER EACH", _
            "LORD LORAS JOUSTING THE MOUNTAIN"&vbLf&"TWO BANK WILL SCORE HITS"&vbLf&"SCORE 3 HITS TO WIN", _
            "VIPER VERSUS THE MOUNTAIN"&vbLf&"SHOOT 3 ORBITS IN A ROW"&vbLf&"LEFT RAMP COLLECTS",_
            "DEFEAT VISERION"&vbLf&"SHOOT 3 HURRY UPS"&vbLf&"TO DEFEAT VISERION", _
            "DEFEAT RHAEGAL"&vbLf&"SHOOT 5 HURRY UPS"&vbLf&"TO DEFEAT RHAEGAL", _
            "DEFEAT DROGON"&vbLf&"SHOOT 3 HURRY UPS"&vbLf&"TO DEFEAT DROGON")

BattleObjectivesShort = Array("","ARYA'S TRAINING","AID FOR THE WALL","SAVE MYRCELLA","WINTERFELL BURNS",_
            "JOUSTING","TRIAL BY COMBAT","DEFEAT VISERION","DEFEAT RHAEGAL","DEFEAT DROGON")

' Length of each scene in the qualifying shot animations. Arranged as (House# x 3) + HitNumber
QAnimateTimes = Array(0,0,0,0,1,1,1.8,3,1,1,2,1.5,2,2.5,2.5,2.5,1.3,2.6,0,4.8,1.3,2.2,1.6,3.9,3.1)

SwordNames = Array("NEEDLE","ICE","OATHKEEPER","LONGCLAW","DARK SISTER","LIGHTBRINGER","HEARTEATER","WIDOW'S WAIL")

' Assignment of Lol Target lights
LoLLights = Array(li17,li20,li23)
'Assignment of Gold target lights
GoldTargetLights = Array(li92,li105,li120,li135,li147)
' Map of house name to combo lane (Greyjoy is combo lane1, Targaryen is Combo lane2, etc)
ComboLaneMap = Array(0,4,0,3,1,0,5,2)

ComboLights = Array(li89,li89,li101,li117,li144,li159)

pfmuxlights = Array(li56,li59,li62,li65)

' Upper PF lights
Dim UPFLights
UPFLights = Array(li186,li186,li189,li180,li192,li183,li195,li198,li210,li207,li204,li201,li213,li216)



' This class holds player state that is carried over across balls
Class cPState
    Dim bWFTargets(2)
    Dim WFTargetsCompleted
    Dim LTargetsCompleted
    Dim myLoLLit
    Dim myMysteryLit
    Dim mySwordsLit
    Dim myLoLUsed
    Dim myLockIsLit
    Dim myBWMultiballsCompleted
    Dim myWallMBCompleted
    Dim myWallMBLevel
    Dim myWallMBReady
    Dim myWallJPValue
    Dim myBallsInLock
    Dim myGoldTargets(5)
    Dim myTotalGold
    Dim myCurrentGold
    Dim myTotalWildfire
    Dim mySwordMask         ' Bitmask of which swords have been collected
    Dim mySwordsCollected
    Dim myCastlesCollected
    Dim myCurrentWildfire
    Dim myTargaryenInProgress
    Dim myPFMState

    Public Sub Save
        Dim i
        bWFTargets(0) = bWildfireTargets(0):bWFTargets(1) = bWildfireTargets(1)
        WFTargetsCompleted = WildfireTargetsCompleted
        LTargetsCompleted = LoLTargetsCompleted
        myLoLLit = bLoLLit
        myLoLUsed = bLoLUsed
        myLockIsLit = bLockIsLit
        myBWMultiballsCompleted = BWMultiballsCompleted
        myWallMBCompleted = WallMBCompleted
        myWallMBLevel = WallMBLevel
        myWallMBReady = bWallMBReady
        myBallsInLock = BallsInLock
        myWallJPValue = WallJPValue
        myTotalGold = TotalGold
        myCurrentGold = CurrentGold
        myTotalWildfire = TotalWildfire
        myCurrentWildfire = CurrentWildfire
        mySwordsCollected = SwordsCollected
        myCastlesCollected = CastlesCollected
        myTargaryenInProgress = bTargaryenInProgress
        mySwordsLit = bSwordLit
        myMysteryLit = bMysteryLit
        mySwordMask = SwordMask
        If PFMState = 2 Then myPFMState = 2 Else myPFMState = 0
        For i = 0 to 5:myGoldTargets(i) = bGoldTargets(i):Next
    End Sub

    Public Sub Restore
        Dim i
        bWildfireTargets(0) = bWFTargets(0):bWildfireTargets(1) = bWFTargets(1)
        WildfireTargetsCompleted = WFTargetsCompleted
        LoLTargetsCompleted = LTargetsCompleted
        bLoLLit = myLoLLit
        bLoLUsed = myLoLUsed
        bLockIsLit = myLockIsLit
        BWMultiballsCompleted = myBWMultiballsCompleted
        WallMBCompleted = myWallMBCompleted
        WallMBLevel = myWallMBLevel
        bWallMBReady = myWallMBReady
        WallJPValue = myWallJPValue
        BallsInLock = myBallsInLock
        SwordsCollected = mySwordsCollected
        TotalGold = myTotalGold
        TotalWildfire = myTotalWildfire
        CurrentWildfire = myCurrentWildfire
        bTargaryenInProgress = myTargaryenInProgress
        PFMState = myPFMState
        bMysteryLit = myMysteryLit
        bSwordLit = mySwordsLit


        CurrentGold = myCurrentGold
        CastlesCollected = myCastlesCollected
        For i = 0 to 5:bGoldTargets(i) = myGoldTargets(i):Next

    End Sub
End Class

Dim BWExplosionTimes
BWExplosionTimes = Array(1,1,2.9,2.8,3.6,1)

' This class holds everything to do with House logic.
' We also put most of the Blackwater Jackpot processing in here, as it uses the same shots
Class cHouse
    Dim bSaid(7)             ' Whether the house's name has been said yet during ChooseHouse state
    Dim bQualified(7)        ' Whether the house has qualified for battle
    Dim bCompleted(7)        ' Whether battle has been completed
    Dim MyBattleState(7)      ' Placeholder for current battle state
    Dim QualifyCount(7)     ' Count of how many times the qualifying shot has been made for each house
    Dim HouseSelected
    Dim QualifyValue        ' Hold the current value for a qualifying target hit
    Dim bBattleReady
    Dim BWJackpotShots(7)     ' Track how many shots are needed for each jackpot shot
    Dim BWJackpotLevel
    Dim BWSJPLevel
    Dim BWSJPBaseValue
    Dim BWJackpotValue
    Dim BWState
    Dim UPFState            ' Upper PF State
    Dim UPFLevel            ' Progress towards Castle Multiball
    Dim UPFShotMask         ' Lit shots on the Upper PF
    Dim UPFCastleShotMask   ' Saved shot mask state for standard mode
    Dim UPFMultiplier
    Dim UPFSJP
    Dim WiCValue            ' Current WiC HurryUp Value
    Dim WiCTotal            ' Total accumulated WiC HurryUp
    Dim WiCShots            ' Completed Iced Over shots
    Dim WiCs                ' Completed WiC HurryUps (countdown to Winter Has Come MB)
    Dim WiCMask             ' Mask of which shots have completed WiCs
    Dim CurrentWiCShot      ' If a WiC HurryUp is active, which shot is flashing. 0 if not active
    Dim CurrentWiCShotCombo ' Combo multiplier on shot that WiC HurryUp started on, when it started
    Dim ActionAbility       ' The house ability you currently have
    Dim ActionButtonUsed    ' Whether the ability has been used on this ball

    Private Sub Class_Initialize(  )
		dim i
		For i = 0 to 7
			bQualified(i) = False
            bCompleted(i) = False
            bSaid(i) = False
            QualifyCount(i) = 0
            Set MyBattleState(i) = New cBattleState
            MyBattleState(i).SetHouse = i
		Next
        HouseSelected = 0
        QualifyValue = 100000
        bBattleReady = False
        LockWall.collidable = False
        UPFState = 0
        UPFLevel = 1
        UPFMultiplier = 1
        UPFShotMask = 42    ' Shots 1, 3 and 5
        WicTotal = 0
        WicShots = 0
        WiCs = 0
        WiCMask = 0
        ActionButtonUsed = 0
	End Sub

    Public Property Let MyHouse(h) 
        HouseSelected = h
        bQualified(h) = True
        QualifyCount(h) = 3
        ActionAbility = h
        If h = Greyjoy Then bCompleted(h) = True Else BattleReady = True
        ' For testing, let us test Targaryen battle mode by choosing Targ to start
        'If (h = Greyjoy or h = Targaryen) Then bCompleted(h) = True Else BattleReady = True

        'TODO: Set all house-specific settings when House is Set. E.g. Persistent and Action functions
        ' Persistent:
        '  - Stark. 10M added to base value of all WiC HurryUps
        '  - Baratheon: Drop targets advance wall multiball - Wall MB starts at 4. Also increases Jackpot values during Wall MB
        '  √ Lannister: everything scores more gold
        '  - Greyjoy. Gain other houses' persistent abilities once you complete them, and they stack
        '  - Tyrell: inside lane combo mult
        '  - Martell: None
        '  - Targaryen: Mode is completed
        '
        ' Action buttons
        '  - Stark: Dire Wolf: Only active during Battle - finishes current HouseBattle1 and scores 5M
        '  √ Barahteon: Red Woman - light Lord Of Light for a few seconds only. Can be used once per ball
        '  √ Lannister: Buy playfield X's for successively more gold
        '  √ Greyjoy: Plunders other houses' action button
        '  - Tyrell: Iron Bank - sell all X's for gold
        '  √ Martell: Add-A-Ball
        '  - Targaryen: Freeze timers for 15s (except ball save timer). Timers started during freeze don't start until after
        If h = Lannister Then AddGold 750 Else TotalGold = 100 : CurrentGold = 100
        If h = Baratheon Then AdvanceWallMultiball 2 : WallJPValue = 925000 Else WallJPValue = 425000
        PlaySoundVol "got-"&HouseToString(h)&"motto",VolDef
    End Property
	Public Property Get MyHouse : MyHouse = HouseSelected : End Property

    Public Property Let BattleReady(e)
        if Not bMultiBallMode Then 
            bBattleReady = e
            if (e) Then 
                LockWall.collidable = True
            ElseIf RealBallsInLock = 0 And bLockIsLit = False And PlayerMode <> -2 Then
                LockWall.collidable = False
            End if
        End If
    End Property

    Public Property Get Qualified(h) : Qualified = bQualified(h) : End Property
    Public Property Let Qualified(h,v) : bQualified(h) = v : End Property
    Public Property Get Completed(h) : Completed = bCompleted(h) : End Property
    Public Property Get BattleState(h) : debug.print h : Set BattleState = MyBattleState(h) : End Property
    Public Property Get BWJackpot : BWJackpot = BWJackpotValue : End Property
    Public Property Let BWJackpot(v) : BWJackpotValue = v : End Property

    ' Reset any state that starts over on a new ball
    Public Sub ResetForNewBall
        Dim i,t
        t = bTargaryenInProgress
        For i = 1 to 7
            If bQualified(i) and Not bCompleted(i) then t = True
        Next
        BattleReady = t
        UPFState = 0
        UPFMultiplier = 1
        If ActionAbility <> Lannister Then ActionButtonUsed = False
    End Sub

    ' Say the house name. Include "house " if not said before
    Public Sub Say(h)
        Dim tmp
        if (bSaid(h)=2) Then tmp="" Else tmp="house-":bSaid(h)=1
        PlaySoundVol "say-" & tmp & HouseToString(h) & "1", VolDef
    End Sub

    Public Sub StopSay(h)
        Dim tmp
        if bSaid(h)=0 Then Exit Sub
        if (bSaid(h)=2) Then tmp="" Else tmp="house-"
        StopSound "say-" & tmp & HouseToString(h) & "1"
        bSaid(h) = 2
    End Sub

    ' Set the shield/sigil lights to the houses' current state
    Public Sub ResetLights
        If HouseSelected = 0 Then Exit Sub       ' Do nothing if we're still in Choose House mode
        SetModeLights   ' If in regular mode, this disables the timers on the shield lights
        If PlayerMode = 1 Then  Exit Sub
        If PlayerMode = 2 Then SetLightColor HouseShield(CurrentWiCShot), ice, 2 : Exit Sub
        Dim i
        Dim j
        j=0
        
        For i = Stark to Targaryen
            If (WiCMask And 2^i) > 0 Then
                SetLightColor HouseShield(i),HouseColor(HouseSelected),1
            ElseIf (bQualified(i) or bCompleted(i)) And (WiCMask And 2^i) = 0 Then
                SetLightColor HouseShield(i), ice, 1
            Else
                SetLightColor HouseShield(i),HouseColor(i),1
            End If 
            If bCompleted(i) Then 
                SetLightColor HouseSigil(i),HouseColor(HouseSelected),1
                j = j + 1
            ElseIf bCompleted(i) = False and (bQualified(i)) Then 
                SetLightColor HouseSigil(i),HouseColor(i),2
            Else
                HouseSigil(i).State = 0
            End If
        Next
        CompletedHouses = j
        if bBattleReady Then SetLightColor li108,white,2 Else SetLightColor li108,white,0
        'TODO: Set HOTK and IronThrone lights too
    End Sub

    Public Sub SetShieldLights
        Dim i,j
        For i = 1 to 7
            ModeLightState(i,0) = 1
            ModeLightState(i,1) = 0
            if bBWMultiballActive And BWJackpotShots(i) > 0 Then
                ModeLightState(i,1) = green
                ModeLightState(i,2) = 0
                ModeLightState(i,0) = 2
            'TODO Jackpot light states for other multiball modes
            End If
        Next

        If HouseBattle1 > 0 Then MyBattleState(HouseBattle1).SetBattleLights
        If HouseBattle2 > 0 Then MyBattleState(HouseBattle2).SetBattleLights
        SetUPFLights
    End Sub


    Public Sub SetBWJackpots
        Dim i
        BWJackpotLevel = 1
        BlackwaterScore = 0
        BWState = 1
        SetUPFState True
        For i = 1 to 7
            If i <> Baratheon and i <> Tyrell Then BWJackpotShots(i) = 1
        Next
        SetModeLights
    End Sub

    'From 1-5 WF, ~100,000 per WF. From 5-25, ~50K per WF, 25-45 ~45K per WF, 45-55, 30K per, and 55+, 10k per. Max is 3M
    Public Sub AddWildfire(wf)
        Dim i,j,k
        k = 1000
        If BWJackpotValue >= 3000000 Then CurrentWildfire = CurrentWildfire + wf: Exit Sub
        For i = 1 to wf
            CurrentWildfire = CurrentWildfire + 1
            If CurrentWildfire < 5 Then
                j=9500
            Elseif CurrentWildfire < 25 Then
                j = 4500
            ElseIf CurrentWildfire < 45 Then
                j = 4000
            ElseIf CurrentWildfire < 55 Then
                j = 2500
            Else
                j = 750:k=500
            End If
            BWJackpotValue = BWJackpotValue + 10*int(j+RndNbr(k))
            If BWJackpotValue > 3000000 Then BWJackpotValue = 3000000
        Next
    End Sub

    Public Sub IncreaseBWJackpotLevel
        Dim i
        BWState = BWState + 1
        BWJackpotLevel = BWJackpotLevel + 1
        For i = 1 to 7
            If i <> Baratheon and i <> Tyrell Then BWJackpotShots(i) = BWJackpotLevel
        Next
        UpdateBWMBScene
        SetModeLights
    End Sub

    Public Sub UpdateBWMBScene
        If ScoreScene.Name <> "bwmb" Then Exit Sub
        FlexDMD.LockRenderThread
        If (BWState MOD 2) = 1 Then
            ScoreScene.GetLabel("obj").Text = "SHOOT GREEN JACKPOTS"
            ScoreScene.GetLabel("Score").SetAlignedPosition 127,0,FlexDMD_Align_TopRight
            ScoreScene.GetLabel("tmr1").Visible = 0
        Else
            ScoreScene.GetLabel("obj").Text = "SHOOT BATTERING RAM"
            ScoreScene.GetLabel("Score").SetAlignedPosition 102,0,FlexDMD_Align_TopRight
            ScoreScene.GetLabel("tmr1").Visible = 1
        End If
        If BWState > 1 Then ScoreScene.GetLabel("line1").Text = "BLACKWATER"&vbLf&"PHASE 2"
        FlexDMD.UnlockRenderThread
    End Sub

    ' m = UPF multiplier. 0 if not a UPF shot
    Public Sub ScoreSJP(m)
        DMDBlackwaterSJPScene FormatScore((BWJackpotValue*BWJackpotLevel*6 + 10000000)*(PlayfieldMultiplierVal+m))
        Score(CurrentPlayer) = Score(CurrentPlayer) + ((BWJackpotValue*BWJackpotLevel*6+10000000)*(PlayfieldMultiplierVal+m))
        BlackwaterScore = BlackwaterScore + ((BWJackpotValue*BWJackpotLevel*6+10000000)*(PlayfieldMultiplierVal+m))
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
        Dim i,t
        Dim delay
        Dim combo:combo=1
        Dim combotext: combotext=""
        Dim qsound:qsound = "gotfx-qualify-sword-hit1"

        If PlayerMode = 2 Then ' In WiC HurryUp Mode
            If h <> CurrentWiCShot Then Exit Sub
            ' This was the HurryUp Shot - Finish WiC HurryUp mode
            StopHurryUp
            PlayerMode = 0
            AddScore HurryUpValue*CurrentWiCShotCombo
            WiCTotal = WiCTotal + HurryUpValue*CurrentWiCShotCombo
            WiCMask = WiCMask Or 2^h
            WiCs = WiCs + 1
            SetLightColor HouseShield(h),HouseColor(SelectedHouse),1
            If WiCs = 4 Then
                ' TODO: Start Winter Has Come Multiball
                WiCMask = 255
            End If
            DMDPlayHitScene "got-wiccomplete","gotfx-wiccomplete",0,"WINTER IS COMING",FormatScore(HurryUpValue*CurrentWiCShotCombo*PlayfieldMultiplierVal),"",CurrentWiCShotCombo,7
            Exit Sub
        End if

        If bBWMultiballActive And (BWState MOD 2) <> 0 Then
            'Handle Jackpot hits for BW Multiball
            If BWJackpotShots(h) > 0 Then
                BWJackpotShots(h) = BWJackpotShots(h) - 1
                i = ComboLaneMap(h)
                combo = ComboMultiplier(i)
                AddScore(BWJackpotValue*combo*BWJackpotLevel)
                BlackwaterScore = BlackwaterScore + (BWJackpotValue*combo*BWJackpotLevel*PlayfieldMultiplierVal)
                DMDPlayHitScene "got-bwexplosion"&i-1,"gotfx-bwexplosion",BWExplosionTimes(i-1), _
                                BWJackpotLevel&"X BLACKWATER JACKPOT",BWJackpotValue*combo*BWJackpotLevel,"",combo,3
                LightEffect 3
                GiEffect 3
                i = RndNbr(3)
                If i < 3 Then
                    PlaySoundVol "say-jackpot",VolDef
                Else
                    'TODO: Say atta-boy
                End If
                SetModeLights   ' Update shield light colors

                'Check to see if all jackpot shots have been made the required number of times
                t = True
                For i = 1 to 7
                    If BWJackpotShots(i) > 0 Then t=False:Exit For
                Next
                If t Then
                    BWState = BWState + 1
                    SetGameTimer tmrBlackwaterSJP,200
                    bBlackwaterSJPMode = True
                    SetBatteringRamLights
                    UpdateBWMBScene
                End If
            End If
        End If

        If bSwordLit And h = Stark Then DoAwardSword

        if PlayerMode = 0 And bMultiBallMode = False Then
            Dim cbtimer: cbtimer=1000
            Dim fmt
            
            if QualifyCount(h) < 3 Then
                QualifyCount(h) = QualifyCount(h) + 1
                If h <> Baratheon and h <> Tyrell Then AddBonus 100000

                If ComboLaneMap(h) Then combo = ComboMultiplier(ComboLaneMap(h))

                line0 = "HOUSE " & HouseToUCString(h)
                if QualifyCount(h) = 3 Then
                    bQualified(h) = True
                    BattleReady = True
                    ResetLights
                    line2 = "HOUSE IS LIT"
                Else
                    line2 = (3 - QualifyCount(h)) & " MORE TO LIGHT"
                End If
                line1 = FormatScore(QualifyValue*combo*PlayfieldMultiplierVal)

                AddScore(QualifyValue*combo)

                ' Play the animation and sound(s)
                delay = QAnimateTimes(h*3+QualifyCount(h))
                If h = Martell or (h = Stark and QualifyCount(h) < 3) Then
                    vpmtimer.addtimer delay*1000, "PlaySoundVol """&qsound&""","&VolDef&" '"
                    qsound = "gotfx-"&HouseToString(h)&"qualify"&QualifyCount(h)
                End If
                if h = Targaryen then fmt = 6 else fmt = 0
                DMDPlayHitScene "got-"&HouseToString(h)&"qualify"&QualifyCount(h),qsound,delay,line0,line1,line2,combo,fmt

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
            ElseIf (WiCMask And 2^h) = 0 Then
                combo = ComboMultiplier(ComboLaneMap(h))
                If combo = 0 then combo = 1
                AddScore 50000*combo
                AddBonus 25000
                'WiCMask = WiCMask Or 2^h
                If WiCValue = 0 Then
                    If HouseSelected = Stark Then WiCValue = 14075000 Else WiCValue = 4075000
                Else
                    WiCValue = WiCValue + RndNbr(700)*1000 + 300000 ' TODO Better way of calculating next WiC Value
                End If
                WiCShots = WiCShots + 1
                If WiCShots = 3 Then
                    CurrentWiCShot = h
                    CurrentWiCShotCombo = combo
                    StartWICHurryUp WiCValue,h
                    WiCShots = 0
                    'Start WiC HurryUp : Exit Sub
                    ' Make sure that LockBall still gets handled - multiball can be stacked with a WiC HurryUp
                Else
                    DMDDoWiCScene WiCValue,WiCShots
                    cbtimer = cbtimer + 1000
                End If
            End If

            if bBattleReady and h = Lannister Then    ' Kick off House Battle selection
                PlayerMode = -2
                FreezeAllGameTimers
                If BallsInLock < 2 And bLockIsLit Then ' Multiball not about to start, lock the ball first
                    vpmtimer.addtimer 400, "LockBall '"     ' Slight delay to give ball time to settle
                    cbtimer = cbtimer + 400
                End If
                vpmtimer.addtimer cbtimer, "StartChooseBattle '"
            End If
        ElseIf PlayerMode = 1 Then
            If HouseBattle1 > 0 Then MyBattleState(HouseBattle1).RegisterHit(h)
            If HouseBattle2 > 0 Then MyBattleState(HouseBattle2).RegisterHit(h)
            ' TODO: Add support for other modes (HOTK, IT)
        End If

        If h = Targaryen And Not bMultiBallMode Then AdvanceWallMultiball 1
        
        IncreaseComboMultiplier(h)
    End Sub

    Public Sub GoldHit(n)
        Dim i,j
        AddScore 30
        If PlayerMode = 1 And (HouseBattle1 = Lannister Or HouseBattle2 = Lannister) Then
            If HouseBattle1 = Lannister Then
                MyBattleState(HouseBattle1).RegisterGoldHit n
            Else
                MyBattleState(HouseBattle2).RegisterGoldHit n
            End If
        Else
            ' Any mode except Lannister Battle mode
            If Not bGoldTargets(n) Then
                PlaySoundVol "gotfx-goldcoin",VolDef
                If HouseSelected = Lannister Then AddGold 100 Else AddGold 15
                bGoldTargets(n) = True
                SetLightColor GoldTargetLights(n),yellow,1
                j = True
                For i = 0 to 4 
                    If bGoldTargets(i) = False Then j=False
                Next
                If j Then
                    ' Target bank completed. Light mystery, turn off target lights 
                    ' Probably need to play a sound here
                    If HouseSelected = Lannister Then AddGold 500 Else AddGold 250
                    For i = 0 to 4: bGoldTargets(i) = False: Next
                    bMysteryLit = True : SetMystery
                    ' tell the gold target lights to turn off in 1 second. There's a timer on the first light
                    GoldTargetLights(0).TimerInterval = 1000: GoldTargetLights(0).TimerEnabled = True
                End If
            Else
                ' Already lit
                If HouseSelected = Lannister Then AddGold 15 Else AddGold 5
                PlaySoundVol "gotfx-litgold",VolDef/4
            End If
        End If
    End Sub

    Sub HouseCompleted(h)
        bQualified(h) = False
        If bCompleted(h) = False Then
            bCompleted(h) = True
            CompletedHouses = CompletedHouses + 1
            If CompletedHouses = 3 Then DoEBisLit
            If h = Lannister Then
                If MyHouse = Lannister Then AddGold 400 Else AddGold 250
            End If
            If MyHouse = Greyjoy Then ActionAbility = h : ActionButtonUsed = False
        End If
        ' TODO Add support for Greyjoy gaining other houses' abilities
    End Sub

    '***************************
    ' Upper Playfield Processing
    '***************************

    ' UPF lights
    ' 1 - li186 - Castle
    ' 2 - li189 - Left target
    ' 3 - li180 - Left outlane
    ' 4 - li192 - Center target
    ' 5 - li183 - Right outlane
    ' 6 - li195 - Right target
    ' 7 - li198 - shield
    ' 11 - li201 - Castle MB
    ' 10 - li204 - Breach
    ' 9 - li207 - Charge
    ' 8 - li210 - Arrows
    ' 12 - li213 - 2X
    ' 13 - li216 - 3X
    
    Public Sub SetUPFLights
        Dim clr,i
        If UPFState = 2 Then 'Blackwater MB
            clr = green
        ElseIf UPFState = 1 Then
            clr = HouseColor(HouseBattle1)
        Else clr = cyan
        End If
        For i = 1 to 13 : UPFLights(i).State = 0 : UPFLights(i).BlinkInterval = 100 : Next
        SetLightColor UPFLights(1),amber,1  ' Castle is lit amber unless it's not

        ' top lights
        If UPFState <> 1 Or HouseBattle2 = 0 Then ' normal single flashing colour
            For i = 1 to 8
                If (UPFShotMask And 2^(i-1)) > 0 Then SetLightColor UPFLights(i),clr,2
            Next
            For i = 8 to 10 : HouseShield(i).TimerEnabled = False : Next
        Else ' Stacked battle mode, use timers to cycle through colours
            For i = 8 to 10
                If (i=8 and (UPFShotMask And 2) > 0) Or (i=9 And (UPFShotMask And 8) > 0 ) Or (i=10 And (UPFShotMask And 32) > 0) Then
                    ModeLightState(i,0) = 3
                    ModeLightState(i,1) = 0
                    ModeLightState(i,2) = clr
                    ModeLightState(i,3) = HouseColor(HouseBattle2)
                    HouseShield(i).TimerInterval = 100
                    HouseShield(i).TimerEnabled = True
                Else
                    HouseShield(i).TimerEnabled = False
                End If
            Next
        End If

        ' Shield
        If UPFState > 0 Then SetLightColor li198,clr,2
        ' Levels
        If UPFState = 0 Then
            For i = 1 to 4
                If UPFLevel = i Then 
                    SetLightColor UPFLights(i+7),clr,2
                ElseIf UPFLevel > i Then
                    SetLightColor UPFLights(i+7),clr,1
                End If
            Next
        End If
        
        ' UPF playfield mult
        If UPFMultiplier = 2 Then 
            SetLightColor li213,amber,2
        ElseIf UPFMultiplier = 3 Then
            SetLightColor li213,amber,1
            SetLightColor li216,amber,2
        End If
    End Sub

    ' Set up the UpperPF state.
    ' If reset=true, reset to initial state for the mode its entering
    Public Sub SetUPFState(reset)
        Dim i
        If bBWMultiballActive Then
            UPFState = 2 : UPFShotMask = 42
            SetUPFFlashers 2,green
        ElseIf PlayerMode = 1 Or PlayerMode = -2.1 Then
            UPFState = 1 : UPFShotMask = 42
            SetUPFFlashers 1,amber
        Else ' PlayerMode 0
            UPFState = 0
            SetUPFFlashers 1,amber
            If reset then UPFShotMask = 42 Else UPFShotMask = UPFCastleShotMask
        End If
    End Sub

    Public Sub ResetUPFMultiplier : UPFMultiplier = 1 : li213.State=0 : li216.State=0 : End Sub


    ' Process a hit on a UPF switch. Numbering:
    '  1 - Castle loop
    '  2 - left target
    '  3 - left outlane
    '  4 - center target
    '  5 - right outlane
    '  6 - right target
    '  7 - left inlane
    '  8 - right inlane
    Public Sub RegisterUPFHit(sw)
        Dim i
        If PlayerMode = 2 Then Exit Sub     ' No UPF progress during WiC HurryUp
        i = RndNbr(10)
        PlaySoundVol "gotfx-upfhit"&i,VolDef
        i = RndNbr(3)
        debug.print "register UPF hit. Sw: "&sw&" State: "&UPFState&" UPFShotMask: "&UPFShotMask
        Select Case sw
            Case 1 ' Castle loop shot
                'TODO need sound effect for Castle loop shot
                If UPFMultiplier < 3 Then ' Increase UPF multiplier
                    UPFMultiplier = UPFMultiplier + 1
                    SetGameTimer tmrUPFMultiplier,300
                    SetUPFLights
                End If
                If (UPFShotMask And 1) > 0 Then     ' Castle was lit
                    Select Case UPFState
                        Case 0: IncreaseUPFLevel : UPFShotMask = 42 : UPFCastleShotMask = 42 : PlaySoundVol "gotfx-wildfiremini2",VolDef
                        Case 1 ' Battlemode hit
                            UPFShotMask = 42
                            ' Award a castle for each battle mode that's active
                            ' 1st castle is 25M, 2nd is 50M, etc plus 7.5M Bonus per
                            ' If 2 castles are scored at once, only second is displayed
                        Case 2 ' BWMB state - does nothing?
                    End Select
                    SetUPFLights
                ElseIf UPFState = 1 Then
                    ' Castle wasn't lit but we're in battle mode
                    House(CurrentPlayer).BattleState(HouseBattle1).RegisterCastleHit
                    If HouseBattle2 > 0 Then House(CurrentPlayer).BattleState(HouseBattle2).RegisterCastleHit
                End If
            Case 2,4,6  ' Standup target
                If (UPFShotMask And (2^(sw-1))) > 0 Then ' Target was lit
                    Select Case UPFState
                        Case 0 ' Castle MB mode
                            PlaySoundVol "gotfx-dragonroar"&i,VolDef
                            PlaySoundVol "gotfx-elevatorupf",VolDef
                            AddBonus 50000
                            UPFShotMask = UPFShotMask Xor (2^(sw-1))
                            If (UPFShotMask And 254) = 0 Then
                                UPFShotMask = UPFShotMask Or 20 ' Light outlanes
                                PlaySoundVol "gotfx-upfdone",VolDef
                                DMDPlayHitScene "got-upfbackground","",0,"CASTLE AWARD",3000000*UPFMultiplier,"",UPFMultiplier,5
                            Else
                                AddScore 250000*UPFMultiplier
                            End If
                            UPFCastleShotMask = UPFShotMask
                        Case 1 ' Battle mode
                            House(CurrentPlayer).BattleState(HouseBattle1).AddTime 5
                            If HouseBattle2 > 0 Then House(CurrentPlayer).BattleState(HouseBattle2).AddTime 5
                            ' In Battle mode, hit sequence goes:
                            '  - hit any target to light two outer targets
                            '  - hit either outside target to light center target
                            '  - hit center target to light Castle
                            Select Case UPFShotMask
                                Case 42: UPFShotMask = 34 ' light outside targets
                                Case 34: UPFSHotMask = 8  ' light center target
                                Case 8: UPFShotMask = 1   ' light Castle loop
                            End Select
                        Case 2 ' BW Multiball mode
                            If UPFSJP Then
                                Dim jpscore
                                UPFSJP = False
                                UPFShotMask = 42
                                If UPFMultiplier > 1 Then ScoreSJP UPFMultiplier Else ScoreSJP 0
                            Else
                                UPFShotMask = UPFShotMask Xor (2^(sw-1))
                                If UPFMultiplier = 1 Then
                                    jpscore = BWJackpotValue*BWJackpotLevel*PlayfieldMultiplierVal
                                Else
                                    jpscore = BWJackpotValue*BWJackpotLevel*(PlayfieldMultiplierVal+UPFM)
                                End If
                                ' Do Jackpot scene
                                Score(CurrentPlayer) = Score(CurrentPlayer) + jpscore
                                BlackwaterScore = BlackwaterScore + jpscore
                                DMDPlayHitScene "got-bwexplosion5","gotfx-bwexplosion",BWExplosionTimes(5), _
                                        BWJackpotLevel&"X BLACKWATER JACKPOT",BWJackpotValue*UPFMultiplier*BWJackpotLevel,"",UPFMultiplier,3
                                LightEffect 3
                                If UPFShotMask = 0 Then UPFShotMask = 8 : UPFSJP = True
                            End If
                    End Select
                    SetUPFLights
                Else
                    ' Not lit. Just give a few points
                    AddScore 560*UPFMultiplier
                End If
            Case 3,5    ' Outlanes
                If (UPFShotMask And (2^(sw-1))) > 0 Then  ' outlane was lit
                    Select Case UPFState
                        Case 0: IncreaseUPFLevel : UPFShotMask = (UPFShotMask And 1) Or 42 : UPFCastleShotMask = UPFShotMask ' Castle MB mode
                        Case 1 ' Battle mode - are these used at all?
                            AddScore 560*UPFMultiplier
                            ' TODO: If the Castle doesn't finish the mode, then outlane shots do advance the mode. 
                        Case 2 ' BWMB mode - are these used?
                            AddScore 560*UPFMultiplier
                    End Select
                    SetUPFLights
                End If
            Case 7: AddScore 560*UPFMultiplier : PlaySoundVol "gotfx-ramphit1",VolDef/4 ' Left inlane
            Case 8      ' Right Inlane
                PlaySoundVol "gotfx-ramphit1",VolDef/4
                AddScore 560*UPFMultiplier
                If bCastleShotAvailable Then
                    UPFShotMask = UPFShotMask Or 1
                    bCastleShotAvailable = False
                    SetUPFLights
                End If
        End Select

    End Sub

    ' Advance the UPF level, either thru Castle hit or outlane
    ' Play the animation, add points. If it's the 4th hit, start Castle Multiball
    Public Sub IncreaseUPFLevel
        Dim delay,line1,line2,score,combo,format,i
        ' Score a level towards Castle MB
        score = (2500000 + 2500000*UPFLevel)*UPFMultiplier
        AddScore score
        i = RndNbr(3)
        line2 = FormatScore(score)
        format=3:combo=UPFMultiplier
        Select Case UPFLevel
            Case 1: line1 = "ARCHERS!"
            Case 2: line1 = "CHARGE!"
            Case 3: line1 = "BREACH!"
            Case 4: line1 = "CASTLE":line2="MULTIBALL":format=4:combo=0
        End Select
        
        PlaySoundVol "gotfx-dragonroar"&i,VolDef
        PlaySoundVol "gotfx-elevatorupf",VolDef

        If UPFLevel = 4 Then delay = 2.5 Else delay = 1.5
        DMDPlayHitScene "got-castlemblevel"&UPFLevel,"gotfx-castlemblevel"&UPFLevel,delay,line1,line2,"",combo,format
        UPFLevel = UPFLevel + 1
        If UPFLevel = 5 Then 
            'TODO: Castle MULTIBALL!!
        Else
            PlaySoundAt SoundFXDOF("fx_resetdrop", 119, DOFPulse, DOFcontactors), Target90
            Target90.IsDropped=0
        End If
    End Sub

    ' Called when someone hits the Action button
    Sub CheckActionBtn
        Dim scene
        Select Case ActionAbility
            Case Stark
                If PlayerMode <> 1 or ActionButtonUsed Then Exit Sub
                If bUseFlexDMD Then
                    Set scene = NewSceneWithVideo("dwolf","got-direwolf")
                    scene.AddActor FlexDMD.NewLabel("txt",FlexDMD.NewFont("udmd-f6by8",vbWhite,vbWhite,0),HouseToUCString(HouseBattle1)&vbLf&"COMPLETED"&vbLf&"5,000,000")
                    scene.GetLabel("txt").SetAlignedPosition 88,16,FlexDMD_Align_Center
                    DMDEnqueueScene scene,1,1500,2000,3000,"gotfx-direwolf"
                End If
                Me.HouseCompleted HouseBattle1
                BattleState(HouseBattle1).EndBattleMode
                SetLightColor HouseSigil(MyHouse),HouseColor(SelectedHouse),1
                AddScore 5000000
                ActionButtonUsed = True
            Case Baratheon
                If ActionButtonUsed Or bLoLLit Then Exit Sub
                DoLordOfLight
                ActionButtonUsed = True
                'TODO: Start a LoL timer that turns off LoL after 10 seconds
            Case Lannister
                If ActionButtonUsed >= 12 Or PlayfieldMultiplierVal = 5 Or PlayfieldMultiplierVal >= SwordsCollected+3 Then Exit Sub
                If CurrentGold < ((PlayfieldMultiplierVal+1) * 600) Then Exit Sub 'Not enough gold. TODO: Snarky scene?
                PlayfieldMultiplierVal = PlayfieldMultiplierVal + 1
                SetGameTimer tmrPFMultiplier,800-(PlayfieldMultiplierVal*100)
                SetPFMLights
                ActionButtonUsed = ActionButtonUsed + 1
                CurrentGold = CurrentGold - ((PlayfieldMultiplierVal+1) * 600)
                'TODO: Do Playfield Multiplier buy scene
            ' Greyjoy has no Action Button functionality
            Case Tyrell
                If ActionButtonUsed Then Exit Sub
                ' TODO: Do Iron Bank Cash-out
            Case Martell
                If ActionButtonUsed Or Not bMultiBallMode Then Exit Sub
                AddMultiballFast 1
                DMD "","ADD A BALL","",eNone,eNone,eNone,1000,True,""
                EnableBallSaver 7
                ActionButtonUsed = True
            Case Targaryen
                ' TODO: FreezeAllTimers (except Ball Save) for 15 seconds
        End Select
    End Sub

End Class

Dim ModeLightPattern
Dim AryaKills
Dim CompletionAnimationTimes
CompletionAnimationTimes = Array(0,2,2,1.5,4,2.3,6,2)

'Each number is a bit mask of which shields light up for the given mode
ModeLightPattern = Array(0,10,16,0,218,138,80,10)

AryaKills = Array("","","joffrey","cercai","walder frey","tywin","the red woman","beric dondarrion","Thoros of Myr", _
                "meryn trant","the hound", "the mountain","rorge","ilyn payne","polliver")

Class cBattleState
    Dim CompletedShots          ' Total shots accumulated for this battle
    Dim ShotMask           ' bitmask of shots that have been lit up
    Dim LannisterGreyjoyMask    ' bitmask of shots completed
    Dim GreyjoyMask             ' Mask of shots completed
    Dim GoldShotMask            ' Mask of which gold targets are lit during Lannister battle
    Dim CompletedDragons
    Dim MyHouse                 ' The house associated with this BattleState instance
    Dim State                   ' Current state of this house's battle
    Dim bComplete               ' Battle is complete
    Dim TotalScore              ' Total score accumulated battling this house
    Dim HouseValue              ' Most houses build value as the battle progresses. Stored here
    Dim HouseValueIncrement     ' Amount house value builds by, per shot, if machine-generated
    Dim MyHurryUps(3)           ' Holds the index values of any running HurryUps. Only Targaryen has more than one concurrently 
    Dim OtherHouseBattle        ' Store the other house battle, if two are stacked. Used for doing Battle Total at the end
    Dim DrogonHits              ' Track health of Drogon, for Targaryen battle
    Dim TGShotCount

    
    Private Sub Class_Initialize(  )
        CompletedShots = 0
        LannisterGreyjoyMask = 0
        GreyjoyMask = 218
        CompletedDragons = 0
        ShotMask = 0
        GoldShotMask = 31
        State = 1
        bComplete = False
        TotalScore = 0
        HouseValueIncrement = 0
        DrogonHits = 0
    End Sub

    Public Property Let SetHouse(h) 
        MyHouse = h
        Select Case h
            Case Lannister: HouseValue = 1000000
            Case Greyjoy: HouseValue = 600000 + RndNbr(4)*25000
            Case Tyrell: HouseValue = 9000000 + RndNbr(7)*125000
            Case Targaryen: HouseValue = 8000000
        End Select
    End Property
	Public Property Get GetHouse : GetHouse = MyHouse : End Property
    Public Property Let OtherHouse(h) : OtherHouseBattle = h : End Property

    Public Sub SetBattleLights
        Dim mask,i
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
            Case Lannister,Targaryen
                mask = ShotMask
            Case Greyjoy
                mask = GreyjoyMask
            Case Tyrell
                Select Case State
                    Case 2,4,6: mask = 32
                    Case 3: mask = 10
                    Case 5: mask = 2
                End Select
            Case Martell
                If State = 2 Then mask = 10
        End Select

        debug.print "House:"&MyHouse&" State:"&State&" Mask:"&mask
        For i = 1 to 7
            If (mask And 2^i) > 0 Then 
                ModeLightState(i,0) = ModeLightState(i,0) + 1
                ModeLightState(i,(ModeLightState(i,0))) = HouseColor(MyHouse) 
            End If
        Next

        If MyHouse = Lannister Then
            For i = 0 to 4
                If (GoldShotMask And 2^i) > 0 Then
                    GoldTargetLights(i).State = 2
                    GoldTargetLights(i).BlinkInterval = 30
                Else
                    GoldTargetLights(i).State = 0
                End If
            Next
        ElseIf MyHouse = HouseBattle1 And HouseBattle2 <> Lannister Then SetGoldTargetLights
        End If
    End Sub

    ' Called to initialize battle mode for this house. Only certain houses need setup done
    Public Sub StartBattleMode
        Dim tmr: tmr=400    ' 10ths of a second
        Dim i,j
        OtherHouseBattle = 0
        Select Case MyHouse
            Case Stark
                State = 1
                HouseValue = 500000
                ' TODO Stark shot increase value may depend on how quickly you make the shots
                If HouseValueIncrement = 0 Then HouseValueIncrement = 3000000 + RndNbr(15) * 125000 
                If CompletedShots > 0 Then CompletedShots = 2
            Case Baratheon: State = 1 : OpenTopGates : HouseValue = 1250000 : HouseValueIncrement = 900000 : ResetDropTargets
            Case Lannister: State=1
            Case Greyjoy: OpenTopGates : tmr = 150
            Case Martell: HouseValue = 0: tmr = 300 : State = 1 : CompletedShots = 0 : OpenTopGates
            Case Targaryen
                tmr = 0
                bTargaryenInProgress = True
                Select Case State
                    Case 1: ShotMask = 10
                    Case 7
                        ResetDropTargets
                        ' Generate 3 randomly lit shots
                        If TGShotCount = 0 Then
                            ShotMask = 0
                            For i = 1 to 3
                                Do
                                    j = RndNbr(6)
                                Loop While (ShotMask And 2^j) > 0
                                ShotMask = ShotMask Or 2^j
                            Next
                        End If
                End Select
        End Select
        If tmr > 0 Then 
            If MyHouse = HouseBattle2 Then SetGameTimer tmrBattleMode2,tmr Else SetGameTimer tmrBattleMode1,tmr
        End If

    ' TODO: Are there any other lights/sounds associated with starting battle for a specific house?
    End Sub

    ' Update the state machine based on the ball hitting a target
    Public Sub RegisterHit(h)
        Dim hit,done,hitscene,hitsound,ScoredValue,i
        ScoredValue = 0
        ThawAllGameTimers
        if bComplete Then Exit Sub
        hitscene="":hitsound=""
        Select Case MyHouse
            ' Stark Battle mode. State 1 is shooting the left ramp. Once 3 shots have been made, switch to State 2
            ' In State 2, left ramp shots can continue to be made, and an orbit shot finishes the mode
            Case Stark
                If h = Lannister or h = Stark Then
                    ' Process ramp shot
                    HouseValue = HouseValue + HouseValueIncrement
                    If HouseValue > 75000000 Then HouseValue = 75000000
                    HouseValueIncrement = HouseValueIncrement + 750000
                    CompletedShots = CompletedShots + 1
                    If CompletedShots = 3 Then
                        State = 2
                        SetModeLights
                    End If
                    PlaySoundVol "gotfx-ramphit",VolDef/4
                    debug.print "Stark hits: "&CompletedShots
                    If CompletedShots >= 3 Then
                        'TODO: On the real table, if you restart the mode, it doesn't reuse the same victims. It also randomizes the order
                        ' Show Arya's kill list scene. 
                        ' Photos alternate between right and left side of scene so adjust text alignment
                        Dim just1, just2
                        just1 = FlexDMD_Align_TopRight:just2 = FlexDMD_Align_BottomLeft
                        Select Case CompletedShots
                            Case 5,6,8,10,12,13,14: just1=FlexDMD_Align_TopLeft:just2 = FlexDMD_Align_BottomRight
                        End Select
                        ' Render battle hit scene. 'House,Scene #, Score, Text1, Text2, Score+Text1 text justification, text2 justification,sound
                        DMDStarkBattleScene Stark,CompletedShots-2,HouseValue,"STARK VALUE GROWS",AryaKills(CompletedShots),just1,just2,"say-aryakill"&CompletedShots-2
                    End If
                    UpdateBattleScene
                ElseIf State = 2 And (h = Greyjoy or h = Martell) Then
                    DoCompleteMode h
                End if

            ' Baratheon Battle mode. State 1 only involves the spinner. Once enough value is built, switch to State 2
            ' State 2: Shot to the Dragon, followed by a shot to the left bank.
            Case Baratheon
                If State = 2 Then
                    If (ShotMask And 2^h) > 0 Then
                        ShotMask = ShotMask And (2^h Xor 255)
                        hitscene = "hit2"
                        HouseValue = HouseValue + 750000
                        If ShotMask = 0 Then
                            State = 3
                            ResetDropTargets
                            SetModeLights
                        End If
                    End If
                End If

            ' Lannister battle mode. Only 1 state. Shoot gold targets to light ramps on either side, then shoot
            ' ramps. Accumulate 5 shots total. Progress is saved. Each gold target can only be hit once, but there is
            ' some overlap in shots that they light, so some shots can be made twice to avoid harder shots. Greyjoy must
            ' shoot all 5 unique shots
            Case Lannister
                If (ShotMask And 2^h) > 0 Then
                    ShotMask = ShotMask And (2^h Xor 255)
                    LannisterGreyjoyMask = LannisterGreyjoyMask Or 2^h
                    CompletedShots = CompletedShots + 1
                    If (SelectedHouse = GreyJoy And LannisterGreyjoyMask = 218) or (SelectedHouse <> Greyjoy And CompletedShots >= 5) Then
                        DoCompleteMode h
                    Else
                        hitscene = "hit"&(CompletedShots+1) 'hit1 is for gold target hit
                        SetModeLights
                        ScoredValue = HouseValue
                        ' TODO: Figure out if there's a better pattern to capture Lannister mode value increases
                        HouseValue = HouseValue + (CompletedShots * 200000)+RndNbr(12)*25000
                    End If
                End If
            
            ' Greyjoy battle mode. Only 1 state: Shoot the 5 main shots. 15 second timer, but the timer resets after
            ' each shot
            Case Greyjoy
                If (GreyjoyMask And 2^h) > 0 Then
                    ' Completed shot
                    CompletedShots = CompletedShots+1
                    GreyjoyMask = GreyjoyMask And (2^h Xor 255)
                    If GreyjoyMask = 0 Then 'Completed req'd shots!
                        DoCompleteMode h
                    Else
                        hitscene = "hit"&CompletedShots
                        hitsound = "hit1"
                        ScoredValue = HouseValue
                        Select Case CompletedShots
                            Case 1,3: HouseValue = HouseValue + 2250000 + RndNbr(8)*25000
                            Case 2: HouseValue = HouseValue + 1500000 + RndNbr(12)*15000
                            Case 4: HouseValue = HouseValue + 5000000 + RndNbr(12)*250000
                        End Select
                        SetModeLights
                        ' Reset mode timer
                        If MyHouse = HouseBattle2 Then SetGameTimer tmrBattleMode2,150 Else SetGameTimer tmrBattleMode1,150
                    End If
                End If

            ' Tyrell battle mode. 6 States. States 1/3/5 involve choice of 3/2/1 main shot(s), States 2/4/6 require a right-bank target shot
            Case Tyrell
                hit=False
                Select Case State
                    Case 1
                        If h = Targaryen or h = Stark or h = Lannister Then hit = true
                    Case 2,4,6
                        If h = Tyrell Then 
                            hit = true
                            ' Target hit. Add 5 seconds to the mode timer
                            If MyHouse = HouseBattle2 Then 
                                TimerTimestamp(tmrBattleMode2) = TimerTimestamp(tmrBattleMode2)+50 
                            Else 
                                TimerTimestamp(tmrBattleMode1) = TimerTimestamp(tmrBattleMode1)+50 
                            End If
                        End if
                    Case 3
                        If h = Stark or h = Lannister Then hit = true
                    Case 5
                        If h = Stark then hit = true
                End Select
                If hit Then
                    State = State + 1
                    If (State MOD 2) = 0 Then 
                        ' Reset Wildfire targets
                        bWildfireTargets(0) = False: bWildfireTargets(1) = False
                        li80.BlinkInterval = 50
                        li83.BlinkInterval = 50
                        li80.State = 2
                        li83.State = 2
                    End If        
                    If State = 7 Then
                        DoCompleteMode 0
                    Else
                        hitscene = "hit"& (State MOD 2) + 1
                        ScoredValue = HouseValue
                        HouseValue = HouseValue + 900000 + (325000*(State-1))
                        If HouseValue > 18000000 Then HouseValue = 18000000
                        SetModeLights
                    End If
                End If

            ' Martell battle mode: State 1 requires 3 orbit shots within a 10 second period. After this, mode is
            ' complete, but State 2 is started, which is a HurryUp at the ramps. Shoot the ramps for bonus. If
            ' you miss the HurryUp, mode still completes
            Case Martell
                Dim huvalue
                If State = 1 And (h = Greyjoy or h = Martell) Then
                    CompletedShots = CompletedShots + 1
                    debug.print "Martell Compl shots: " & CompletedShots & " LastSwHit: " &LastSwitchHit
                    hitscene = "hit"&CompletedShots
                    If CompletedShots = 3 Then 'State 1 complete
                        HouseValue = HouseValue + 9000000 + RndNbr(7)*125000
                        ScoredValue = HouseValue
                        TimerFlags(tmrMartellBattle) = 0
                        State = 2
                        UpdateBattleScene
                        StartHurryUp ScoredValue,MyBattleScene,0
                        HouseValue = 0
                        SetModeLights
                    Else
                        If HouseValue = 0 Then HouseValue = 19250000 Else HouseValue = HouseValue + 500000 + RndNbr(25)*125000:
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
                    huvalue = HurryUpValue
                    StopHurryUp
                    If huvalue > 0 Then
                        'Hurry-up hit in time
                        HouseValue = huvalue
                        DoCompleteMode h
                    End if
                    
                End If

            ' Targaryen: 3 LEVELS, each with 3 states except last which has 2 that repeat 4 times - 8 states total
            ' All shots involve HurryUps. Mode ends if HurryUp runs down
                ' Level 1 Start: light 2 ramps for HurryUp. 8M
                ' State 1: Shoot 1 of the lit ramps to advance to State 2
                ' State 2: Light 2 loops. Shoot one to advance to dragon. 10M
                ' State 3: Start hurry-up on Dragon. 12M
                ' Level 2: Repeat Level 1, but require all 4 shots in State 1 & 2
                ' Level 3: Light 3 random shots as hurry-ups (mode ends if hurry-ups timeout?)
                ' State 1: Shoot all 3 hurry-ups. Shooting Dragon spots a hurry-up.
                ' State 2: Shoot Dragon hurry-up
                ' States 1 & 2 repeat until Drogon health is used up - 15 shots total, then clear the current Wave (State 1 & 2) to end the mode
                ' Timer on Level 3: If you take too long, you are attacked with “DRAGON FIRE”, and wave restarts with new randomly chosen shots (State 1, but same Wave)
                ' TODO: Greyjoy players have a Hurry-Up to hit any target to start State 1 on each Level
            Case Targaryen
                hit = False:done=False
                Select Case State
                    Case 1
                        If h = Stark or h = Lannister or h = Targaryen Then hit=true:done=True:ShotMask = 80
                    Case 2
                        If h = Greyjoy or h = Martell or h = Targaryen Then hit=true:done=True:ShotMask = 128
                    Case 3,6
                        If h = Targaryen Then
                            hit=true:done=true
                            ShotMask = 10
                        End If
                    Case 4
                        If h = Stark or h = Lannister Then
                            hit=true
                            ShotMask = ShotMask And (2^h Xor 255)
                            If ShotMask = 0 Then done=true:ShotMask=80
                        End If
                        If h = Targaryen Then
                            hit = true
                            If ShotMask = 8 or Shotmask = 2 Then done = true:ShotMask=80 Else ShotMask = 8
                        End If
                    Case 5
                        If (ShotMask And 2^h) > 0 Then
                            hit=true
                            ShotMask = ShotMask And (2^h Xor 255)
                            If ShotMask = 0 Then done=true:ShotMask=128
                        ElseIf h = Targaryen Then
                            hit = true
                            If ShotMask = 16 or Shotmask = 64 Then done = true:ShotMask=128 Else ShotMask = 16
                        End If
                    Case 7
                        If (ShotMask And 2^h) > 0 Then
                            hit=true
                            ShotMask = ShotMask And (2^h Xor 255)
                            TGShotCount = TGShotCount + 1
                            DrogonHits = DrogonHits + 1
                            If ShotMask = 0 Then done=true:ShotMask=128
                        ElseIf h = Targaryen Then
                            hit = true
                            For i = 1 to 6
                                If (ShotMask And 2^i) > 0 Then
                                    ShotMask = ShotMask And (2^i Xor 255)
                                    Exit For
                                End If
                            Next
                            TGShotCount = TGShotCount + 1
                            DrogonHits = DrogonHits + 1
                            If ShotMask = 0 Then done=true:ShotMask=128
                        End If
                    Case 8
                        If h = Targaryen Then
                            hit=true:done=true
                            DrogonHits = DrogonHits + 1
                        End If
                End Select
                If hit Then
                    ScoredValue = TGHurryUpValue
                    StopTGHurryUp
                    If State < 4 Then
                        hitscene = "hit1"
                    ElseIf State < 7 Then
                        hitscene = "hit2"
                        hitsound = "hit1"
                    ElseIf State = 7 Then
                        hitscene = "hit" & 3 + TGShotCount MOD 3
                        hitsound = "hit3"
                    Else
                        hitscene = "hit6"
                        hitsound = "hit3"
                    End if
                    If (State=4 Or State=5 Or State=7) And Not done then TGStartHurryUp 
                    If Not done then SetModeLights
                End If
                If done Then
                    State = State + 1
                    Select Case State
                        Case 4,7: EndBattleMode
                        Case 9
                            If DrogonHits < 15 Then 
                                TGShotCount = 0 : State = 7 : TGStartHurryUp 
                            Else 
                                DoCompleteMode Targaryen
                            End if
                        Case Else: TGStartHurryUp
                    End Select
                    SetModeLights
                End If  

        End Select

        If hitscene <> "" Then
            Dim line2,line3,name,sound,combo
            AddBonus 100000
            line3 = "JACKPOT BUILDS"
            combo = 0
            'Play a scene and add score
            If ScoredValue <> 0 Then
                line3 = "AWARDED"
                combo = ComboMultiplier(ComboLaneMap(h))
                line2 = FormatScore(ScoredValue*combo*PlayfieldMultiplierVal)
                AddScore ScoredValue*combo
                TotalScore = TotalScore + (ScoredValue*combo*PlayfieldMultiplierVal)
            Else
                line2 = FormatScore(HouseValue)
            End If
            name = "got-"&HouseToString(MyHouse)&"battle"&hitscene
            if hitsound <> "" Then 
                sound = "gotfx-"&HouseToString(MyHouse)&"battle"&hitsound 
            Else 
                sound = "gotfx-"&HouseToString(MyHouse)&"battle"&hitscene
            End if
            If MyHouse = Targaryen Then
                DMDPlayHitScene name,sound,1.5,"HOUSE TARGARYEN",line2,"",combo,3
            Else
                DMDPlayHitScene name,sound,1.5,BattleObjectivesShort(MyHouse),line2,line3,combo,1
            End If
            UpdateBattleScene
        End If

    End Sub

    ' Finish the mode. 'Shot' is the shot # that completed the mode, in case a combo multiplier is involved
    Public Sub DoCompleteMode(shot)
        Dim comboval,line2,name,sound,delay

        If MyHouse = Targaryen Then bTargaryenInProgress = False
        bComplete = True
        House(CurrentPlayer).HouseCompleted MyHouse

        EndBattleMode

        SetLightColor HouseSigil(MyHouse),HouseColor(SelectedHouse),1

        If shot > 0 And MyHouse <> Baratheon And shot <> Tyrell Then
            comboval = ComboMultiplier(ComboLaneMap(shot)) * PlayfieldMultiplierVal
        Else
            comboval = PlayfieldMultiplierVal
        End If
        TotalScore = TotalScore + HouseValue * comboval
        
        AddScore HouseValue * comboval
        line2 = FormatScore(HouseValue * comboval)
        If comboval = 1 Then comboval = 0  ' Don't bother printing Combo value for final shot if it's just 1x
        name = "got-"&HouseToString(MyHouse)&"battlecomplete"
        sound = "gotfx-"&HouseToString(MyHouse)&"battlecomplete"
        delay = CompletionAnimationTimes(MyHouse)
        DMDPlayHitScene name,sound,delay,BattleObjectivesShort(MyHouse),line2,"COMPLETE",comboval,1
        If HouseBattle1 = 0 And HouseBattle2 = 0 And bUseFlexDMD Then 
            tmrBattleCompleteScene.Interval=3000
            tmrBattleCompleteScene.Enabled = 1
            tmrBattleCompleteScene.UserValue = MyHouse
        End If
    End Sub

    ' Return to normal play after battle mode
    Public Sub EndBattleMode
        Dim br,i
        ' Disable mode timer and HouseBattle
        If MyHouse = Targaryen Then StopSound "gotfx-dragonwings"
        If MyHouse = HouseBattle1 Then 
            TimerFlags(tmrBattleMode1) = 0
            HouseBattle1 = 0 
            If HouseBattle2 <> 0 Then ' Move Stacked battle to the primary position
                House(CurrentPlayer).BattleState(HouseBattle2).OtherHouse = MyHouse
                HouseBattle1=HouseBattle2 : HouseBattle2=0 
                TimerFlags(tmrBattleMode2) = TimerFlags(tmrBattleMode2) and 254
                timerTimestamp(tmrBattleMode1) = timerTimestamp(tmrBattleMode2)
            End If
        Else
            House(CurrentPlayer).BattleState(HouseBattle1).OtherHouse = MyHouse
            TimerFlags(tmrBattleMode2) = 0
            HouseBattle2 = 0
        End If

        CloseTopGates

        If HouseBattle1 = 0 And HouseBattle2 = 0 Then  
            PlayerMode = 0
            ' Check to see whether there are any non-lit houses. If not, always light BattleReady at the end of a battle
            ' Also light BattleReady if two balls are locked and at least one house is qualified
            Dim br1:br1=False
            br = True
            if Not bTargaryenInProgress Then
                For i = 1 to 7
                    If House(CurrentPlayer).Qualified(i) = False And House(CurrentPlayer).Completed(i) = False  Then br = False
                    If BallsInLock = 2 and bLockIsLit And House(CurrentPlayer).Qualified(i) = True And House(CurrentPlayer).Completed(i) = False Then br1=True
                Next
            End If
            If br or br1 Then House(CurrentPlayer).BattleReady = True

            If Not bMultiBallMode Then
                TimerFlags(tmrUpdateBattleMode) = 0     ' Disable the timer that updates the Battle Alternate Scene
                DMDResetScoreScene
                House(CurrentPlayer).SetUPFState False
            End If

            If Not bComplete Then DoBattleCompleteScene
        ElseIf Not bMultiBallMode Then ' Another house battle is still active and no MB, so regenerate battle scene
            DMDCreateAlternateScoreScene HouseBattle1,0
        End If
        PlayModeSong
        SetPlayfieldLights
    End Sub

    ' Called by the timer when the mode timer has expired
    Public Sub BattleTimerExpired
        If MyHouse = Martell And State = 2 Then 
            DoCompleteMode 0
        Else 
            EndBattleMode
        End if
    End Sub

    Public Sub BEndHurryUp
        If MyHouse = Martell And State = 2 Then 
            DoCompleteMode 0
        Else
            If MyHouse = Targaryen And State = 8 Then
                'Dragon Fire!!
                DMDPlayHitScene "got-targaryenbattlehit7","gotfx-targaryenbattlehit7",3.5,"DRAGON","FIRE","",0,4
                State = 7
                TGShotCount = 0
                DrogonHits = DrogonHits - 1
            End If
            EndBattleMode
        End if
    End Sub

    ' Add time to a mode
    Public Sub AddTime(t)
        If MyHouse = Targaryen Or (MyHouse = Martell And State = 2) Then ' Add value to HurryUp
            HurryUpValue = HurryUpValue + (HurryUpChange * 5 * t)
        Else    ' timer
            If MyHouse = HouseBattle2 Then 
                TimerTimestamp(tmrBattleMode2) = TimerTimestamp(tmrBattleMode2)+(t*10)
            Else 
                TimerTimestamp(tmrBattleMode1) = TimerTimestamp(tmrBattleMode1)+(t*10)
            End If
        End If
        ' TODO - play the "Add Time" scene
    End Sub

    ' Upper Playfield Castle loop. 
    ' When not lit, contributes to mode completion
    Public Sub RegisterCastleHit
        Dim i
        Select Case MyHouse
            Case Stark: Me.RegisterHit Stark : Me.AddTime 5
            Case Baratheon: RegisterSpinnerHit : Me.AddTime 5
            Case Lannister
                If ShotMask = 0 Then
                    ' Register hit against first lit gold target
                    For i = 0 to 4
                        If (GoldShotMask And 2^i) > 0 then RegisterGoldHit i : Exit For
                    Next
                Else
                    ' Register hit against first shot
                    For i = 1 to 7
                        If (ShotMask And 2^i) > 0 Then RegisterHit i : Exit For
                    Next
                End If
                Me.AddTime 5
            Case Greyjoy
                ' Register hit against first shot
                For i = 1 to 7
                    If (ShotMask And 2^i) > 0 Then RegisterHit i : Exit For
                Next
            Case Tyrell: If (State MOD 2) = 0 Then Me.RegisterHit Tyrell Else Me.RegisterHit Stark
            Case Martell: If (State = 1) Then Me.RegisterHit Greyjoy Else Me.AddTime 5
            Case Targaryen: Me.AddTime 5
        End Select
    End Sub

    ' Upper Playfield Castle Loop completes this Mode when lit
    ' But no score awarded, other than what they get from the castle itself
    Public Sub RegisterCastleComplete
        If MyHouse <> Targaryen Then
            bComplete = True
            House(CurrentPlayer).HouseCompleted MyHouse

            EndBattleMode
        Else
            'TODO Targaryen Upper PF battle complete rules

        End If

        SetLightColor HouseSigil(MyHouse),HouseColor(SelectedHouse),1
    End Sub

    ' Some battles involve the spinner
    Public Sub RegisterSpinnerHit
        If MyHouse <> Baratheon Then Exit Sub
        ' ShotMask = ShotMask And 239 ' turn off bit 4
        HouseValue = HouseValue + HouseValueIncrement
        If HouseValue > 150000000 Then HouseValue = 150000000
        DMDBaratheonSpinnerScene HouseValue
        
        If State = 1 And HouseValue > 20000000 Then   ' TODO Spinner value needs to build how high before advancing to State 2?
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
        ElseIf MyHouse = Targaryen And State = 7 And (ShotMask And 4) > 0 And tgt = 0 Then
            Me.RegisterHit Baratheon
        ElseIf MyHouse = Targaryen And State = 7 And (ShotMask And 32) > 0 And tgt = 1 Then
            Me.RegisterHit Tyrell
        ElseIf tgt = 0 And MyHouse = Baratheon Then
            ResetDropTargets
        ElseIf tgt = 1 Then
            Me.RegisterHit Tyrell
        End if
    End Sub

    ' Lannister battle mode needs to know about gold target hits
    Public Sub RegisterGoldHit(tgt)
        Dim litmask,litshots,growval
        If MyHouse <> Lannister Then Exit Sub
        If (GoldShotMask And 2^tgt) = 0 Then 
            PlaySoundVol "gotfx-litgold",VolDef
            If SelectedHouse = Lannister Then AddGold 15 Else AddGold 5
            Exit Sub   ' Gold target wasn't lit
        End If
        If SelectedHouse = Lannister Then AddGold 100 Else AddGold 15
        PlaySoundVol "gotfx-goldcoin",VolDef
        GoldShotMask = GoldShotMask Xor 2^tgt
        Select Case tgt
            Case 0: litmask = 144
            Case 1: litmask =  136
            Case 2,3: litmask = 10
            Case 4: litmask = 66
        End Select
        litshots = "+1 SHOT LIT"
        If (ShotMask And litmask) = litmask Then 
            litshots = ""
        ElseIf (ShotMask And litmask) = 0 Then 
            litshots = "+2 SHOTS LIT"
        End If
        ShotMask = ShotMask Or litmask
        HouseValue = HouseValue + 125000
        SetModeLights
        DMDPlayHitScene "got-lannisterbattlehit1","gotfx-lannisterbattlehit1",1.5,"HOUSE LANNISTER VALUE GROWS",HouseValue,litshots,0,2
    End Sub

    ' Called when the 10 second timer runs down
    Public Sub MartellTimer: CompletedShots = 0: UpdateBattleScene: End Sub

    Public Sub TGStartHurryUp
        If MyHouse <> Targaryen Then Exit Sub
        Me.SetTGHurryUpValue
        MyBattleScene.GetLabel("TGHurryUp").Visible = True
        StartTGHurryUp HouseValue,MyBattleScene,5
    End Sub

    Public Sub SetTGHurryUpValue
        If MyHouse <> Targaryen Then Exit Sub
        Select Case State
            Case 1,2,3: HouseValue = 6000000 + 2000000*State ' verified
            Case 4,5,6: HouseValue = 3000000*State ' verified
            Case 7: HouseValue = 9000000+3000000*TGShotCount ' real vals: 9M, 12M, 15M, 
            Case 8: HouseValue = 12000000
        End Select
        ' There's a bit of a race condition here, since the battle scene gets set up
        ' before the HurryUp is started. So stuff the right value into the Targaryen HurryUpValue
        ' so that the scene renders correctly at the beginning
        TGHurryUpValue = HouseValue
    End Sub

    Public Function TGLevel
        If MyHouse <> Targaryen Then TGLevel = 0:Exit Function
        If State < 4 Then 
            TGLevel = 0
        Elseif State < 7 Then 
            TGLevel = 1
        Else 
            TGLevel = 2
        End If
    End Function

'  bit   data (Label name)
'   0    Score
'   1    Ball
'   2    Credits
'   3    combo1 thru 5
'   4    HurryUp
'   5    BattleTimer1 (tmr1)
'   6    BattleTimer2 (tmr2)
'   7    MartellBattleTimer (tmr3)
'  Create a Battle Score scene specific to this House Battle
    Dim MyBattleScene
    Dim bSmallBattleScene
    Public Sub CreateBattleProgressScene(ByRef BattleScene)
        Dim tinyfont,ScoreFont,line3,x3,x4,y4,i
    
        Set tinyfont = FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0)
        
        If MyHouse = Targaryen Then
            ' Everything about the Targaryen scene is different
            Dim Dragon
            Select Case Me.TGLevel
                Case 0: Dragon = "VISERION"
                Case 1: Dragon = "RHAEGAL"
                Case 2: Dragon = "DROGON"
            End Select
            
            Me.SetTGHurryUpValue

            BattleScene.AddActor FlexDMD.NewLabel("Score",FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0),FormatScore(Score(CurrentPlayer)))
            BattleScene.GetLabel("Score").SetAlignedPosition 0,0,FlexDMD_Align_TopLeft
            BattleScene.AddActor FlexDMD.NewLabel("TGHurryUp",tinyfont,HouseValue) 'Placeholder value to ensure text is centered
            BattleScene.GetLabel("TGHurryUp").SetAlignedPosition 0,19,FlexDMD_Align_TopLeft
            BattleScene.AddActor FlexDMD.NewLabel("dragon",tinyfont,Dragon)
            BattleScene.GetLabel("dragon").SetAlignedPosition 127,7,FlexDMD_Align_TopRight
            'TODO: If dragon = DROGON, draw a health bar in the top right corner
        Else
            ' x3,y3 = line3 location
            y4 = 20 ' x4,y4 = timer location
            Select Case MyHouse
                Case Stark,Baratheon: line3 = "VALUE = "&FormatScore(HouseValue) : x3 = 40: x4 = 40: y4 = 22
                Case Lannister,Greyjoy: line3 = "SHOTS = " & 5-CompletedShots : x3 = 20: x4 = 56
                Case Tyrell: x4 = 40
                Case Martell: line3 = "SHOOT ORBITS":x3=25:x4 = 60
            End Select

            BattleScene.AddActor FlexDMD.NewLabel("obj",tinyfont,BattleObjectivesShort(MyHouse))
            BattleScene.AddActor FlexDMD.NewLabel("tmr1",tinyfont,Int((TimerTimestamp(tmrBattleMode1)-GameTimeStamp)/10))
            If MyHouse <> Tyrell Then
                BattleScene.AddActor FlexDMD.NewLabel("line3",tinyfont,line3) 
                BattleScene.GetLabel("line3").SetAlignedPosition x3,16,FlexDMD_Align_Center
            End If
            BattleScene.GetLabel("tmr1").SetAlignedPosition x4,y4,FlexDMD_Align_Center
            BattleScene.GetLabel("obj").SetAlignedPosition 40,3,FlexDMD_Align_Center

            If MyHouse = Martell Then
                BattleScene.AddActor FlexDMD.NewLabel("tmr3",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite, vbWhite, 0),"10")
                BattleScene.GetLabel("tmr3").SetAlignedPosition 40,13,FlexDMD_Align_Center
                If CompletedShots = 0 Or State > 1 Then BattleScene.GetLabel("tmr3").Visible = 0
                BattleScene.AddActor FlexDMD.NewLabel("HurryUp",tinyfont,"20000000") 'Placeholder value to ensure text is centered
                BattleScene.GetLabel("HurryUp").SetAlignedPosition 32,13,FlexDMD_Align_Center
                If State < 2 Then 
                    BattleScene.GetLabel("HurryUp").Visible = 0
                Else
                    BattleScene.GetLabel("line3").SetAlignedPosition 30,21,FlexDMD_Align_Center
                End If
            Else
                ' Every other house has the score showing
                BattleScene.AddActor FlexDMD.NewLabel("Score",FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0),FormatScore(Score(CurrentPlayer)))
                BattleScene.GetLabel("Score").SetAlignedPosition 40,9,FlexDMD_Align_Center
            End if
        End If

        For i = 1 to 5
            BattleScene.AddActor FlexDMD.NewLabel("combo"&i, FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbBlack, 1), "0")
        Next
        Set MyBattleScene = BattleScene
        bSmallBattleScene = False 
    End Sub

    Public Function CreateSmallBattleProgressScene(ByRef BattleScene, n)
        Dim tinyfont,ScoreFont,line2,x3,x4,y4,i
        'Set ScoreFont = FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0)
        Set tinyfont = FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbBlack, 0)
        BattleScene.AddActor FlexDMD.NewLabel("obj",tinyfont,HouseToUCString(MyHouse))
        If MyHouse <> Targaryen Then BattleScene.AddActor FlexDMD.NewLabel("tmr"&n,tinyfont,Int((TimerTimestamp(tmrBattleMode1)-GameTimeStamp)/10))
        
        y4 = 16
        Select Case MyHouse
            Case Stark,Baratheon: line2 = "VALUE = "& vbLf & FormatScore(HouseValue) 
            Case Lannister,Greyjoy: line2 = "SHOTS = " & 5-CompletedShots
            Case Tyrell: line2=""
            Case Martell: line2 = "SHOOT ORBITS"
        End Select

        If MyHouse = Martell Then
            BattleScene.AddActor FlexDMD.NewLabel("tmr3",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite,vbWhite, 0),"10")
            BattleScene.GetLabel("tmr3").SetAlignedPosition 32,13,FlexDMD_Align_Center
            If CompletedShots = 0 Or State > 1 Then BattleScene.GetLabel("tmr3").Visible = 0
        End If
        If MyHouse = Martell Then
            BattleScene.AddActor FlexDMD.NewLabel("HurryUp",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite,vbWhite, 0),"20000000") 'Placeholder value to ensure text is centered
            BattleScene.GetLabel("HurryUp").SetAlignedPosition 32,13,FlexDMD_Align_Center
            If State < 2 Then BattleScene.GetLabel("HurryUp").Visible = 0
        ElseIf MyHouse = Targaryen Then
            BattleScene.AddActor FlexDMD.NewLabel("TGHurryUp",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite,vbWhite, 0),"12000000") 'Placeholder value to ensure text is centered
            BattleScene.GetLabel("TGHurryUp").SetAlignedPosition 32,13,FlexDMD_Align_Center
        End If
        
        If MyHouse <> Targaryen Then
            BattleScene.AddActor FlexDMD.NewLabel("line3",tinyfont,line2) 
            BattleScene.GetLabel("line3").SetAlignedPosition 32,16,FlexDMD_Align_Center
            BattleScene.GetLabel("tmr"&n).SetAlignedPosition 62,1,FlexDMD_Align_TopRight
        End If
        BattleScene.GetLabel("obj").SetAlignedPosition 1,1,FlexDMD_Align_TopLeft
        
        Set MyBattleScene = BattleScene
        bSmallBattleScene = True
    End Function

    ' Timers and score are updated by main score subroutine. We just take care of battle-specific values
    Public Sub UpdateBattleScene
        Dim line3
        if Not bUseFlexDMD Then Exit Sub
        If MyHouse = Martell Then
            FlexDMD.LockRenderThread
            If State = 2 Then
                MyBattleScene.GetLabel("tmr3").Visible = 0
                With MyBattleScene.GetLabel("line3")
                    .Text = "SHOOT RAMPS"
                    .SetAlignedPosition 30,21,FlexDMD_Align_Center
                End with
                MyBattleScene.GetLabel("HurryUp").Visible = 1
            Else
                If CompletedShots = 0 Then 
                    MyBattleScene.GetLabel("tmr3").Visible = 0
                    MyBattleScene.GetLabel("line3").SetAlignedPosition 30,16,FlexDMD_Align_Center
                Else 
                    MyBattleScene.GetLabel("tmr3").Visible = 1
                    MyBattleScene.GetLabel("line3").SetAlignedPosition 30,21,FlexDMD_Align_Center
                End if
            End if
            FlexDMD.UnlockRenderThread
            Exit Sub
        ElseIf MyHouse <> Targaryen Then
            Select Case MyHouse
                Case Stark,Baratheon 
                    If bSmallBattleScene Then 
                        line3 = "VALUE = "& vbLf & FormatScore(HouseValue) 
                    Else  
                        line3 = "VALUE = " & FormatScore(HouseValue)
                    End If
                Case Lannister,Greyjoy: line3 = "SHOTS = " & 5-CompletedShots
                Case Else: Exit Sub
            End Select
            FlexDMD.LockRenderThread
            MyBattleScene.GetLabel("line3").Text = line3
            FlexDMD.UnlockRenderThread
        End If
    End Sub

    Public Sub DoBattleCompleteScene
        DoMyBattleCompleteScene
        If OtherHouseBattle <> 0 Then House(CurrentPlayer).BattleState(OtherHouseBattle).DoMyBattleCompleteScene
    End Sub

    Public Sub DoMyBattleCompleteScene
        If Not bUseFlexDMD Then Exit Sub
        Dim scene
        Set scene = NewSceneWithVideo("btotal","got-"&HouseToString(MyHouse)&"battlesigil")
        scene.GetVideo("btotalvid").SetAlignedPosition 127,0,FlexDMD_Align_TopRight
        scene.AddActor FlexDMD.NewLabel("ttl",FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0),HouseToUCString(MyHouse)&" TOTAL")
        scene.AddActor FlexDMD.NewLabel("bscore",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite, vbBlack, 0),FormatScore(TotalScore))
        scene.GetLabel("ttl").SetAlignedPosition 0,10,FlexDMD_Align_Left
        scene.GetLabel("bscore").SetAlignedPosition 40,20,FlexDMD_Align_Center
        DMDEnqueueScene scene,0,3000,3000,4000,"gotfx-battletotal"
    End Sub

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

Function HouseToUCString(h)
    Select Case h
        Case 0
            HouseToUCString = ""
        Case Stark
            HouseToUCString = "STARK"
        Case Baratheon
            HouseToUCString = "BARATHEON"
        Case Lannister
            HouseToUCString = "LANNISTER"
        Case Greyjoy
            HouseToUCString = "GREYJOY"
        Case Tyrell
            HouseToUCString = "TYRELL"
        Case Martell
            HouseToUCString = "MARTELL"
        Case Targaryen
            HouseToUCString = "TARGARYEN"
    End Select
End Function

'**************************************************
' Table, Game, and ball initialization code
'**************************************************

Sub VPObjects_Init
    Dim i
    BumperWeightTotal = 0
    For i = 1 To BumperAwards:BumperWeightTotal = BumperWeightTotal + PictoPops(i)(2): Next
    ReplayScore = 298000000
    SetDefaultPlayfieldLights   ' Sets all playfield lights to their default colours
End Sub

Sub Game_Init()     'called at the start of a new game
    SetDefaultPlayfieldLights   ' Sets all playfield lights to their default colours
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
    bBattleInstructionsDone = False
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
    bBlackwaterSJPMode = False
    
    ' The below settings will be overwritten by PlayerState.Restore if this isn't Ball 1 
    WildfireTargetsCompleted = 0
    LoLTargetsCompleted = 0
    CompletedHouses = 0
    TotalGold = 0
    CurrentGold = 0
    TotalWildfire = 0
    CurrentWildfire = 0
    SwordsCollected = 0
    bLockIsLit = False
    BWMultiballsCompleted = 0
    WallMBCompleted = 0
    WallMBLevel = 0
    bWallMBReady = False
    ' End restore

    bMysteryLit = True     ' TODO: While Debugging
    bSwordLit = True       ' TODO: While debugging
    bElevatorShotUsed = False
    bCastleShotAvailable = False
    SetTopGates
    MoveDiverter 1

    ' Drop the right ramp target
    PlaySoundAt "fx_droptarget", Target90
    Target90.IsDropped = 1

    HouseBattle1 = 0 : HouseBattle2 = 0

    ' Reset Combo multipliers
    ResetComboMultipliers

    if (House(CurrentPlayer).MyHouse = 0) Then
        PlayerMode = -1
        SelectedHouse = 1
        FlashShields SelectedHouse,1
        If CurrentPlayer = 1 Then
            PlaySoundVol "say-choose-your-house1",VolDef
        Else
            PlaySoundVol "player"&CurrentPlayer,VolDef
            vpmTimer.AddTimer 1000,"PlaySoundVol ""say-choose-your-house1"",VolDef '"
        End If
        ChooseHouse 0
    Else 
        PlayerState(CurrentPlayer).Restore
        PlayerMode = 0
        SelectedHouse = House(CurrentPlayer).MyHouse
        House(CurrentPlayer).ResetForNewBall
    End If
    SetPlayfieldLights
    PlayModeSong
End Sub

Sub ResetNewBallVariables() 'reset variables for a new ball or player
    dim i
    'turn on or off the needed lights before a new ball is released
    ResetPictoPops
    ResetDropTargets
     ' Top lanes start out off on the Premium/LE
    For i = 0 to 1 : bTopLanes(i) = False : Next
    'playfield multipiplier
    pfxtimer.Enabled = 0
    PlayfieldMultiplierVal = 1
    PFMState = 0
    SpinnerLevel = 1
    AccumulatedSpinnerValue = 0
    SpinnerValue = 500 + (1+BallsPerGame-BallsRemaining(CurrentPlayer))*2000 ' Appears to start at 2500 on ball 1 and 4500 on ball 2
    SetPFMLights
    bWildfireLit = False
    bPlayfieldValidated = False
    bBattleCreateBall = False
End Sub

Sub SetPlayfieldLights
    TurnOffPlayfieldLights
    If PlayerMode = 1 or PlayerMode = -2.1 Then
        SetModeLights       ' Set Sigils and Shields for battle, as well as UpperPF lights
    ElseIf PlayerMode = 0 Or PlayerMode = 2 Then
        If House(CurrentPlayer).MyHouse > 0 Then House(CurrentPlayer).ResetLights    ' Set Sigils and Shields for normal play
        SetGoldTargetLights
    ElseIf PlayerMode = -1 Then 'ChooseHouse
        FlashShields SelectedHouse,True
    End If
    SetLockLight
    SetOutlaneLights
    SetTopLaneLights
    SetWildfireLights
    SetPFMLights
    If PlayerMode = 2 Then Exit Sub

    ' Lights below here stay off during a WiC HurryUp
    SetMysteryLight
    SetSwordLight
    SetComboLights
    SetTargetLights
    SetBatteringRamLights
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
    If (BallsOnPlayfield-RealBallsInLock = 2) And LastSwitchHit = "OutlaneSW" And (bBallSaverActive = True Or bLoLLit = True) Then
        ' Preemptive ball save
        bAutoPlunger = True
        If bBallSaverActive = False Then bLoLLit = False: SetOutlaneLights
    ElseIf (BallsOnPlayfield-RealBallsInLock > 1) Then
        DOF 143, DOFPulse
        bMultiBallMode = True
        bAutoPlunger = True
    End If
End Sub


Sub DoBallSaved(l)
    ' create a new ball in the shooters lane
    ' we use the Addmultiball in case the multiballs are being ejected
    AddMultiball 1
    ' we kick the ball with the autoplunger
    bAutoPlunger = True
    bBallSaved = True
    If l Then
        PlaySoundVol "gotfx-lolsave",VolDef
        bLoLLit = False
    Else
        ' TODO: Add ball-saved animation and sound
        DMD "", CL(1, "BALL SAVED"), "", eNone, eNone, eNone, 1000, True, ""
        if Not bMultiBallMode Then BallSaveTimer
    End If
End Sub

Sub EnableBallSaver(seconds)
    'debug.print "Ballsaver started"
    ' set our game flag
    bBallSaverActive = True
    bBallSaverReady = False
    ' start the timer
    SetGameTimer tmrBallSave,seconds*10
    SetGameTimer tmrBallSaveSpeedUp,(seconds-5)*10
    ' if you have a ball saver light you might want to turn it on at this point (or make it flash)
    LightShootAgain.BlinkInterval = 160
    LightShootAgain.State = 2
End Sub

' The ball saver timer has expired.  Turn it off AND reset the game flag
'
Sub BallSaveTimer
    'debug.print "Ballsaver ended"
    ' clear the flag
    bBallSaverActive = False
    If ExtraBallsAwards(CurrentPlayer) = 0 Then LightShootAgain.State = 0 Else LightShootAgain.State = 1
End Sub

Sub BallSaverSpeedUpTimer
    'debug.print "Ballsaver Speed Up Light"
    ' Speed up the blinking
    LightShootAgain.BlinkInterval = 80
    LightShootAgain.State = 2
End Sub

Sub AddScore(points)
    ResetBallSearch
    'TODO: GoT allows you to hit certain targets without validating the playfield and starting timers
    ThawAllGameTimers
    bPlayfieldValidated = True
    PlayModeSong
    If (Tilted = False) Then
        ' if there is a need for a ball saver, then start off a timer
        ' only start if it is ready, and it is currently not running, else it will reset the time period
        If(bBallSaverReady = True)AND(BallSaverTime <> 0)And(bBallSaverActive = False)Then
            EnableBallSaver BallSaverTime
        End If

        'TODO: Award replay if score goes over replay score
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
        PlayerMode >= 0 and _
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
' Handle any bonus points awarded. This is a mini state machine. State is
' stored in timer.UserValue. States:
' "BONUS" 0.25s
' Base Bonus 0.45s
' X Houses complete 0.45s
' Swords 150k each 0.45s
' Castles 0.45s
' Gold (405=121500) 0.45s  e.g “405 GOLD” on line 1, “121,500” on line 2
' Wildfire (22=121000) 0.55s
' Then bonus X times all added together 1.2s
' Then Total bonus. 1.4s
'
' Note, there are 7 "notes" in the ROM, but only 6 bonuses. Perhaps note 7 is reserved.
' In any case, we skip over it below, in case we want it in the future.

'TODO: Add support for fastforwarding bonus if flipper is held in
Dim tmpBonusTotal
dim bonusCnt
Sub tmrEndOfBallBonus_Timer()
    Dim scene,line1,line2,ol,skip,font
    ol = False
    skip = False
    tmrEndOfBallBonus.Enabled = False
    tmrEndOfBallBonus.Interval = 500
    ' State machine based on GoTG line 2549 onwards
    Select Case tmrEndOfBallBonus.UserValue
        Case 0
            bonusCnt = 0
            StopSound Song
            line1 = "BONUS"
            ol = True
            'tmrEndOfBallBonus.Interval = 250
        Case 1
            line1 = "BASE BONUS" & vbLf & FormatScore(BonusPoints(CurrentPlayer))
            BonusCnt = BonusPoints(CurrentPlayer)
        Case 2 
            If CompletedHouses > 0 Then
                line1 = CompletedHouses & " HOUSES COMPLETE":line2= FormatScore(175000*CompletedHouses)
                BonusCnt = BonusCnt + (175000*CompletedHouses)
            Else
                Skip = True
            End If
        Case 3 
            If SwordsCollected > 0 Then
                line1 = SwordsCollected & " SWORD"
                If SwordsCollected > 1 Then line1 = line1&"S"
                line2 = FormatScore(150000*SwordsCollected)
                BonusCnt = BonusCnt + (150000*SwordsCollected)
            Else
                Skip = True
            End If
        Case 4
            If CastlesCollected > 0 Then
                line1 = CastlesCollected & " CASTLE"
                If CastlesCollected > 1 Then line1 = line1&"S" 
                line2 = FormatScore(7500000*CastlesCollected)
                BonusCnt = BonusCnt + (7500000*CastlesCollected)
            Else
                Skip = True
            End If
        Case 5
            If TotalGold > 0 Then
                line1 = FormatScore(TotalGold) & " GOLD" : line2 = FormatScore(300*TotalGold)
                BonusCnt = BonusCnt + (300*TotalGold)
            Else
                Skip = True
            End If
        Case 6
            If TotalWildfire > 0 Then
                line1 = FormatScore(TotalWildfire) & " WILDFIRE" : line2 = FormatScore(5500*TotalWildfire)
                BonusCnt = BonusCnt + (5500*TotalWildfire)
                tmrEndOfBallBonus.Interval = 600
            Else
                Skip = True
            End If
        Case 8
            line1 = BonusMultiplier(CurrentPlayer)&"X" : line2 = FormatScore(BonusCnt)
            tmrEndOfBallBonus.Interval = 1200
        Case 9
            line1 = "TOTAL BONUS" : line2 = FormatScore(BonusCnt * BonusMultiplier(CurrentPlayer))
            PlayfieldMultiplierVal = 1
            AddScore BonusCnt * BonusMultiplier(CurrentPlayer)
            tmrEndOfBallBonus.Interval = 1700
        Case 10
            vpmtimer.addtimer 100, "EndOfBall2 '"
            Exit Sub
        Case Else
            Skip = True
    End Select

    If Skip Then
        tmrEndOfBallBonus.Interval = 10
    Else
        ' Do Bonus Scene
        If bUseFlexDMD Then
            Set scene = FlexDMD.NewGroup("bonus")
            If ol Then
                Set font = FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbWhite, 0)
            Else
                line1 = line1 & vbLf & line2
                Set font = FlexDMD.NewFont("udmd-f6by8.fnt",vbWhite, vbWhite, 0)
            End if
            scene.AddActor FlexDMD.NewFrame("bonusbox")
            With scene.GetFrame("bonusbox")
                .Thickness = 1
                .SetBounds 0, 0, 128, 32      ' Each frame is 43W by 32H, and offset by 0, 42, or 84 pixels
            End With
            scene.AddActor FlexDMD.NewLabel("line1",font,line1)
            scene.GetLabel("line1").SetAlignedPosition 64,16,FlexDMD_Align_CENTER
            DMDClearQueue
            DMDEnqueueScene scene,0,1400,1400,10,"gotfx-spike-count"&tmrEndOfBallBonus.UserValue
        Else
            If ol Then 
                DisplayDMDText "",line1,tmrEndOfBallBonus.Interval
            Else
                DisplayDMDText line1,line2,tmrEndOfBallBonus.Interval
            End If
            PlaySoundVol "gotfx-spike-count"&tmrEndOfBallBonus.UserValue, VolDef
        End If
    End If

    tmrEndOfBallBonus.UserValue = tmrEndOfBallBonus.UserValue + 1
    tmrEndOfBallBonus.Enabled = True
End Sub

Sub EndOfBall()
    Dim AwardPoints, TotalBonus,delay
    AwardPoints = 0
    TotalBonus = 0
    ' the first ball has been lost. From this point on no new players can join in
    bOnTheFirstBall = False

	
    StopGameTimers
    If HouseBattle1 > 0 Then BattleModeTimer1
    If HouseBattle2 > 0 Then BattleModeTimer2
    EndHurryUp
    PlayerMode = 0
    
    ' only process any of this if the table is not tilted.  (the tilt recovery
    ' mechanism will handle any extra balls or end of game)

    If(Tilted = False)Then
        SetPlayfieldLights
        DMDflush

        delay = 0
        If tmrBattleCompleteScene.Enabled = 1 Then
            delay=3000
            tmrBattleCompleteScene_Timer
        End If
        ' Delay for a Battle Total screen to be shown
        tmrEndOfBallBonus.Interval = delay + 400
        ' Start the Bonus timer - this timer calls the Bonus Display code when it runs down
		tmrEndOfBallBonus.UserValue = 0
		tmrEndOfBallBonus.Enabled = true
        ' Bonus will start EndOfBall2 when it is done
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
    Dim i

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

        ' Drop the lock walls just in case the ball is behind it (just in Case)
        SwordWall.collidable = False
        LockWall.collidable = False
        vpmtimer.addtimer 1000, "LockWallReset '"

		bGameInPLay = False									' EndOfGame sets this but need to set early to disable flippers 
		bShowMatch = True

		' Do Match end score code
		Match=10 * INT(RND * 9)
		'Match = Score(CurrentPlayer) mod 100		' Force Match for testing 
		if BigMod(Score(CurrentPlayer), 100) = Match then									' Handles large scores 
			vpmtimer.addtimer 6000, "PlayYouMatched '"
		End If

        DMDDoMatchScene Match
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
			vpmtimer.addtimer 9500, "if bShowMatch then EndOfGame() '"
		'End If 

    ' you may wish to put a Game Over message on the desktop/backglass

    Else
        ' set the next player
        CurrentPlayer = NextPlayer
		'UpdateNumberPlayers				' Update the Score Sizes
        ' make sure the correct display is up to date
        AddScore 0

        ' reset the playfield for the new player (or new ball)
        ResetForNewPlayerBall()

        ' AND create a new ball
        CreateNewBall()

        ' play a sound if more than 1 player
        If PlayersPlayingGame > 1 Then
            'TODO: Add "player <X>, you're up!" sound
            'PlaySoundVol "say-player" &CurrentPlayer+1, VolDef
            DMD "", CL(1, "PLAYER " &CurrentPlayer+1), "", eNone, eNone, eNone, 800, True, ""
        End If
    End If
End Sub

' This function is called at the End of the Game, it should reset all
' Drop targets, AND eject any 'held' balls, start any attract sequences etc..

Sub EndOfGame()

    If bGameInPLay = True then Exit Sub ' In case someone pressed 'Start' during Match sequence
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
	vpmtimer.addtimer 1000, "LockWallReset '"

    ' TODO: Add an end-of-game pithy quote
    DMD "_", "GAME OVER", "",eNone,eNone,eNone,6000,true,""

    ' most of the modes/timers terminate at the end of the ball

	'PlaySong "m_end"
	'playmedia "m_end.mp3", MusicDir, pAudio, "", -1, "", 1, 1

    ' set any lights for the attract mode
    GiOff
	'bFlash1Enabled = True
	'bFlash2Enabled = True
	'bFlash3Enabled = True
	'bFlash4Enabled = True

    vpmTimer.AddTimer 3000,"StartAttractMode '"

' you may wish to light any Game Over Light you may have
End Sub

Sub PlayYouMatched
    'TODO: Play a 'Matched!' sound/video
	'PlaySoundVol "YouMatchedPlayAgain", VolDef
	DOF 140, DOFOn
	DMDFlush
	DMD "_", CL(1, "CREDITS: " & Credits), "", eNone, eNone, eNone, 500, True, "fx_kicker"
End Sub 

' Set the virtual lock wall ready to lock a ball
Sub LockWallReset
    SwordWall.collidable = False
    LockWall.collidable = True
End Sub

' Plays the right song for the current situation
Sub PlayModeSong
    Dim mysong,i
    mysong = ""
    If PlayerMode = 2 Then
        mysong = "gotfx-long-wind-blowing"
    ElseIf bPlayfieldValidated = False Then
        mysong = "got-track-playfieldunvalidated"
    ElseIf PlayerMode = -2 Then
        mysong = "got-track-choosebattle"
    ElseIf bMysteryAwardActive Then
        mysong = "got-track-choosemystery"
    ElseIf Playermode = 1 or PlayerMode = -2.1 Then
        mysong = "got-track5"
    ElseIf bMultiBallMode Then
        mysong = "got-track4"
    End If
    If mysong = "" Then
        If Song = "got-track1" Or Song = "got-track2" Or Song = "got-track3" Then Exit Sub
        i = BallsPerGame - BallsRemaining(CurrentPlayer) + 1
        mysong = "got-track"&i
    End If
    If Song <> mysong Then PlaySong mysong
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
    if bBWMultiballActive Then
        BWMultiballsCompleted = BWMultiballsCompleted + 1
        DMDBlackwaterCompleteScene
    End If
    bBWMultiballActive = False
    BlackwaterSJPTimer
    If PlayerMode = 0 Then TimerFlags(tmrUpdateBattleMode) = 0
    PlayModeSong
    If PlayerMode = 1 Then 
        DMDCreateAlternateScoreScene HouseBattle1,HouseBattle2
    Else
        DMDResetScoreScene
    End If
    House(CurrentPlayer).SetUPFState False
    SetPlayfieldLights
End Sub

Sub RotateLaneLights(dir)
    If bTopLanes(0) or bTopLanes(1) Then
        bTopLanes(0) = Not bTopLanes(0)
        bTopLanes(1) = Not bTopLanes(1)
        SetTopLaneLights
    End If
End Sub

Sub OpenTopGates: topgatel.open = True: topgater.open = True: End Sub
Sub CloseTopGates: SetTopGates : End Sub

Sub SetTopGates
    Dim lstate,rstate
    lstate=False:rstate=False
    If HouseBattle1 = Baratheon or HouseBattle2 = Baratheon or HouseBattle1 = Martell or HouseBattle2 = Martell or HouseBattle1=Greyjoy or HouseBattle2 = Greyjoy Then
        lstate=True:rstate=True
    ElseIf bEBisLit or bElevatorShotUsed = False or (bMysteryLit And Not bMultiBallMode And PlayerMode = 0) Then
        lstate=True : MoveDiverter(1)
    End If
    If ComboMultiplier(1) > 1 Then rstate=True
    topgater.open = rstate
    topgatel.open = lstate
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

Sub MoveDiverter(o)
    if o then
        Diverter.ObjRotZ = 22
        Diverter.collidable = 0
    Else
        Diverter.ObjRotZ = 0
        Diverter.collidable = 1
    End If
End Sub

Sub ResetComboMultipliers
    Dim i
    For i = 0 to 5: ComboMultiplier(i) = 1: Next
    SetComboLights
    DMDLocalScore
End Sub

Sub SetMystery
    If bMysteryLit = True And PlayerMode = 0 And Not bMultiBallMode Then
        SetLightColor li153, white, 2  ' Turn on Mystery light
        MoveDiverter 1
        topgatel.open = True
    End If
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

Sub SetPFMLights
    ' Update the playfield multiplier lights
    Dim i
    For i = 2 to 5
        If PlayfieldMultiplierVal < i Then 
            SetLightColor pfmuxlights(i-2),amber,0
        Elseif PlayfieldMultiplierVal = i Then
            pfmuxlights(i-2).BlinkInterval = 100
            SetLightColor pfmuxlights(i-2),amber,2
        Else 
            SetLightColor pfmuxlights(i-2),amber,1
        End If
    Next
End Sub

' Set an effect on the Upper Playfield flashers
' fx : one of a number of flasher effects
'    0 = off, 1=on, 2=flash indefinitely, 3=flash 5 times fast, 4=flash 10 times fast
' col : colour const to use for the colour
Dim UPFFlasherState(2)
Sub SetUPFFlashers(fx,col)
    dim times,interval,i,fl
    Select Case fx
        Case 0: UPFFlasher001.visible = 0 : UPFFlasher002.visible = 0 : Exit Sub
        Case 1: times = 0
        Case 2: times = -1 : interval = 100 ' blink indefinitely
        Case 3: times = 5 : interval = 50 ' flash 5 times rapidly (half second flash)
        Case 4: times = 10 : interval= 50 ' flash 10 times rapidly (1 second)
    End Select
    i = 0
    For each fl in Array(UPFFlasher001,UPFFlasher002)
        ' Save current state
        If fl.visible = 0 then UPFFlasherState(i) = 0 Else UPFFlasherState(i) = fl.color
        ' Turn flasher on and set colour
        SetFlashColor fl,col,1
        If times = 0 Then
            fl.TimerEnabled = 0
        Else
            ' Set up a timer on the flasher with a subroutine that we define. Sub 
            fl.TimerInterval = interval
            fl.UserValue = times * 2
            fl.TimerEnabled = 0
            fl.TimerEnabled = 1
        End If
        i = i + 1
    Next
End Sub

Sub UPFFlasher001_Timer
    Dim tmp
    tmp=me.UserValue
    tmp=tmp-1
    Me.Visible = tmp MOD 2
    me.UserValue = tmp
    If tmp = 0 Then
        Me.Visible = 1
        Me.TimerEnabled=0
        me.color=UPFFlasherState(0)
        If me.color=0 then me.visible=0
    End if
End Sub

Sub UPFFlasher002_Timer
    Dim tmp
    tmp=me.UserValue
    tmp=tmp-1
    Me.Visible = tmp MOD 2
    me.UserValue = tmp
    If tmp = 0 Then
        Me.Visible = 1
        Me.TimerEnabled=0
        me.color=UPFFlasherState(1)
        If me.color=0 then me.visible=0
    End if
End Sub
    

' During Battle mode, Shield lights may be in one of several states
' They may also alternate colour. To deal with this, create an array of
' light states and set a timer on each light to cycle through its states
' 1st element of array is number of states for this light
' This Sub sets the jackpot light. The SetModeLights in the BattleState class
' handles all of the battle-related colours
Dim ModeLightState(10,10)
Sub SetModeLights
    Dim i

    House(CurrentPlayer).SetShieldLights

    ' Set up timers on the Shield lights that have more than one state defined
    ' Turn off the lights of those that don't
    For i = 1 to 7
        If ModeLightState(i,0) < 2 Then
            HouseShield(i).TimerEnabled = False 
            HouseShield(i).State = 0
        Else 
            HouseShield(i).TimerEnabled = True
        End If
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
    If uv > ModeLightState(1,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li26_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(2,uv) > 0 Then SetLightColor Me,ModeLightState(2,uv),1 Else Me.state=0
    uv = uv + 1
    If uv > ModeLightState(2,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li114_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(3,uv) > 0 Then SetLightColor Me,ModeLightState(3,uv),1 Else Me.state=0
    uv = uv + 1
    If uv > ModeLightState(3,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li86_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(4,uv) > 0 Then SetLightColor Me,ModeLightState(4,uv),1 Else Me.state=0
    uv = uv + 1
    If uv > ModeLightState(4,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li77_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(5,uv) > 0 Then SetLightColor Me,ModeLightState(5,uv),1 Else Me.state=0
    uv = uv + 1
    If uv > ModeLightState(5,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li156_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(6,uv) > 0 Then SetLightColor Me,ModeLightState(6,uv),1 Else Me.state=0
    uv = uv + 1
    If uv > ModeLightState(6,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li98_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(7,uv) > 0 Then SetLightColor Me,ModeLightState(7,uv),1 Else Me.state=0
    uv = uv + 1
    If uv > ModeLightState(7,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li189_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(8,uv) > 0 Then SetLightColor Me,ModeLightState(8,uv),1 Else Me.state=0
    uv = uv + 1
    If uv > ModeLightState(8,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li192_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(9,uv) > 0 Then SetLightColor Me,ModeLightState(9,uv),1 Else Me.state=0
    uv = uv + 1
    If uv > ModeLightState(9,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

Sub li195_Timer
    Dim uv
    uv = Me.UserValue
    Me.TimerEnabled = False
    If ModeLightState(10,uv) > 0 Then SetLightColor Me,ModeLightState(10,uv),1 Else Me.state=0
    uv = uv + 1
    If uv > ModeLightState(10,0) Then uv = 1
    Me.UserValue = uv
    Me.TimerEnabled = True
End Sub

'*******************************************************
' Combo multiplier light timer
' Used to speed up the flash rate as the timer runs down
'*******************************************************
'ComboLights = Array(li89,li89,li101,li117,li144,li159)
Sub li89_Timer
    Dim i,bi
    For i = 1 to 5
        If ComboMultiplier(i) > 1 Then 
            bi = TimerTimestamp(tmrComboMultplier) - GameTimeStamp
            if bi > 50 then bi = 150 else bi = bi*2 + 50
            ComboLights(i).State = 0
            ComboLights(i).BlinkInterval = bi
            ComboLights(i).State = 2 ' Hopefully this ensure they all blink in unison.
        End if
    Next
End Sub

Sub CheckActionButton
    If PlayerMode = -2 Then 
        PreLaunchBattleMode
    ElseIf PlayerMode = -2.1 Then
        ' Skip battle intro animation and get to it
        DMDClearQueue
        LaunchBattleMode
    ElseIf PlayerMode >= 0 Then 
        House(CurrentPlayer).CheckActionBtn
    End If
End Sub

' Set the Bonus Multiplier to the specified level AND set any lights accordingly
' There is no bonus multiplier lights in this table

Sub SetBonusMultiplier(Level)
    ' Set the multiplier to the specified level
    BonusMultiplier(CurrentPlayer) = Level
End Sub

Sub IncreaseBonusMultiplier(bx)
    If BonusMultiplier(CurrentPlayer) = 20 then Exit Sub
    BonusMultiplier(CurrentPlayer) = BonusMultiplier(CurrentPlayer) + bx : If BonusMultiplier(CurrentPlayer) > 20 Then BonusMultiplier(CurrentPlayer) = 20
    Dim scene
    If bUseFlexDMD Then
        Set scene = FlexDMD.NewGroup("testscene")
        scene.AddActor FlexDMD.NewLabel("lbl1",FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbBlack, 1),BonusMultiplier(CurrentPlayer)&"X")
        scene.GetLabel("lbl1").SetAlignedPosition 64,16,FlexDMD_Align_CENTER
        BlinkActor scene.GetLabel("lbl1"),50,30
        scene.AddActor NewSceneFromImageSequence("img1","bonusx",50,20,2,0)
        DMDEnqueueScene scene,1,3000,4500,4000,"gotfx-wind-blowing"
    Else
        DisplayDMDText "",BonusMultiplier(CurrentPlayer)&"X BONUS",2000
    End If
End Sub

' ComboMultiplier increaser
' The logic is rather complicated. In general, a hit on one shot will increase the
' multiplier on the other shots to this shot's multiplier + 1. Ramps affect all other
' shots. L orbit affects only the next 2 adjacent shots. R orbit affects 3 middle shots.
' Dragon affects ALL shots (including itself) but the timer is half the length.
' In addition, it looks like a hit on a shot that's at 1x but is *different* from the
' the last shot will increase the multipliers on the other shots rather than just giving you
' one more than 2x
Dim LastComboHit
Sub IncreaseComboMultiplier(h)
    Dim i,c,x,tmr,mask,max
    tmr = 150           ' Default combo rundown timer
    c = ComboLaneMap(h)
    If c = 0 And h <> 0 Then Exit Sub  ' Target bank was hit - they don't increase multipliers
    max = 5             ' TODO: When can the Combo multiplier go to 6?
    If max > 3+SwordsCollected Then max = 3+SwordsCollected
    If c = 0 Then 
        For i = 1 to 5
            If ComboMultiplier(i) > x Then x = ComboMultiplier(i)
        Next
    Else 
        x = ComboMultiplier(c)
    End If
    x = x + 1
    if x > max Then x = max ' TODO: When can the Combo multiplier go to 6?
    Select Case c
        Case 0          ' Used for Inlane hit increases
            mask = 62   ' Increase x of all shots
        Case 1          ' Left orbit
            mask = 12   ' Turn on shots 2 & 3
        Case 2          ' Dragon shot
            mask = 62
            tmr = 80
        Case 3          ' L ramp
            mask = 54
        Case 4          ' R ramp
            mask = 46
        Case 5          ' Right orbit
            mask = 28
    End Select
    For i = 1 to 5
        If (mask And 2^i) > 0 Then 
            If c = LastComboHit or x > ComboMultiplier(i) Then
                ComboMultiplier(i) = x
            ElseIf ComboMultiplier(i) < max Then
                ComboMultiplier(i) = ComboMultiplier(i) + 1
            End If
        Else
            ComboMultiplier(i) = 1
        End If
    Next
    LastComboHit = c
    SetGameTimer tmrComboMultplier,tmr
    SetComboLights
    DMDLocalScore 'Update the DMD. TODO: On the real game, the DMD flashes the multipliers when they first change
End Sub

Sub AddGold(g)
    Dim scene
    TotalGold = TotalGold + g
    CurrentGold = CurrentGold + g
    If bUseFlexDMD And PlayerMode <> 2 Then
        Set scene = NewSceneWithImage("goldstack","goldstack")
        scene.AddActor FlexDMD.NewLabel("addgold",FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbBlack, 0),"+"&g&" GOLD")
        scene.GetLabel("addgold").SetAlignedPosition 2,0,FlexDMD_Align_TopLeft
        BlinkActor scene.GetLabel("addgold"),150,4
        scene.AddActor FlexDMD.NewLabel("gold",FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbBlack, 0),"TOTAL GOLD: "&CurrentGold)
        scene.GetLabel("gold").SetAlignedPosition 2,27,FlexDMD_Align_BottomLeft
        DMDEnqueueScene scene,2,1200,2000,2000,""
    End If
End Sub

Sub AddBonus(b)
    BonusPoints(CurrentPlayer) = BonusPoints(CurrentPlayer) + b
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
        DMDFlush
        ' TODO: Display additional text about house chosen on ball launch
        DMDLocalScore
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
    If PlayerMode = 1 Then
        If HouseBattle1 > 0 Then House(CurrentPlayer).BattleState(HouseBattle1).RegisterTargetHit 0
        If HouseBattle2 > 0 Then House(CurrentPlayer).BattleState(HouseBattle2).RegisterTargetHit 0
    ElseIf PlayerMode = 0 Then ' Only increase Spinner Value and play target dropped sound in regular play mode
        PlaySoundVol "gotfx-loltarget-hit" & DroppedTargets, VolDef
        SpinnerValue = SpinnerValue + (SpinnerAddValue * RndNbr(10) * SpinnerLevel)
    End If
    If DroppedTargets = 3 Then
        ' Target bank completed
        AddBonus 100000
        If PlayerMode = 0 Then LoLTargetsCompleted = LoLTargetsCompleted + 1
        ResetDropTargets
        If bLoLLit = False and bLoLUsed = False Then DoLordOfLight
        For i = 0 to 2
            'TODO: Revisit this to see whether LoL lights that are on solid still flash when bank is completed
            FlashForMs LoLLights(i),500,100,2
        Next
        If SpinnerLevel <= CompletedHouses Then SpinnerLevel = SpinnerLevel + 1 'TODO: Should SpinnerLevel still increase if in a Mode?
        House(CurrentPlayer).RegisterHit(Baratheon)
        If SelectedHouse = Baratheon And Not bMultiBallMode Then AdvanceWallMultiball 1
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
    If PlayerMode = 1 Then
        If HouseBattle1 > 0 Then House(CurrentPlayer).BattleState(HouseBattle1).RegisterTargetHit 1
        If HouseBattle2 > 0 Then House(CurrentPlayer).BattleState(HouseBattle2).RegisterTargetHit 1
    End If

    If (BWMultiballsCompleted = 0 or bWildfireTargets(t1)) And Not bMultiBallMode Then LightLock
    if bWildfireTargets(t1) Then
        'Target bank completed
        AddBonus 100000
        'Light both lights for 1 second, then shut them off
        debug.print "wf targets completed"
        FlashForMs li80,1000,1000,0
        FlashForMs li83,1000,1000,0
        ' Lights don't always seem to restore their state properly after flashing, so stick a timer on it
        li80.TimerInterval = 1100
        li80.TimerEnabled = True
        bWildfireTargets(0)=False:bWildfireTargets(1)=False
        If PlayerMode <> 1 Then House(CurrentPlayer).RegisterHit(Tyrell)
        bWildfireLit = True: SetLightColor li126, darkgreen, 1
    Else
        AddBonus 10000
        Select Case t
            Case 0
                SetLightColor li80,green,1
                FlashForMs li80,1000,100,2
            Case 1
                SetLightColor li83,green,1
                FlashForMs li83,1000,100,2
        End Select
    End If
    LastSwitchHit = "wftarget"&t
End Sub

'WF target light timer
Sub li80_Timer
    SetWildfireLights
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
    If BallsInLock = 2 And PlayerMode <> 1 Then
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
' Top Lane switches
'******************

Sub sw53_Hit
    TopLane_Hit 0
End Sub

Sub sw54_Hit
    TopLane_Hit 1
End Sub

Sub TopLane_Hit(sw)
    If Tilted Then Exit Sub
    if bTopLanes(sw) = False Then
        AddScore 1000
        AddBonus 5000
        bTopLanes(sw) = True
        'TODO: Play a sound when toplane is hit
        SetTopLaneLights    ' sub takes care of flashing them if they're both lit
        If bTopLanes(0) And bTopLanes(1) Then
            PlaySoundVol "gotfx-toplanes-complete",VolDef
            IncreaseBonusMultiplier 1
            If SelectedHouse = Lannister Then AddGold 225 Else AddGold 135
            bTopLanes(0) = False: bToplanes(1) = False
        End if
    Else
        AddScore 110
    End If
    LastSwitchHit = "toplane"
End Sub

'*******************
' Outlane Switches
'*******************

Sub sw3_Hit
    Outlane_Hit
End Sub

Sub sw4_Hit
    Outlane_Hit
End Sub

Sub Outlane_Hit
    If Tilted then Exit Sub
    AddScore 25000
    AddBonus 25000
    PlaySoundVol "gotfx-outlanelost",VolDef
    LastSwitchHit = "OutlaneSW"
    If bMultiBallMode Then Exit Sub
    If bBallSaverActive Then
        bEarlyEject = True
        CreateMultiballTimer.Interval = 100
        DoBallSaved 0
    Elseif bLoLLit Then
        bEarlyEject = True
        CreateMultiballTimer.Interval = 100
        DoBallSaved 1
        bLoLUsed = True
        SetOutlaneLights
    End If
End Sub

'*****************
' Ramp entrance switches
'*****************

' Left ramp
Sub sw38_Hit
    If Tilted then Exit Sub
    If PlayerMode = 1 Then PlaySoundVol "gotfx-ramphit1",VolDef/4 Else PlaySoundVol "gotfx-swordswoosh",VolDef
    LastSwitchHit = "sw38"
End Sub

' Right Ramp
Sub sw41_Hit
    If Tilted then Exit Sub
    If PlayerMode = 1 Then PlaySoundVol "gotfx-ramphit2",VolDef/4 Else PlaySoundVol "gotfx-swordswoosh",VolDef
    LastSwitchHit = "sw41"
End Sub

'******************
' 5 main shot hits
'******************
Sub LOrbitSW30_Hit
    If Tilted then Exit Sub
    AddScore 1000
    If LastSwitchHit = "sw30a" Then House(CurrentPlayer).RegisterHit(Greyjoy)
    'House(CurrentPlayer).RegisterHit(Greyjoy)
    LastSwitchHit = "LOrbitSW30"
End Sub

Sub sw30a_Hit
    LastSwitchHit = "sw30a"
End Sub

Sub sw30b_Hit
    LastSwitchHit = "sw30b"
End Sub
' Left ramp switch
Sub sw39_Hit
    If Tilted then Exit Sub
    AddScore 1000
    debug.print "left ramp hit"
    House(CurrentPlayer).RegisterHit(Lannister)
    
    LastSwitchHit = "sw39"
    sw48.UserValue = "sw39"
End Sub

'Right ramp switch
Sub sw42_Hit
    If Tilted then Exit Sub
    AddScore 1000
    House(CurrentPlayer).RegisterHit(Stark)
    LastSwitchHit = "sw42"
End Sub

Sub ROrbitsw31_Hit
    If Tilted then Exit Sub
    If LastSwitchHit <> "swPlungerRest" Then 
        AddScore 1000
        If LastSwitchHit <> "sw30b" And Not bJustPlunged Then House(CurrentPlayer).RegisterHit(Martell)
        'House(CurrentPlayer).RegisterHit(Martell)
    End If
    LastSwitchHit = "ROrbitsw31"
End Sub

' Right ramp drop target
Sub Target90_Dropped
    PlaySoundAt "fx_droptarget", Target90
    If Tilted Then Exit Sub
    AddScore 30
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

'*****************
' Elevator Kickers
'*****************
' kickerfloor - bottom of elevator
' kickerUPF - UpperPF level
' kickertopfloor - Iron Throne level
' kickerIT - kicker in Iron Throne

Sub KickerFloor_Hit
    Me.DestroyBall
    MoveDiverter(0)
    ' TODO Add logic for any other modes that kick the ball to the Iron Throne
    If ((bMysteryLit And PlayerMode = 0 And Not bMultiBallMode) or bEBisLit) And Not bJustPlunged Then
        vpmTimer.AddTimer 500,"ElevatorKick 2 '"
        If Not bMultiBallMode Then FreezeAllGameTimers
    Else
        bElevatorShotUsed = True
        bCastleShotAvailable = True
        vpmTimer.AddTimer 500,"ElevatorKick 1 '"
    End If
    SetTopGates
End Sub

Sub ElevatorKick(f)
    PlaySoundAt "fx_kicker",KickerFloor
    Select Case f
        Case 1
            KickerUPF.CreateBall
            KickerUPF.Kick 180,5
            PlaySoundVol "gotfx-elevatorupf",VolDef
            SetUPFFlashers 3,red
        Case 2
            KickerTopFloor.CreateBall
            KickerTopFloor.Kick 90,3
    End Select
End Sub

Sub KickerUPF_Hit
    KickerUPF.Kick 180,5
End Sub

' TODO Iron Throne Kicker modes - Extra Ball, Mystery selection, IT mode
Sub KickerIT_Hit
    Dim delay
    delay = 500
    If bEBisLit Then
        bEBisLit = False : setEBLight
        DoAwardExtraBall
        delay = 5000
    End If
    If bMysteryLit And PlayerMode = 0 And Not bMultiBallMode Then
        vpmTimer.AddTimer delay,"DoMysteryAward '"
    Else
        vpmTimer.AddTimer delay,"IronThroneKickout '"
    End If
End Sub

Sub IronThroneKickout
    PlaySoundAt "fx_kicker",KickerIT
    KickerIT.Kick 180,3
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
    debug.print "sw48_hit: got here1"
    If bLockIsLit Then
        FreezeAllGameTimers
        vpmtimer.addtimer 400, "LockBall '"     ' Slight delay to give ball time to settle
    ElseIf RealBallsInLock > 0 Then     ' Lock isn't lit but we have a ball locked
        debug.print "sw48_hit: releaselockedball"
        ReleaseLockedBall 0
    End If
    LastSwitchHit = "sw48"    
End Sub


'*************************
' Upper Playfield Switches
'*************************

'Castle loop
Sub sw79_Hit
    If Tilted then Exit Sub
    House(CurrentPlayer).RegisterUPFHit 1
End Sub

' Left target
Sub Target80_Hit
    If Tilted then Exit Sub
    House(CurrentPlayer).RegisterUPFHit 2
End Sub

'Left outlane
Sub sw77_Hit
    If Tilted then Exit Sub
    House(CurrentPlayer).RegisterUPFHit 3
End Sub

'Center target
Sub Target81_Hit
    If Tilted then Exit Sub
    House(CurrentPlayer).RegisterUPFHit 4
End Sub

' Right outlane
Sub sw78_Hit
    If Tilted then Exit Sub
    House(CurrentPlayer).RegisterUPFHit 5
End Sub

' Right target
Sub Target82_Hit
    If Tilted then Exit Sub
    House(CurrentPlayer).RegisterUPFHit 6
End Sub

' Left inlane
Sub sw83_Hit
    If Tilted then Exit Sub
    House(CurrentPlayer).RegisterUPFHit 7
End Sub

' Right inlane
Sub sw84_Hit
    If Tilted then Exit Sub
    House(CurrentPlayer).RegisterUPFHit 8
End Sub

' Left sling
' TODO: Add a sound?
Sub rlbandsw85_Hit
    If Tilted then Exit Sub
    AddScore 110
End Sub

' Right sling
Sub rlbandsw86_Hit
    If Tilted then Exit Sub
    AddScore 110
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
    House(CurrentPlayer).GoldHit(n)
    LastSwitchHit = "gold"&n
End Sub

' Left Inlane
Sub sw1_Hit
    If Tilted then Exit Sub
    AddScore 560
    'TODO Process inlane hit
    LastSwitchHit = "sw1"
End Sub

' Right Inlane
Sub sw2_Hit
    If Tilted then Exit Sub
    AddScore 560
    'TODO Process inlane hit
    LastSwitchHit = "sw2"
End Sub

' Battering Ram
Sub BatteringRam_Hit
    If Tilted Then Exit Sub
    Dim scene,line1,i
    AddScore 1130
    AddBonus 5000
    PlaySoundVol "gotfx-battering-ram",Voldef
    If bWildfireLit = 2 Then ' Mini-mode hit
        House(CurrentPlayer).AddWildfire 10
        If bUseFlexDMD And Not bBlackwaterSJPMode Then
            ' Do Scene for Wildfire Mini Mode
            Set scene = NewSceneWithVideo("wfmm","got-wildfiremode")
            scene.AddActor FlexDMD.NewLabel("ttl",FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbBlack, 0), _
                            CurrentWildfire&" TOTAL"&vbLf&"JACKPOT = "& House(CurrentPlayer).BWJackpot)
            scene.AddActor FlexDMD.NewLabel("obj",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite, vbBlack, 0),"+10 WILDFIRE")
            scene.GetLabel("obj").SetAlignedPosition 64,8,FlexDMD_Align_Center
            DelayActor scene.GetLabel("obj"),1,True
            scene.GetLabel("ttl").SetAlignedPosition 64,22,FlexDMD_Align_Center
            DelayActor scene.GetLabel("ttl"),1,True
            i = (Int(CurrentWildfire/10) MOD 2) + 1
            DMDEnqueueScene scene,1,1800,4000,1500,"gotfx-wildfiremini"&i
        End If
    ElseIf bWildfireLit = True And Not bMultiBallMode Then
        ' Start Wildfire Mini Mode
        SetGameTimer tmrWildfireMode,220    ' 22 second mode timer
        debug.print "starting wildfire minimode"
        li126.BlinkInterval = 100
        SetLightColor li126, darkgreen, 2
        If bUseFlexDMD And Not bBlackwaterSJPMode Then
            ' Do Scene for Wildfire Mini Mode
            Set scene = NewSceneWithVideo("wfmm","got-wildfiremode")
            scene.AddActor FlexDMD.NewLabel("mode",FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbBlack, 0),"WILDFIRE MINI-MODE")
            scene.AddActor FlexDMD.NewLabel("obj",FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbBlack, 0),"HIT BATTERING RAM"&vbLf&"TO COLLECT WILDFIRE")
            scene.GetLabel("mode").SetAlignedPosition 64,7,FlexDMD_Align_Center
            scene.GetLabel("obj").SetAlignedPosition 64,20,FlexDMD_Align_Center
            DelayActor scene.GetLabel("obj"),1,True
            DelayActor scene.GetLabel("mode"),1,True
            DMDEnqueueScene scene,1,1800,4000,1500,"gotfx-wildfireministart"
        End If
        bWildfireLit = 2
    End If
    If bBlackwaterSJPMode Then House(CurrentPlayer).ScoreSJP 0    'Super Jackpot!!

    'Playfield Multiplier support
    'PFMState:
    ' 0 - all lights off
    ' 1 - blue arrow flashing - timer active
    ' 2 - PFM light on solid
    ' 3 - PFM light flashing - timer active
    ' Hits advance state. A hit on state 3 awards PF multiplier. Timer resets state to 0
    Select Case PFMState
        Case 0
            If PlayfieldMultiplierVal < 3 Or (PlayfieldMultiplierVal < 3 + SwordsCollected And PlayfieldMultiplierVal < 5) Then
                SetGameTimer tmrPFMState,200    ' 20 seconds
                line1 = ""
            End If
        Case 1
            TimerFlags(tmrPFMState) = 0
            line1 = "LIGHT PLAYFIELD"&vbLf&"MULTIPLIER"
        Case 2
            SetGameTimer tmrPFMState,200    ' 20 seconds
            line1 = ""
        Case 3
            TimerFlags(tmrPFMState) = 0
            PlayfieldMultiplierVal = PlayfieldMultiplierVal + 1
            SetGameTimer tmrPFMultiplier,800-(PlayfieldMultiplierVal*100)
            SetPFMLights
            line1 = "+1 PLAYFIELD"&vbLf&"MULTIPLIER"
        Case Else
            ' Special case. When the PF Multiplier timer runs out, there's a short grace period where a single
            ' hit will restore it
            If PFMState > 3 Then
                PlayfieldMultiplierVal = PFMState - 2
                SetGameTimer tmrPFMultiplier,760-(PlayfieldMultiplierVal*80)
                SetPFMLights
                PFMState = 3
                line1 = ""
            End If
    End Select
    If PFMState <> 0 Or (PlayfieldMultiplierVal < 3 Or (PlayfieldMultiplierVal < 3 + SwordsCollected And PlayfieldMultiplierVal < 5) ) Then
        PFMState = PFMState + 1 : If PFMState = 4 Then PFMState = 0
        If Not bWildfireLit Then DoBatteringRamScene line1
    End If
    SetBatteringRamLights
End Sub

Sub DoBatteringRamScene(line1)
    Dim scene
    If bUseFlexDMD Then
        If line1 = "" Then
            Set scene = NewSceneWithVideo("pfmq","got-batteringram")
            DMDEnqueueScene scene,1,500,500,1000,""
        Else
            Set scene = NewSceneWithVideo("wfmm","got-wildfiremode")
            scene.AddActor FlexDMD.NewLabel("obj",FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbBlack, 0),line1)
            scene.GetLabel("obj").SetAlignedPosition 64,16,FlexDMD_Align_Center
            DelayActor scene.GetLabel("obj"),1,True
            DMDEnqueueScene scene,1,1800,4000,1500,"gotfx-wildfiremini"&PFMState/2
        End If
    Else
        If line1 <> "" Then 
            DisplayDMDText line1,"",2000
            PlaySoundVol "gotfx-wildfiremini"&PFMState/2,VolDef
        End If
    End If
End Sub

Sub WildfireModeTimer
    bWildfireLit = False
    SetLightColor li126, darkgreen, 0
    TimerFlags(tmrWildfireMode) = 0
    debug.print "Ending Wildfire Minimode"
End Sub

Sub PFMStateTimer
    PFMState = 0
    SetLightColor li132, darkblue, 0
    SetLightColor li123, amber, 0
End Sub

Sub PFMultiplierTimer
    PFMState = PlayfieldMultiplierVal + 2
    PlayfieldMultiplierVal = 1
    SetPFMLights
    vpmTimer.AddTimer 4000,"PFMState=0 '"
End Sub

Sub SetBatteringRamLights
    Select Case PFMState
        Case 2: SetLightColor li123, amber, 1
        Case 3: li123.BlinkInterval = 100 : SetLightColor li123, amber, 2
        Case Else: li123.State = 0
    End Select
    If (PFMState MOD 2) = 1 Or bWildfireLit <> 0 Or bBlackwaterSJPMode Then 
        SetLightColor li132,midblue,2
    Else
        SetLightColor li132,midblue,0
    End If
    If bBlackwaterSJPMode Then 
        li132.BlinkInterval = 66
        li129.BlinkInterval = 66
        SetLightColor li129,red,2
    Else 
        li132.BlinkInterval = 100
        li129.State = 0
    End If
End Sub

Sub Spinner001_Spin
    If Tilted then Exit Sub
    Dim spinval
    Me.TimerEnabled = False
    Me.TimerInterval = 1000
    Me.TimerEnabled  = True
    If PlayerMode = 1 and (HouseBattle1 = Baratheon or HouseBattle2 = Baratheon) Then
        House(CurrentPlayer).BattleState(HouseBattle1).RegisterSpinnerHit
        House(CurrentPlayer).BattleState(HouseBattle2).RegisterSpinnerHit
        AccumulatedSpinnerValue = 1 ' Ensure a new scene isn't created for each spin hit
        Exit Sub
    End If
    spinval = SpinnerValue * (2^(SpinnerLevel-1))
    AccumulatedSpinnerValue = AccumulatedSpinnerValue + spinval
    AddScore spinval
    DMDSpinnerScene spinval
    PlaySoundVol "gotfx-drum"&SpinnerLevel,VolDef/4
End Sub

Sub Spinner001_Timer: AccumulatedSpinnerValue = 0: End Sub

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


'*************************
' Mystery Award
'******************

Dim MysteryAwards(29)
Dim MysteryVals(2)
Dim MysterySelected

MysteryAwards(0) = ARRAY("KEEP YOUR"&vbLf&"GOLD",0)
MysteryAwards(1) = Array(1,120)
MysteryAwards(2) = Array("LIGHT A"&vbLf&"HOUSE",140)
MysteryAwards(3) = Array("+1 BONUS X",160)
MysteryAwards(4) = Array("GROW"&vbLf&"WALL"&vbLf&"JACKPOT",190)
MysteryAwards(5) = Array("LIGHT"&vbLf&"WILDFIRE",220)
MysteryAwards(6) = Array("LIGHT"&vbLf&"LOCK",250)
MysteryAwards(7) = Array("+5"&vbLf&"WILDFIRE",270)
MysteryAwards(8) = Array("LIGHT"&vbLf&"SWORDS",320)
MysteryAwards(9) = Array("LIGHT PF"&vbLf&"MULTIPLY",420)
MysteryAwards(10) = Array("COLLECT"&vbLf&"SWORD",620)
MysteryAwards(11) = Array("ADVANCE"&vbLf&"CASTLE"&vbLf&"MULTIBALL",830)
MysteryAwards(12) = Array("ADVANCE"&vbLf&"WALL"&vbLf&"MULTIBALL",1130)
MysteryAwards(13) = Array("LIGHT 1X"&vbLf&"SUPER"&vbLf&"JACKPOT",1130)
MysteryAwards(14) = Array("+2 BONUS X",1430)
MysteryAwards(15) = Array("+10"&vbLf&"WILDFIRE",1880)
MysteryAwards(16) = Array("START"&vbLf&"WINTER"&vbLf&"IS COMING",2030)
MysteryAwards(17) = Array("+2 CASTLE"&vbLf&"MULTIBALL",2330)
MysteryAwards(18) = Array(5,2600)
MysteryAwards(19) = Array("+3 BONUS X",2970)
MysteryAwards(20) = Array("LIGHT"&vbLf&"LORD OF"&vbLf&"LIGHT",3530)
MysteryAwards(21) = Array("BARATHEON"&vbLf&"BUTTON"&vbLf&"ABILITY",3800)
MysteryAwards(22) = Array("MARTELL"&vbLf&"BUTTON"&vbLf&"ABILITY",3800)
MysteryAwards(23) = Array("LANNISTER"&vbLf&"BUTTON"&vbLf&"ABILITY",3800)
MysteryAwards(24) = Array("LIGHT 2X"&vbLf&"SUPER"&vbLf&"JACKPOT",3920)
MysteryAwards(25) = Array("HOLD"&vbLf&"BONUS",4200)
MysteryAwards(26) = Array("LIGHT"&vbLf&"EXTRA"&vbLf&"BALL",4500)
MysteryAwards(27) = Array("LIGHT 3X"&vbLf&"SUPER"&vbLf&"JACKPOT",4750)
MysteryAwards(28) = Array(25,6000)
MysteryAwards(29) = Array("SPECIAL",10000)

' Choose 2 "random" mysteries from the array. One will use a moderate amount of their gold, the other will use as much as possible. 
' The third (First) option is option 0 - keep gold
' Player uses flipper buttons to choose and action button to select
' Start 3 timers. One fires after a few seconds and says "Choose!", one fires with 5 seconds left and says "choose now!"
' Last timer fires after 20? seconds and chooses whatever is selected   

Sub DoMysteryAward
    Dim i
    MysteryVals(0) = 0
    For i = 1 to 29
        If MysteryAwards(i)(1) < CurrentGold Then MysteryVals(2) = i
    Next
    Do
        i = RndNbr(29)
    Loop Until MysteryAwards(i)(1) < CurrentGold/2 Or (MysteryAwards(i)(1) < CurrentGold And CurrentGold < 300 And i <> MysteryVals(2))
    MysteryVals(1) = i
    bMysteryAwardActive = True
    MysterySelected = 0
    i = RndNbr(5)
    MATstep = 0
    PlaySoundVol "say-make-your-choice"&i,VolDef
    SetGameTimer tmrMysteryAward,10
    PlayModeSong

    DMDMysteryAwardScene
End Sub

Dim MATstep
Sub MysteryAwardTimer
    Dim i,j,snd
    snd = "":i=1
    MATstep = MATstep + 1
    If MATstep=6 And MysterySelected = 0 Then snd="say-make-your-choice-quickly":i=6
    If MATstep=10 And MysterySelected = 0 Then snd="say-gold-is-always-useful":i=2
    j = RndNbr(i)
    If snd <> "" Then PlaySoundVol snd&j,VolDef
    If bUseFlexDMD Then
        FlexDMD.LockRenderThread
        MysteryScene.GetLabel("tmr").Text = CStr(10-MATstep)
        FlexDMD.UnlockRenderThread
    End If
    If MATstep = 10 Then
        SelectMysteryAward
    Else
        SetGameTimer tmrMysteryAward,10
    End If
End Sub

Sub UpdateMysteryAward(keycode)
    If keycode = RightMagnaSave or keycode = LockBarKey or _  
			(keycode = PlungerKey and bUsePlungerForSternKey) Then SelectMysteryAward
    If keycode = LeftFlipperKey Then
        MysterySelected = MysterySelected - 1
        If MysterySelected < 0 Then MysterySelected = 2
        PlaySoundVol "gotfx-mysteryleft",VolDef/4
        DMDMysteryAwardScene
    ElseIf keycode = RightFlipperKey Then
        MysterySelected = MysterySelected + 1
        If MysterySelected > 2 Then MysterySelected = 0
        PlaySoundVol "gotfx-mysteryright",VolDef/4
        DMDMysteryAwardScene
    End If
End Sub

Sub SelectMysteryAward
    Dim i
    bMysteryAwardActive = False
    bMysteryLit = False : SetMysteryLight
    DMDMysteryAwardScene
    TimerFlags(tmrMysteryAward) = 0
    PlaySoundVol "gotfx-mysteryselect",VolDef
    Select Case MysteryVals(MysterySelected)
        Case 0: 'keep gold
        Case 1
            AddScore 1000000
            DMD "BIG POINTS",FormatScore(1000000*PlayfieldMultiplierVal),"",eNone,eNone,eNone,1000,True,""
        Case 2  ' light a house
            For i = 1 to 7
                If Not House(CurrentPlayer).Qualified(i) Then Exit For
            Next
            House(CurrentPlayer).Qualified(i) = True
            House(CurrentPlayer).ResetLights
            ' TODO: Better animation for this
            DMD "",HouseToUCString(i)&" IS LIT","",eNone,eNone,eNone,1000,True,""
        Case 3: IncreaseBonusMultiplier 1  ' +1X
        Case 4: IncreaseWallJackpot
        Case 5: bWildfireLit = True: SetLightColor li126, darkgreen, 1 ' TODO: This has a scene
        Case 6: LightLock
        Case 7: TotalWildfire = TotalWildfire + 5: House(CurrentPlayer).AddWildfire 5  ' Increase wildfire. TODO: Should play a scene
        Case 8: bSwordLit = True: SetSwordLight  ' Light Swords. TODO: Play a scene
        Case 9: PFMState = 2 : SetBatteringRamLights : DoBatteringRamScene "LIGHT PLAYFIELD"&vbLf&"MULTIPLIER"
        Case 10: DoAwardSword
        Case 11: House(CurrentPlayer).IncreaseUPFLevel
        Case 12: AdvanceWallMultiball 1
        Case 13,24,27: 'TODO: Light 1X Super JP
        Case 14: IncreaseBonusMultiplier 2
        Case 15: TotalWildfire = TotalWildfire + 10: House(CurrentPlayer).AddWildfire 10 ' Increase wildfire. TODO: Should play a scene
        Case 16: 'TODO Start a WiC HurryUp
        Case 17: House(CurrentPlayer).IncreaseUPFLevel : House(CurrentPlayer).IncreaseUPFLevel  ' TODO: Allow method to take an argument 
        Case 18
            AddScore 5000000
            DMD "BIGGER POINTS",FormatScore(5000000*PlayfieldMultiplierVal),"",eNone,eNone,eNone,1000,True,""
        Case 19: IncreaseBonusMultiplier 3
        Case 20: DoLordOfLight
        Case 21,22,23: 'TODO: Add house's button ability
        Case 25: 'TODO: Bonus Hold
        Case 26: DoEBisLit
        Case 28
            AddScore 25000000
            DMD "BIGGER POINTS",FormatScore(25000000*PlayfieldMultiplierVal),"",eNone,eNone,eNone,1000,True,""
        Case 29: AwardSpecial
    End Select
    vpmTimer.AddTimer 500,"IronThroneKickout '"
    PlayModeSong
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
PictoPops(6) = Array("INCREASE"&vbLf&"WALL"&vbLf&"JACKPOT","+POT",50,0) ''Battle for Wall Value Increases. Value=xxx'
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
        Case 1: IncreaseBonusMultiplier 1
        Case 2      ' Increase wildfire. TODO: Should play a scene
            TotalWildfire = TotalWildfire + 5: House(CurrentPlayer).AddWildfire 5
        Case 3      ' Increase Gold
            If SelectedHouse = Lannister Then AddGold 250 Else AddGold 150
        Case 4      ' Light Swords. TODO: Play a scene
            bSwordLit = True: SetSwordLight
        Case 5      ' Increase Winter Is Coming value
            IncreaseWinterIsComing
        Case 6      ''Battle for Wall Value Increases. Value=xxx'
            IncreaseWallJackpot
        Case 7: LightLock
        Case 8
            AddScore 1000000
            DMD "BIG POINTS",FormatScore(1000000*PlayfieldMultiplierVal),"",eNone,eNone,eNone,1000,True,""
        Case 9: IncreaseBonusMultiplier 3
        Case 10     ' Add Time (to mode or Hurry Up)
            If PlayerMode = 1 Then
                If HouseBattle1 > 0 Then House(CurrentPlayer).BattleState(HouseBattle1).AddTime 10
                If HouseBattle2 > 0 Then House(CurrentPlayer).BattleState(HouseBattle2).AddTime 10
            ElseIf bHurryUpActive Then
                HurryUpValue = HurryUpValue + (HurryUpChange * 50)
                'TODO: pLay an "Add Time" scene with two hourglasses
            End if
        Case 11
            If bMultiBallMode Then
                AddMultiballFast 1
                DMD "","ADD A BALL","",eNone,eNone,eNone,1000,True,""
                EnableBallSaver 7
            End If
        Case 12: AdvanceWallMultiball 1
        Case 13: DoEBisLit
        Case 14: DoLordOfLight
        Case 15
            bMysteryLit = True : SetMystery
        Case 16
            ' TODO: This has a scene
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
            CheckPictoAward = Not bWildfireLit And Not bMultiBallMode
    End Select
End Function

' Set new random values on the Pictopops. Ensure at least one is different
Sub ResetPictoPops
    Dim i
    Do
        For i = 0 to 2:GeneratePictoAward i: Next
    Loop While BumperVals(0) = BumperVals(1) And BumperVals(0) = BumperVals(2)
End Sub

Dim bBattleCreateBall
Sub LockBall
    Dim i,scene,g
    BallsInLock = BallsInLock + 1
    RealBallsInLock = RealBallsInLock + 1
    debug.print "Locked ball " & BallsInLock
    bLockIsLit = False
    SetLightColor li111,darkgreen,0     ' Turn off Lock light
    If SelectedHouse = Lannister Then g = 250 Else g = 75
    TotalGold = TotalGold + g
    CurrentGold = CurrentGold + g
    TotalWildfire = TotalWildfire + 5 
    House(CurrentPlayer).AddWildfire 5
    i = RndNbr(3)
    if i > 1 Then i = ""
    PlaySoundVol "say-ball-" & BallsInLock & "-locked" & i, VolDef
    If BallsInLock = 3 Then
        'Start BW multiball in 1 second - gives a chance to say 'ball locked'
        vpmtimer.addtimer 1600, "StartBWMultiball '"
    ElseIf PlayerMode >= 0 Then  ' Regular mode - release new ball
        If RealBallsInLock > BallsInLock Then
            RealBallsInLock = RealBallsInLock - 1
            ReleaseLockedBall 0
        Else
            bAutoPlunger = True
            bPlayfieldValidated = False
            CreateNewBall
        End If
    Else ' battle mode selection and not all balls locked - let PreLaunchBattleMode take care of releasing a ball
        bBattleCreateBall = True
    End If
    If BallsInLock < 3 Then
        DoLockBallSeq
        If bUseFlexDMD Then
            Set scene = NewSceneWithImage("lock","got-balllock")
            scene.AddActor FlexDMD.NewLabel("lbl1",FlexDMD.NewFont("udmd-f6by8.fnt",vbWhite, vbWhite, 0) ,"BLACKWATER")
            scene.GetLabel("lbl1").SetAlignedPosition 2,1,FlexDMD_Align_TopLeft
            scene.AddActor FlexDMD.NewLabel("lbl2",FlexDMD.NewFont("udmd-f6by8.fnt",vbWhite, vbWhite, 0) ,"BALL "&BallsInLock&" LOCKED")
            scene.GetLabel("lbl2").SetAlignedPosition 2,10,FlexDMD_Align_TopLeft
            BlinkActor scene.GetLabel("lbl2"),100,7
            scene.AddActor FlexDMD.NewLabel("wf", FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0) ,"+5 WILDFIRE")
            scene.GetLabel("wf").SetAlignedPosition 2,25,FlexDMD_Align_BottomLeft
            scene.AddActor FlexDMD.NewLabel("gold", FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0) ,"+"&g&" GOLD")
            scene.GetLabel("gold").SetAlignedPosition 2,31,FlexDMD_Align_BottomLeft
            DMDEnqueueScene scene,0,1000,1500,500,""
        End If
    End If
End Sub

Sub StartBWMultiball
    bMultiBallMode = True
    WildfireModeTimer   ' Stop Wildfire Minimode if it happened to be running
    bWildfireLit = False : SetWildfireLights
    BlackwaterScore = 0
    Dim scene
    If bUseFlexDMD Then
        Set scene = NewSceneWithVideo("bwmb","got-blackwatermb")
        scene.AddActor FlexDMD.NewLabel("balllock", FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0) ,"BALL 3"&vbLf&"LOCKED")
        scene.GetLabel("balllock").SetAlignedPosition 126,30,FlexDMD_Align_BottomRight
        BlinkActor scene.GetLabel("balllock"),0.1,12
        DMDEnqueueScene scene,0,2000,5000,500,"gotfx-blackwater-multiball-start"
    Else
        PlaySoundVol "gotfx-blackwater-multiball-start",VolDef
    End If
    PlayModeSong
    DoBWMultiballSeq
  	tmrBWmultiballRelease.Interval = 5000	' Long initial delay to give sequence time to complete
    tmrBWmultiballRelease.Enabled = True
    bBWMultiballActive = True
    House(CurrentPlayer).SetBWJackpots
    DMDCreateBWMBScoreScene
    EnableBallSaver 25  ' 20 seconds plus the 5 second delay before MB starts
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
        If (TimerFlags(i) AND 2) = 2 And i > 5 Then ' Timers 1 - 5 can't be frozen. 
            TimerTimestamp(i) = TimerTimestamp(i) + 1 ' "Frozen" timer - increase its expiry by 1 step
        ElseIf (TimerFlags(i) AND 1) = 1 Then 
            bGameTimersEnabled = True
            If TimerTimestamp(i) <= GameTimeStamp Then
                TimerFlags(i) = TimerFlags(i) AND 254   ' Set bit0 to 0: Disable timer
                Execute(TimerSubroutine(i))
            End If
        End if
    Next
End Sub

Sub SetGameTimer(tmr,val)
    TimerTimestamp(tmr) = GameTimeStamp + val
    TimerFlags(tmr) = TimerFlags(tmr) or 1
    bGameTimersEnabled = True
End Sub

Sub StopGameTimers
    Dim i
    For i = 1 to MaxTimers:TimerFlags(i) = TimerFlags(i) And 254: Next
End Sub

' Freeze all timers, including ball saver timers
' This should only be called when no balls are in play - i.e. the only "live" ball is held somewhere
Dim bAllGameTimersFrozen
Sub FreezeAllGameTimers
    Dim i
    For i = 1 to MaxTimers
        TimerFlags(i) = TimerFlags(i) Or 2
    Next
    bAllGameTimersFrozen = True
End Sub

Sub ThawAllGameTimers
    Dim i
    If bAllGameTimersFrozen = False Then Exit Sub
    For i = 1 to MaxTimers
        TimerFlags(i) = TimerFlags(i) And 253
    Next
    ' If mode timers are running, set up a mode pause timer that will pause them 2 seconds from now
    ' This timer is reset every time this sub is called (i.e. every time there's a scoring event)
    If (TimerFlags(tmrBattleMode1) And 1) > 0 Or (TimerFlags(tmrBattleMode2) And 1) > 0 Then SetGameTimer tmrModePause,20
End Sub

Sub MartellBattleTimer
    Dim h
    If HouseBattle2 = Martell Then h = HouseBattle2 else h = HouseBattle1
    House(CurrentPlayer).BattleState(h).MartellTimer
End Sub

Sub BattleModeTimer1
    House(CurrentPlayer).BattleState(HouseBattle1).BattleTimerExpired
End Sub

Sub BattleModeTimer2
    House(CurrentPlayer).BattleState(HouseBattle2).BattleTimerExpired

End Sub

Sub ModePauseTimer
    If (TimerFlags(tmrBattleMode1) And 1) > 0 Then TimerFlags(tmrBattleMode1) = TimerFlags(tmrBattleMode1) Or 2
    If (TimerFlags(tmrBattleMode2) And 1) > 0 Then TimerFlags(tmrBattleMode2) = TimerFlags(tmrBattleMode2) Or 2
    If (TimerFlags(tmrMartellBattle) And 1) > 0 Then TimerFlags(tmrMartellBattle) = TimerFlags(tmrMartellBattle) Or 2
End Sub

Sub BlackwaterSJPTimer
    TimerFlags(tmrBlackwaterSJP) = 0
    bBlackwaterSJPMode = False
    SetBatteringRamLights
    If bBWMultiballActive Then House(CurrentPlayer).IncreaseBWJackpotLevel
End Sub

Sub UPFMultiplierTimer
    House(CurrentPlayer).ResetUPFMultiplier
End Sub

Sub tmrBattleCompleteScene_Timer
    tmrBattleCompleteScene.Enabled = 0
    If tmrBattleCompleteScene.UserValue > 0 Then House(CurrentPlayer).BattleState(tmrBattleCompleteScene.UserValue).DoBattleCompleteScene
    tmrBattleCompleteScene.UserValue = 0
End Sub

'*********************
' HurryUp Support
'*********************

' Called every 200ms by the GameTimer to update the HurryUp value
Sub HurryUpTimer
    Dim lbl
    If bHurryUpActive Then HurryUpCounter = HurryUpCounter + 1
    If bTGHurryUpActive Then TGHurryUpCounter = TGHurryUpCounter + 1
    If bUseFlexDMD Then
        If bHurryUpActive And Not IsEmpty(HurryUpScene) Then
            If Not (HurryUpScene is Nothing) Then
                Set lbl = HurryUpScene.GetLabel("HurryUp")
                If Not lbl is Nothing Then
                    FlexDMD.LockRenderThread
                    lbl.Text = FormatScore(HurryUpValue)
                    FlexDMD.UnlockRenderThread
                End If
            End if
        End If
        If bTGHurryUpActive And Not IsEmpty(TGHurryUpScene) Then
            If Not (TGHurryUpScene is Nothing) Then
                Set lbl = TGHurryUpScene.GetLabel("TGHurryUp")
                If Not lbl is Nothing Then
                    FlexDMD.LockRenderThread
                    lbl.Text = FormatScore(TGHurryUpValue)
                    FlexDMD.UnlockRenderThread
                End If
            End if
        End If
    Else
        'TODO Update regular DMD with hurryUp value
    End if
    if bHurryUpActive And HurryUpCounter > HurryUpGrace Then 
        HurryUpValue = HurryUpValue - HurryUpChange
        If HurryUpValue <= 0 Then HurryUpValue = 0 : EndHurryUp
    End If
    if bTGHurryUpActive And TGHurryUpCounter > TGHurryUpGrace Then 
        TGHurryUpValue = TGHurryUpValue - TGHurryUpChange
        If TGHurryUpValue <= 0 Then TGHurryUpValue = 0 : EndTGHurryUp
    End If
    If bTGHurryUpActive or bHurryUpActive Then SetGameTimer tmrHurryUp,2
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
    If bUseFlexDMD Then
        Set HurryUpScene = scene
    Else
        'TODO: Display hurryUp on regular DMD in place of score
    End If
    HurryUpGrace = grace
    HurryUpValue = value
    HurryUpCounter = 0
    HurryUpChange = Int(HurryUpValue / 1033.32) * 10
    bHurryUpActive = True
    SetGameTimer tmrHurryUp,2
End Sub

' Called when the HurryUp runs down. Ends battle mode if running
Sub EndHurryUp
    StopHurryUp
    If PlayerMode = 1 Then
        If HouseBattle1 > 0 Then House(CurrentPlayer).BattleState(HouseBattle1).BEndHurryUp
        If HouseBattle2 > 0 Then House(CurrentPlayer).BattleState(HouseBattle2).BEndHurryUp
    End if
End Sub

' Called when the HurryUp has been scored. Ends the HurryUp but doesn't end the battle (if applicable)
Sub StopHurryUp
    Dim lbl
    bHurryUpActive = False
    if Not bTGHurryUpActive Then TimerFlags(tmrHurryUp) = TimerFlags(tmrHurryUp) And 254
    If PlayerMode = 2 Then
        PlayerMode = 0
        tmrWiCLightning.Enabled = False
        GiIntensity 1
        SetPlayfieldLights
        DMDResetScoreScene
        DMDFlush
        AddScore 0
    End If
    if bUseFlexDMD Then
        If Not IsEmpty(HurryUpScene) Then
            If Not (HurryUpScene is Nothing) Then 
                Set lbl = HurryUpScene.GetLabel("HurryUp")
                If Not lbl is Nothing Then
                    FlexDMD.LockRenderThread
                    lbl.Visible = False
                    FlexDMD.UnlockRenderThread
                End if
            End If
        End if
    Else
        'TODO Set DMD back to regular score
    End if
End Sub

'Targaryen-specific HurryUp - allows it to co-exist with another HurryUp
Sub StartTGHurryUp(value,scene,grace)
    if bTGHurryUpActive Then
        debug.print "HurryUp already active! Can't have two!"
        Exit Sub
    End If
    If bUseFlexDMD Then
        Set TGHurryUpScene = scene
    Else
        'TODO: Display hurryUp on regular DMD in place of score
    End If
    TGHurryUpGrace = grace
    TGHurryUpValue = value
    TGHurryUpCounter = 0
    TGHurryUpChange = Int(TGHurryUpValue / 1033.32) * 10
    bTGHurryUpActive = True
    SetGameTimer tmrHurryUp,2
End Sub

' Called when the HurryUp runs down. Ends battle mode if running
Sub EndTGHurryUp
    StopTGHurryUp
    If PlayerMode = 1 Then
        If HouseBattle1 = Targaryen Then House(CurrentPlayer).BattleState(Targaryen).BEndHurryUp
        If HouseBattle2 = Targaryen Then House(CurrentPlayer).BattleState(Targaryen).BEndHurryUp 
    End if
End Sub

' Called when the HurryUp has been scored. Ends the HurryUp but doesn't end the battle (if applicable)
Sub StopTGHurryUp
    Dim lbl
    bTGHurryUpActive = False
    if Not bHurryUpActive Then TimerFlags(tmrHurryUp) = TimerFlags(tmrHurryUp) And 254
    if bUseFlexDMD Then
        If Not IsEmpty(TGHurryUpScene) Then
            If Not (TGHurryUpScene is Nothing) Then 
                Set lbl = TGHurryUpScene.GetLabel("TGHurryUp")
                If Not lbl is Nothing Then
                    FlexDMD.LockRenderThread
                    lbl.Visible = False
                    FlexDMD.UnlockRenderThread
                End if
            End If
        End if
    Else
        'TODO Set DMD back to regular score
    End if
End Sub

' Start the Winter Is Coming HurryUp
' All playfield lights turn off except flashing shot
' Hurry Up starts, wind blows, "lightning" flashes
Dim WICHurryUpScene
Sub StartWICHurryUp(value,shot)
    PlayerMode = 2
    SetPlayfieldLights
    If bUseFlexDMD Then
        Set WICHurryUpScene = NewSceneWithVideo("wic","got-wichurryup")
        WICHurryUpScene.AddActor FlexDMD.NewLabel("HurryUp",FlexDMD.NewFont("udmd-f6by8.fnt",vbWhite,vbWhite,0),"")
        WICHurryUpScene.GetLabel("HurryUp").SetAlignedPosition 4,21,FlexDMD_Align_TopLeft
    End if
    DMDFlush
    DMDEnqueueScene WICHurryUpScene,0,4000,6000,500,""
    DMDSetAlternateScoreScene WICHurryUpScene,16
    StartHurryUp value,WICHurryUpScene,10
    PlayModeSong
    tmrWiCLightning.Interval = 50
    tmrWiCLightning.Enabled = True
End Sub

Sub tmrWiCLightning_Timer
    Dim step,i
    tmrWiCLightning.Enabled = False
    step = tmrWiCLightning.UserValue
    If step > 7 then step = 0
    Select Case step
        Case 0,1,3: i = 0
        Case 2,5: i = 0.05
        Case 4: i = 4
        Case 6,7: i = 0.15
    End Select
    GiIntensity i
    step = step + 1
    tmrWiCLightning.UserValue = step
    tmrWiCLightning.Enabled = true
End Sub

Sub IncreaseWinterIsComing
    'TODO Handle Winter Is Coming increase (likely move inside House Class)
    ' Play sound & animation
End Sub

Sub IncreaseWallJackpot
    If WallJPValue < 1500000 Then WallJPValue = WallJPValue + 3000000 Else WallJPValue = WallJPValue + 500000 + RndNbr(100)*5000
    DMDPlayHitScene "got-increasewalljp","gotfx-increasewalljp",1000,"BATTLE FOR WALL INCREASES","VALUE="&FormatScore(WallJPValue),"",0,3
End Sub

Sub AdvanceWallMultiball(n)
    'Countdown to Wall Multiball
    ' Play rotating clock animation based on where we're at
    ' If we're at Zero then
    Dim start,num,scene
    If bWallMBReady Then Exit Sub
    
    If WallMBCompleted > 0 Then Start=0 Else Start=220
    Start = Start + WallMBLevel*20
    If Start = 0 Then Start = 1
    num = n*20 + 1

    WallMBLevel = WallMBLevel + n

    If WallMBLevel >= 11 Or (WallMBCompleted = 0 And WallMBLevel >= 6 ) Then
        bWallMBReady = True
        ' TODO: Which shot starts Wall MB?
    End If

    if bUseFlexDMD Then
        Set scene = NewSceneFromImageSequenceRange("clock","wallclock",start,num,25,0,1)
        DMDEnqueueScene scene,1,800*n+400,800*n+400,3000,"gotfx-wallcountdown"
    Else
        DisplayDMDText "WALL MULTIBALL","LEVEL "&WallMBLevel,1000
        PlaySoundVol,"gotfx-wallcountdown"
    End If
End Sub

Sub AwardSpecial
    'TODO Play Special animation and sound
    ' Knock Knocker
End Sub

Sub DoLordOfLight
    Dim Scene
    If bUseFlexDMD Then
        Set Scene = FlexDMD.NewGroup("lol")
        Scene.AddActor FlexDMD.NewLabel("txt",FlexDMD.NewFont("udmd-f3by7.fnt",vbWhite,vbWhite,0),"LORD OF LIGHT"&vbLf&"OUTLANE BALL-SAVE LIT")
        Scene.GetLabel("txt").SetAlignedPosition 64,16,FlexDMD_Align_Center
        DMDEnqueueScene Scene,2,750,750,1500,"gotx-lolsave"
    Else
        'TODO LoL display without FlexDMD
        PlaySoundVol "gotfx-lolsave",VolDef
    End If
    bLoLLit = True
    SetOutlaneLights
End Sub

Sub DoAwardSword
    Dim scene,font,i,j
    bSwordLit = False : SetSwordLight
    If SwordsCollected = 8 then Exit Sub    ' SHOULD never happen
    PlaySoundVol "gotfx-swordaward",VolDef
    SwordsCollected = SwordsCollected + 1
    Do
        i = RndNbr(8)-1
    Loop While (SwordMask And (2^i)) > 0
    SwordMask = SwordMask Or (2^i)
    j = RndNbr(1000)*10000+500000   ' TODO: Better way to calculate sword score??
    AddScore j
    If bUseFlexDMD Then
        Set scene = NewSceneWithVideo("sword","got-swordawarded")
        Set font = FlexDMD.NewFont("udmd-f6by8.fnt",vbWhite,vbWhite,0)
        scene.AddActor FlexDMD.NewLabel("swname",font,SwordNames(i))   
        scene.AddActor FlexDMD.NewLabel("score",font,FormatScore(j))
        scene.GetLabel("swname").SetAlignedPosition 120,2,FlexDMD_Align_TopRight
        scene.GetLabel("score").SetAlignedPosition 80,26,FlexDMD_Align_Center
        DMDEnqueueScene scene,0,1500,2500,1000,"say-sword"&i
    Else
        PlaySoundVol "say-sword"&i,VolDef
        DisplayDMDText SwordNames(i),FormatScore(j),1000
    End if
End Sub

Sub DoEBisLit
    Dim scene,i
    If bEBisLit Then Exit Sub
    bEBisLit = True:SetEBLight
    i = RndNbr(2)
    PlaySoundVol "say-extra-ball-is-lit"&i,VolDef
    If bUseFlexDMD Then
        Set scene = NewSceneWithVideo("ebislit","got-ebislit")
        DMDEnqueueScene scene,2,1400,1400,1500,""
    Else
        DisplayDMDText "EXTRA BALL","IS LIT",1000
    End If
End Sub

Sub DoAwardExtraBall
    Dim scene
    PlaySoundVol "say-extra-ball",VolDef
    If bUseFlexDMD Then
        Set scene = NewSceneWithVideo("eb","got-extraball")
        DMDEnqueueScene scene,0,5500,7500,2500,""
    Else
        DisplayDMDText "","EXTRA BALL",1000
    End if
End Sub

Sub DMDDoWiCScene(value,shots)
    Dim scene,line3,i
    If bUseFlexDMD Then
        Set scene = NewSceneWithVideo("wic","got-winterstorm")
        If shots = 1 Then line3 = "2 MORE SHOTS" Else line3 = "1 MORE SHOT"
        scene.AddActor FlexDMD.NewLabel("txt1",FlexDMD.NewFont("udmd-f3by7.fnt",vbWhite,vbWhite,0),"WINTER IS COMING"&vbLf&"VALUE GROWS")
        scene.AddActor FlexDMD.NewLabel("txt2",FlexDMD.NewFont("udmd-f6by8.fnt",vbWhite,vbWhite,0),FormatScore(value))
        scene.AddActor FlexDMD.NewLabel("txt3",FlexDMD.NewFont("tiny3by5.fnt",vbWhite,vbWhite,0),line3)
        scene.GetLabel("txt1").SetAlignedPosition 64,0,FlexDMD_Align_Top
        scene.GetLabel("txt2").SetAlignedPosition 64,16,FlexDMD_Align_Top
        scene.GetLabel("txt3").SetAlignedPosition 64,25,FlexDMD_Align_Top
        DMDEnqueueScene scene,1,1000,1200,2000,"gotfx-wind-blowing"
    Else
        DisplayDMDText "WIC VALUE GROWS",value,1000
        PlaySoundVol "gotfx-wind-blowing",VolDef
    End if
    If shots = 2 then
        i = RndNbr(3)
        PlaySoundVol "say-winter-is-coming"&i,VolDef
    End If
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
    Dim i,j,tmrval,done
    HouseBattle1 = Empty
    HouseBattle2 = Empty

    PlayerMode = -2

    TurnOffPlayfieldLights
    
    DMDChooseBattleScene "","","",10

    ' Check to see if there are any unlit houses. If not, "Pass For Now" is not allowed
    done = True
    For i = 1 to 7
        If House(CurrentPlayer).Qualified(i) = False And House(CurrentPlayer).Completed(i) = False  Then done = False
    Next
    if Not done Then 
        BattleChoices(0) = 0:TotalBattleChoices = 1 ' Pass For Now is allowed
    Else
        TotalBattleChoices = 0
    End if

    ' Create the array of choices
    For i = 0 to 7
        If (SelectedHouse <> Greyjoy And House(CurrentPlayer).Qualified(i)) or i = 0 then   ' Greyjoy can't stack house battles
            For j = 1 to 7
                If House(CurrentPlayer).Qualified(j) And House(CurrentPlayer).Completed(j) = False And j<>i Then
                    If i=0 Then  BattleChoices(TotalBattleChoices) = j*8 Else BattleChoices(TotalBattleChoices) = i*8+j
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

    ' Disable BattleReady for next time
    House(CurrentPlayer).BattleReady = False

    If bBattleInstructionsDone Then
        UpdateChooseBattle
    Else    
        ' Set up the update timer to update after instructions have been displayed for 1.5 seconds
        vpmTimer.AddTimer 1500, "UpdateChooseBattle() '"
        bBattleInstructionsDone = True
    End If
    PlayModeSong
End Sub

' UpdateChooseBattle
' Set House string values based on the currently selected BattleChoice
' Update timers
' Update DMD

Sub UpdateChooseBattle
    Dim house1, house2, tmr, i

    ' Just in case we got called by accident
    If PlayerMode <> -2 Then
        TimerFlags(tmrUpdateChooseBattle) = 0
        Exit Sub
    End if

    ' Enable the game timer to call this sub again in 1 second
    SetGameTimer tmrUpdateChooseBattle,10

    If IsEmpty(CBScene) Then Exit Sub
    Set DefaultScene = CBScene

    HouseBattle2 = BattleChoices(CurrentBattleChoice) MOD 8
    HouseBattle1 = Int(BattleChoices(CurrentBattleChoice)/8)
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

' PreLaunchBattleMode
' Shut off ChooseBattle timers
' Play animation with sound for housebattle1 & 2. Show objective for housebattle1 for length of sound 
' Start battle:
'   Set mode timer(s) 
' Check if we locked a ball and if so, do lock ball processing

Sub PreLaunchBattleMode
    Dim scene,tmr
    TimerFlags(tmrUpdateChooseBattle) = 0
    TimerFlags(tmrChooseBattle) = 0
    If BattleChoices(CurrentBattleChoice) = 0 Then ' Pass for now
        PlayerMode = 0 
        AddScore 0
        PlaySoundVol "gotfx-passfornow",VolDef
        PlayModeSong
        SetPlayfieldLights
        LaunchBattleMode
        Exit Sub
    End If
    
    HouseBattle2 = BattleChoices(CurrentBattleChoice) MOD 8
    HouseBattle1 = Int(BattleChoices(CurrentBattleChoice)/8)

    ' Start battle!
    DMDHouseBattleScene HouseBattle1
    DMDHouseBattleScene HouseBattle2

    tmr = Int(SceneSoundLengths(HouseBattle1)/100)
    If HouseBattle2 > 0 Then tmr=tmr + Int(SceneSoundLengths(HouseBattle2)/100)
    
    PlayerMode = -2.1
    Set DefaultScene = ScoreScene

    House(CurrentPlayer).BattleState(HouseBattle1).StartBattleMode
    If HouseBattle2 > 0 Then House(CurrentPlayer).BattleState(HouseBattle2).StartBattleMode
    House(CurrentPlayer).SetUPFState True
    SetPlayfieldLights

    PlayModeSong

    DMDCreateAlternateScoreScene HouseBattle1,HouseBattle2

    SetGameTimer tmrLaunchBattle,tmr
End Sub

' Handle releasing or locking the ball after choosing battle
Sub LaunchBattleMode
    TimerFlags(tmrLaunchBattle) = 0
    PlaySoundAt "fx_droptarget", Target90
    Target90.IsDropped = 1
    If PlayerMode = -2.1 Then PlayerMode = 1
    ' Start the targaryen HurryUp if appropriate
    If HouseBattle1 = Targaryen Then 
        House(CurrentPlayer).BattleState(HouseBattle1).TGStartHurryUp
        PlaySound "gotfx-dragonwings",-1,VolDef/4
    ElseIf HouseBattle2 = Targaryen Then 
        House(CurrentPlayer).BattleState(HouseBattle2).TGStartHurryUp
        PlaySound "gotfx-dragonwings",-1,VolDef/4
    End If
    If bBattleCreateBall Then   'LockBall has already run. Create the new ball now
        bBattleCreateBall = False
        If RealBallsInLock > BallsInLock Then
            RealBallsInLock = RealBallsInLock - 1
            ReleaseLockedBall 0
        Else
            bAutoPlunger = True
            bPlayfieldValidated = False
            debug.print "calling CreateNewBall from LaunchBattleScene"
            CreateNewBall
        End If
    ElseIf bLockIsLit Then      ' Should be 3rd ball locked. Tweaked timing to ensure he doesn't speak over top of song intro
        debug.print "calling LockBall from LaunchBattleScene"
        LockBall
    Else                            ' Lock isn't lit but we have a ball locked
        debug.print "calling ReleaseLockedBall from LaunchBattleScene"
        ReleaseLockedBall 0
    End If
End Sub

' Called twice per second during battle mode
Sub UpdateBattleMode
    SetGameTimer tmrUpdateBattleMode,5
    DMDLocalScore
End Sub


'*************************
' Table lighting control
'*************************

Sub SetWildfireLights
    SetLightColor li80,green,ABS(bWildfireTargets(0))
    SetLightColor li83,green,ABS(bWildfireTargets(1))
End Sub

Sub SetTopLaneLights
    If bTopLanes(0) And bTopLanes(1) Then ' Flash the lights for a second and use a timer to shut them off
        li162.BlinkInterval=100:li165.blinkInterval=100
        li162.State=2:li165.State=2
        li162.TimerInterval=1000
        li162.TimerEnabled=1
    Else
        SetLightColor li162, white, ABS(bTopLanes(0))
        SetLightColor li165, white, ABS(bTopLanes(1))
    End if
End Sub

Sub SetTargetLights
    Dim i
    For i = 0 to 2
        if i >= LoLTargetsCompleted Then LoLLights(i).State = 0 Else SetLightColor LoLLights(i),yellow,1
    Next
End Sub

Sub SetOutlaneLights
    SetLightColor li11,white,ABS(bLoLLit)
    SetLightColor li74,white,ABS(bLoLLit)
End Sub

Sub li162_Timer
    li162.State = 0
    li165.State = 0
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
    if bMysteryLit And Not bMultiBallMode Then
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

' We'll use the timer on each lit combo light to gradually speed up the flashing
Sub SetComboLights
    Dim i,stat,x
    stat = 0:x=False
    For i = 1 to 5
        If ComboMultiplier(i) > 1 Then stat=2:x=True Else stat=0
        SetLightColor ComboLights(i),red,stat
    Next
    If x Then
        ComboLights(1).TimerEnabled = True
        ComboLights(1).TimerInterval = 1000
    Else
        ComboLights(1).TimerEnabled = False
    End if
End Sub

Sub setEBLight
    if bEBisLit Then
        SetLightColor li150,amber,1
    Else
        SetLightColor li150,white,0
    End If
End Sub

' Set up all of the default colours for playfield lights
Sub SetDefaultPlayfieldLights
    Dim i
    For i = 1 to 5: SetLightColor ComboLights(i),red,-1: Next
    For i = 0 to 4: SetLightColor GoldTargetLights(i),yellow,-1: Next
    For i = 0 to 2: SetLightColor LoLLights(i),yellow,-1: Next
    For i = 0 to 3: SetLightColor pfmuxlights(i),amber,-1: Next
    SetLightColor li80,green,-1     ' WF targets
    SetLightColor li83,green,-1     ' WF targets
    SetLightColor li150,amber,-1    ' EB light
    SetLightColor li153,white,-1    ' Mystery light
    SetLightColor li138,yellow,-1   ' Sword light
    SetLightColor li111,darkgreen,-1 ' Lock light
    SetLightColor li11,white,-1     ' Outlane lights
    SetLightColor li74,white,-1     ' Outlane lights
    SetLightColor li162,white,-1    ' Toplane lights
    SetLightColor li165,white,-1    ' Toplane lights
    SetLightColor li132,midblue,-1  ' Battering Ram
    SetLightColor li129,red,-1      ' SuperJackpot Light
    SetLightColor li126,darkgreen,-1    ' Wildfire light
    SetLightColor li123,white,-1    ' Playfield Mul light
    For i = 1 to 7
        SetLightColor HouseShield(i),HouseColor(i),-1
        SetLightColor HouseSigil(i),HouseColor(i),-1
    Next

End Sub

'TODO May need a separate sequencer for in-game effects so we can have a separate _playdone sub
Sub DoLockBallSeq
    SavePlayfieldLightState
    PlayfieldSlowFade green,0.1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.Play SeqBlinking,,2,250
    LightSeqAttract.Play SeqAllOff
End Sub

' Do the light sequence for the start of BW Multiball
Sub DoBWMultiballSeq
    SavePlayfieldLightState
    PlayfieldSlowFade green,0.1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqBlinking,,2,250
    LightSeqAttract.Play SeqDownOn,75,2
    LightSeqAttract.Play SeqAllOff
    LightSeqAttract.UpdateInterval = 25
    LightSeqAttract.Play SeqBlinking,,60,25

    tmrMultiballSequencer.Interval = 2500  ' Tune this value to ensure it starts just after the wave sequence ends
    tmrMultiballSequencer.UserValue = 0
    tmrMultiballSequencer.Enabled = True
End Sub

' During multiball light sequence, randomly change the playfield colours
' between green and red during the fast random flash sequence
Sub tmrMultiballSequencer_Timer
    Dim a,c,i
    tmrMultiballSequencer.Enabled = False
    tmrMultiballSequencer.UserValue = tmrMultiballSequencer.UserValue + 1
    if tmrMultiballSequencer.UserValue > 50 Then    ' We've run for 2.5 seconds
        LightSeqAttract.StopPlay
        RestorePlayfieldLightState False
        Exit Sub
    End If
    For each a in aPlayfieldLights
        c = green
        i = RndNbr(2)
        if i = 2 then c = red
        SetLightColor a,c,-1
    Next
    tmrMultiballSequencer.Interval = 50
    tmrMultiballSequencer.Enabled = True
End Sub

'***************
' INSTANT INFO
'***************
' Format tells us how to format each scene (copied from Attract mode)
'  1: 1 line of text
'  2: 2 lines of text (same size)
'  3: 3 lines of text (small, big, medium)
'  4: image only, no text
'  5: video only, no text
'  6: video, scrolling text
'  7: 2 lines of text (big, small)
'  8: 3 lines of text (same size)
'  9: scrolling image
' 10: 1 line of text with outline
' 11: 3 lines of text (small, medium, medium)
Sub InstantInfo
    Dim scene,format,font,skipifnoflex,y,img
    Dim line1,line2,line3,font1
    InstantInfoTimer.Enabled = False
    font = "udmd-f7by10.fnt" ' Most common font
    Select Case InfoPage
        Case 0: format=1:line1="INSTANT INFO"
        Case 1 ' current ball/credits/player
            If Not bGameInPlay Then InfoPage = 29 : InstantInfo : Exit Sub 
            format=8:font="udmd-f6by8.fnt" 
            line1="BALL "&BallsPerGame-BallsRemaining(CurrentPlayer)+1
            If bFreePlay Then 
                line2 = "FREE PLAY" 
            Else
                Line2 = "CREDITS "&Credits
            End if
            line3 = "PLAYER "&CurrentPlayer&" IS UP"
        Case 2,3,4,5 ' current scores
            If PlayersPlayingGame < InfoPage-1 Then InfoPage = 6 : InstantInfo : Exit Sub 
            format=2:line1="PLAYER "&InfoPage-1:line2=FormatScore(Score(InfoPage-1)):skipifnoflex=False
        Case 6 ' current player's gold
            format=1:line1=CurrentGold&" GOLD"
        Case 7 ' LoL status
            format=8:font="udmd-f3by7.fnt"
            line1="LORD OF LIGHT"
            line3=""
            If bLoLLit Then
                line2="LIT"
            ElseIf bLoLUsed Then
                line2="USED"
            Else
                line2="SHOOT LEFT TARGETS":line3="FOR OUTLANE BALL SAVE"
            End If
        Case 8 ' Blackwater status
            format=11:font="FlexDMD.Resources.udmd-f4by5.fnt"
            line1="BLACKWATER MULTIBALL"
            If bLockIsLit Then line2="LOCK IS LIT" Else line2="SHOOT RIGHT TARGETS"
            If BallsInLock = 1 Then line3="1 BALL IN LOCK" Else line3 = BallsInLock & " BALLS IN LOCK"
        Case 9
            format=11:font="udmd-f6by8.fnt"
            line1="SPINNER"
            line2="LEVEL "&SpinnerLevel
            line3=SpinnerValue & " A SPIN"
        'Case 10: WALL MULTIBALL\n<X> ADVANCEMENTS\nTO START MULTIBALL
        'Case 11: WINTER IS COMING\n<X>\nSHOTS TO START
        'Case 12: <X>HOUSE COMPLETIONS NEEDED\nFOR EXTRA BALL
        'Case 13: SELECTED HOUSE\nHOUSE <X>\n <action>
        'Case 14-20: HOUSE <X>\n<X> MORE TO LIGHT or "IS LIT" or "COMPLETED"?
        'Case 21: SWORD COLLECTION\nSWORDS: <X>\nNEXT UNLOCKS <x>x TIMES MULTIPLIER
        'Case 22: Spinner actually goes here
        'Case 23: TOTAL BONUS\n<X>\nCURRENT MULTIPLIER <x>X
        'Case 24: REPLAY AT
        'TODO lots more info screens in here
        Case 10: InfoPage=29:InstantInfo:Exit Sub

        Case 29:format=1:line1 = "REPLAY AT" &vbLf&ReplayScore
        Case 30,31,32,33,34
            format = 8 : font="udmd-f6by8.fnt" : :skipifnoflex=False
            If InfoPage = 30 Then line1 = "GRAND CHAMPION" Else line1 = "HIGH SCORE #" & InfoPage-30
            line2 = HighScoreName(InfoPage-30) : line3 = FormatScore(HighScore(InfoPage-30))
        Case 35,36,37,38,39,40,41,42,43,44,45
            If bGameInPlay Then InfoPage=0:InstantInfo:Exit Sub
            format=3:skipifnoflex=False
            line1 = ChampionNames(i-35)&" CHAMPION"
            line2 = HighScoreName(i-30):line3 = HighScore(i-30)
    End Select
    If InfoPage >= 46 Then InfoPage = 0:InstantInfo:Exit Sub
    If bUseFlexDMD=False And skipifnoflex=True Then InfoPage=InfoPage+1:InstantInfo:Exit Sub

    ' Create the scene
    if bUseFlexDMD Then
        If format=4 or Format=5 or Format=6 or Format=9 Then
            Set scene = NewSceneWithVideo("attract"&InfoPage,img)
        Else
            Set scene = FlexDMD.NewGroup("attract"&InfoPage)
        End If

        ' Most of these modes aren't used for InstantInfo but we could probably combine the code with AttractMode to make it DRY
        Select Case format
            Case 1
                scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont(font,vbWhite,vbWhite,0),line1)
                scene.GetLabel("line1").SetAlignedPosition 64,16,FlexDMD_Align_Center
            Case 2
                Set font1 = FlexDMD.NewFont(font,vbWhite,vbWhite,0)
                scene.AddActor FlexDMD.NewLabel("line1",font1,line1)
                scene.AddActor FlexDMD.NewLabel("line2",font1,line2)
                scene.GetLabel("line1").SetAlignedPosition 64,9,FlexDMD_Align_Center
                scene.GetLabel("line2").SetAlignedPosition 64,22,FlexDMD_Align_Center
            Case 3
                scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),line1)
                scene.AddActor FlexDMD.NewLabel("line2",FlexDMD.NewFont("skinny10x12.fnt",vbWhite,vbWhite,0),line2)
                scene.AddActor FlexDMD.NewLabel("line3",FlexDMD.NewFont("udmd-f6by8.fnt",vbWhite,vbWhite,0),line3)
                scene.GetLabel("line1").SetAlignedPosition 64,3,FlexDMD_Align_Center
                scene.GetLabel("line2").SetAlignedPosition 64,15,FlexDMD_Align_Center
                scene.GetLabel("line3").SetAlignedPosition 64,27,FlexDMD_Align_Center
            Case 6
                scene.AddActor FlexDMD.NewGroup("scroller")
                scene.SetBounds 0,0-y,128,32+(2*y)  ' Create a large canvas for the text to scroll through
                With scene.GetGroup("scroller")
                    .SetBounds 0,y+32,128,y
                    .AddAction scene.GetGroup("scroller").ActionFactory().MoveTo(0,0,scrolltime)
                    .AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont(font,vbWhite,vbWhite,0),line1)
                End With
                scene.GetVideo("attract"&i&"vid").SetAlignedPosition 0,y,FlexDMD_Align_TopLeft ' move image to screen
                scene.GetLabel("line1").SetAlignedPosition 64,0,FlexDMD_Align_Top        
            Case 7
                scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont(font,vbWhite,vbWhite,0),line1)
                scene.AddActor FlexDMD.NewLabel("line2",FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),line2)
                scene.GetLabel("line1").SetAlignedPosition 64,14,FlexDMD_Align_Center
                scene.GetLabel("line2").SetAlignedPosition 64,27,FlexDMD_Align_Center
            Case 8
                Set font1 = FlexDMD.NewFont(font,vbWhite,vbWhite,0)
                scene.AddActor FlexDMD.NewLabel("line1",font1,line1)
                scene.AddActor FlexDMD.NewLabel("line2",font1,line2)
                scene.AddActor FlexDMD.NewLabel("line3",font1,line3)
                scene.GetLabel("line1").SetAlignedPosition 64,5,FlexDMD_Align_Center
                scene.GetLabel("line2").SetAlignedPosition 64,16,FlexDMD_Align_Center
                scene.GetLabel("line3").SetAlignedPosition 64,27,FlexDMD_Align_Center
            Case 9
                scene.SetBounds 0,0-y,128,32+(2*y)  ' Create a large canvas for the image to scroll through
                With scene.GetImage("attract"&i&"img")
                    .SetAlignedPosition 0,y+32,FlexDMD_Align_TopLeft
                    .AddAction scene.GetImage("attract"&i&"img").ActionFactory().MoveTo(0,0,scrolltime)
                End With
            Case 10
                scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont(font,vbWhite,RGB(64, 64, 64),1),line1)
                scene.GetLabel("line1").SetAlignedPosition 64,16,FlexDMD_Align_Center
            Case 11
                scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),line1)
                scene.AddActor FlexDMD.NewLabel("line2",FlexDMD.NewFont(font,vbWhite,vbWhite,0),line2)
                scene.AddActor FlexDMD.NewLabel("line3",FlexDMD.NewFont(font,vbWhite,vbWhite,0),line3)
                scene.GetLabel("line1").SetAlignedPosition 64,3,FlexDMD_Align_Center
                scene.GetLabel("line2").SetAlignedPosition 64,13,FlexDMD_Align_Center
                scene.GetLabel("line3").SetAlignedPosition 64,25,FlexDMD_Align_Center
        End Select

        DMDDisplayScene scene
    Else
        ' TODO: Do Info mode for regular DMD
    End If
End Sub

'***************************
' Game-specific Attract Mode
'***************************

Sub GameAddCredit
    PlaySoundVol "fx_coin",VolDef
    ' Jump the Attract Mode Scene to the "Credits" screen
    if bAttractMode Then
        DMDFlush
        tmrAttractModeScene.UserValue = 5
        tmrAttractModeScene.Enabled = False
        tmrAttractModeScene.Interval = 10
        tmrAttractModeScene.Enabled = True
    End If
End Sub

Dim OathSeq
OathSeq = Array("NIGHT GATHERS"&vbLf&"AND NOW"&vbLf&"MY WATCH"&vbLf&"BEGINS"&vbLf&"IT SHALL"&vbLf&"NOT END"&vbLf&"UNTIL"&vbLf&"MY DEATH",_
            "I SHALL"&vbLf&"TAKE NO WIFE"&vbLf&"HOLD"&vbLf&"NO LANDS"&vbLf&"FATHER"&vbLf&"NO CHILDREN", _
            "I SHALL"&vbLf&"WEAR NO CROWNS"&vbLf&"AND WIN"&vbLf&"NO GLORY"&vbLf&"I SHALL"&vbLf&"LIVE AND DIE"&vbLf&"AT MY POST", _
            "I AM"&vbLf&"THE SWORD"&vbLf&"IN THE"&vbLf&"DARKNESS"&vbLf&"I AM"&vbLf&"THE WATCHER"&vbLf&"ON THE WALLS", _
            "I AM"&vbLf&"THE SHIELD"&vbLf&"THAT GUARDS"&vbLf&"THE REALMS"&vbLf&"OF MEN", _
            "I PLEDGE"&vbLf&"MY LIFE"&vbLf&"AND HONOR"&vbLf&"TO THE"&vbLf&"NIGHT'S WATCH"&vbLf&"FOR THIS NIGHT"&vbLf&"AND ALL"&vbLf&"THE NIGHTS"&vbLf&"TO COME")
Dim OathCnt
OathCnt = 0

Function GetNextOath()
    GetNextOath = OathSeq(OathCnt)
    OathCnt = OathCnt + 1
    If OathCnt >= 6 then OathCnt = 0
End Function

Dim ChampionNames
ChampionNames = Array("STARK","BARATHEON","LANNISTER","GREYJOY","TYRELL","MARTELL","TARGARYEN","WINTER IS COMING","WINTER HAS COME","HAND OF THE KING","IRON THRONE")

Sub GameStartAttractMode
    tmrDMDUpdate.Enabled = False
    bAttractMode = True
    tmrAttractModeScene.UserValue = 0
    tmrAttractModeScene.Interval = 10
    tmrAttractModeScene.Enabled = True

    SavePlayfieldLightState
    tmrAttractModeLighting.UserValue = 0
    tmrAttractModeLighting.Interval = 10
    tmrAttractModeLighting.Enabled = True
End Sub

Sub GameStopAttractMode
    tmrAttractModeScene.Enabled = False
    tmrAttractModeLighting.Enabled = False
    LightSeqAttract.StopPlay
    RestorePlayfieldLightState True
    DMDClearQueue
    tmrDMDUpdate.Enabled = True
    bAttractMode = False
End Sub

' To launch attract mode, disable DMDUpdateTimer and enble tmrAttractModeScene
' Attract mode is a big state machine running through various scenes in a loop. The timer is called
' after the scene has displayed for the set time, to move onto the next scene
' Scenes:
' 0: Stern logo - 3 seconds
' 1: PRESENTS - 2 seconds
' 2: GoT logo video - 21 seconds
' 3: part of Nights Watch oath on winter storm bg - 9 seconds
' 4: most recent score (just p1?) - 2 sec
' 5: credits - 2 sec
' 6: Replay at <x> - 2 sec
' 7: more oath - 9 sec
' 8: game logo - 3 sec
' 9-24: various high scores - 2 seconds each

' Format tells us how to format each scene
'  1: 1 line of text
'  2: 2 lines of text (same size)
'  3: 3 lines of text (small, big, medium)
'  4: image only, no text
'  5: video only, no text
'  6: video, scrolling text
'  7: 2 lines of text (big, small)
'  8: 3 lines of text (same size)
'  9: scrolling image
' 10: 1 line of text with outline
Sub tmrAttractModeScene_Timer
    Dim scene,scene2,img,line1,line2,line3
    Dim skip,font,format,scrolltime,y,delay,skipifnoflex,i
    Dim font1,font2,font3
    skip = False
    tmrAttractModeScene.Enabled = False
    delay = 2000
    skipifnoflex = True  ' Most scenes won't render without FlexDMD
    scrolltime = 0
    i = tmrAttractModeScene.UserValue
    Select Case tmrAttractModeScene.UserValue
        Case 0:img = "got-sternlogo":format=9:scrolltime=3:y=73:delay=3000
        Case 1:line1 = "PRESENTS":format=10:font="skinny10x12.fnt":delay=2000
        Case 2:img = "got-intro":format=5:delay=17200
        Case 3,7:img = "got-winterstorm":format=6:line1 = GetNextOath():delay=9000:font = "skinny10x12.fnt":scrolltime=9:y=100   ' Oath Text
        Case 4
            format=7:font="udmd-f11by18.fnt":line1=FormatScore(Score(1)):skipifnoflex=False  ' Last score
            If Score(1) > 999999999 Then font="udmd-f7by10.fnt"
            If bFreePlay Then line2 = "FREE PLAY" Else Line2 = "CREDITS "&Credits
        Case 5
            format=1:font="udmd-f7by10.fnt":skipifnoflex=False
            If bFreePlay Then 
                line1 = "FREE PLAY" 
            ElseIf Credits > 0 Then 
                Line1 = "CREDITS "&Credits
            Else 
                Line1 = "INSERT COINS"
            End if
        Case 6:format=1:font="udmd-f7by10.fnt":line1 = "REPLAY AT" &vbLf&ReplayScore
        Case 8:img = "got-introframe":format=4:delay=3000
        Case 9:format=8:line1="GRAND CHAMPION":line2=HighScoreName(0):line3=FormatScore(HighScore(0)):font="udmd-f6by8.fnt":skipifnoflex=False
        Case 10:format=8:line1="HIGH SCORE #1":line2=HighScoreName(1):line3=FormatScore(HighScore(1)):font="udmd-f6by8.fnt":skipifnoflex=False
        Case 11:format=8:line1="HIGH SCORE #2":line2=HighScoreName(2):line3=FormatScore(HighScore(2)):font="udmd-f6by8.fnt":skipifnoflex=False
        Case 12:format=8:line1="HIGH SCORE #3":line2=HighScoreName(3):line3=FormatScore(HighScore(3)):font="udmd-f6by8.fnt":skipifnoflex=False
        Case 13:format=8:line1="HIGH SCORE #4":line2=HighScoreName(4):line3=FormatScore(HighScore(4)):font="udmd-f6by8.fnt":skipifnoflex=False
        Case 14,15,16,17,18,19,20,21,22,23,24
            If HighScore(i-8) = 0 Then delay = 5
            format=3:skipifnoflex=False
            line1 = ChampionNames(i-14)&" CHAMPION"
            line2 = HighScoreName(i-9):line3 = HighScore(i-9)
    End Select
    If i = 24 Then tmrAttractModeScene.UserValue = 0 Else tmrAttractModeScene.UserValue = i + 1
    If bUseFlexDMD=False And skipifnoflex=True Then tmrAttractModeScene.Interval = 10 Else tmrAttractModeScene.Interval = delay
    tmrAttractModeScene.Enabled = True

    ' Create the scene
    if bUseFlexDMD Then
        If format=4 or Format=5 or Format=6 or Format=9 Then
            Set scene = NewSceneWithVideo("attract"&i,img)
        Else
            Set scene = FlexDMD.NewGroup("attract"&i)
        End If

        Select Case format
            Case 1
                scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont(font,vbWhite,vbWhite,0),line1)
                scene.GetLabel("line1").SetAlignedPosition 64,16,FlexDMD_Align_Center
            Case 3
                scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),line1)
                scene.AddActor FlexDMD.NewLabel("line2",FlexDMD.NewFont("skinny10x12.fnt",vbWhite,vbWhite,0),line2)
                scene.AddActor FlexDMD.NewLabel("line3",FlexDMD.NewFont("udmd-f6by8.fnt",vbWhite,vbWhite,0),line3)
                scene.GetLabel("line1").SetAlignedPosition 64,3,FlexDMD_Align_Center
                scene.GetLabel("line2").SetAlignedPosition 64,15,FlexDMD_Align_Center
                scene.GetLabel("line3").SetAlignedPosition 64,27,FlexDMD_Align_Center
            Case 6
                scene.AddActor FlexDMD.NewGroup("scroller")
                scene.SetBounds 0,0-y,128,32+(2*y)  ' Create a large canvas for the text to scroll through
                With scene.GetGroup("scroller")
                    .SetBounds 0,y+32,128,y
                    .AddAction scene.GetGroup("scroller").ActionFactory().MoveTo(0,0,scrolltime)
                    .AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont(font,vbWhite,vbWhite,0),line1)
                End With
                scene.GetVideo("attract"&i&"vid").SetAlignedPosition 0,y,FlexDMD_Align_TopLeft ' move image to screen
                scene.GetLabel("line1").SetAlignedPosition 64,0,FlexDMD_Align_Top        
            Case 7
                scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont(font,vbWhite,vbWhite,0),line1)
                scene.AddActor FlexDMD.NewLabel("line2",FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),line2)
                scene.GetLabel("line1").SetAlignedPosition 64,14,FlexDMD_Align_Center
                scene.GetLabel("line2").SetAlignedPosition 64,27,FlexDMD_Align_Center
            Case 8
                Set font1 = FlexDMD.NewFont(font,vbWhite,vbWhite,0)
                scene.AddActor FlexDMD.NewLabel("line1",font1,line1)
                scene.AddActor FlexDMD.NewLabel("line2",font1,line2)
                scene.AddActor FlexDMD.NewLabel("line3",font1,line3)
                scene.GetLabel("line1").SetAlignedPosition 64,5,FlexDMD_Align_Center
                scene.GetLabel("line2").SetAlignedPosition 64,16,FlexDMD_Align_Center
                scene.GetLabel("line3").SetAlignedPosition 64,27,FlexDMD_Align_Center
            Case 9
                scene.SetBounds 0,0-y,128,32+(2*y)  ' Create a large canvas for the image to scroll through
                With scene.GetImage("attract"&i&"img")
                    .SetAlignedPosition 0,y+32,FlexDMD_Align_TopLeft
                    .AddAction scene.GetImage("attract"&i&"img").ActionFactory().MoveTo(0,0,scrolltime)
                End With
            Case 10
                scene.AddActor FlexDMD.NewLabel("line1",FlexDMD.NewFont(font,vbWhite,RGB(64, 64, 64),1),line1)
                scene.GetLabel("line1").SetAlignedPosition 64,16,FlexDMD_Align_Center
        End Select

        DMDDisplayScene scene
    Else
        ' TODO: Do attract mode for regular DMD
    End If
End Sub

' Attract mode light sequence
' For first part, light sequence is sigils and playfield X rotating, all others flashing quickly bottom to top.
' The lights that are on are all the same colour as whichever sigil is lit, if we care
' Then sequences:
'       - 4-color slow transition thru RGBP
'       - bottom-to-top fade sweeps in sequential colours 6 total) ROYGBP
'       - top-to-bottom fade sweeps
'       - right to left fade sweeps, faster
'       - left to right fade sweep
'       - 7 color faster transition 

Dim AttractPFcolors
Dim PFCurrentColor
AttractPFcolors = Array(red,orange,yellow,green,blue,purple)
Dim ColorWheel
' Wheel of colours used to fade between 6 primary colours
' These values were calculated using a script. They are the intermediate values between the primary colours,
' calculated as "R*65536 + G*256 + B", equivalent to the hex number &H00RRGGBB
ColorWheel = Array(16711680,16711936,16712192,16712448,16712704,16712960,16713216,16713472,16713728,16713984,16714496,16714752,16715008,16715264,16715520,16715776,16716032,16716288,16716544,16716800, _
                    16717312,16717568,16717824,16718080,16718336,16718592,16718848,16719104,16719360,16719616,16720128,16720384,16720640,16720896,16721152,16721408,16721664,16721920,16722176,16722688, _
                    16722944,16723200,16723456,16723712,16723968,16724224,16724480,16724736,16724992,16725504,16725760,16726016,16726272,16726528,16726784,16727040,16727296,16727552, _
                    16728064,16728832,16729600,16730368,16731392,16732160,16732928,16733952,16734720,16735488,16736256,16737280,16738048,16738816,16739840,16740608,16741376,16742144,16743168,16743936, _
                    16744704,16745728,16746496,16747264,16748288,16749056,16749824,16750592,16751616,16752384,16753152,16754176,16754944,16755712,16756480,16757504,16758272,16759040,16760064,16760832, _
                    16761600,16762624,16763392,16764160,16764928,16765952,16766720,16767488,16768512,16769280,16770048,16770816,16771840,16772608,16773376,16774400,16775168,16775936, _
                    16776960,16449280,16187136,15859456,15597312,15335168,15007488,14745344,14417664,14155520,13893376,13565696,13303552,12975872,12713728,12451584,12123904,11861760,11534080,11271936, _
                    11009792,10682112,10419968,10092288,9830144,9568000,9240320,8978176,8650496,8388352,8126208,7798528,7536384,7208704,6946560,6684416,6356736,6094592,5766912,5504768, _
                    5242624,4914944,4652800,4325120,4062976,3800832,3473152,3211008,2883328,2621184,2359040,2031360,1769216,1441536,1179392,917248,589568,327424, _
                    65280,64004,62984,61709,60689,59669,58394,57374,56099,55079,54059,52784,51764,50489,49469,48449,47174,46154,44879,43859, _
                    42839,41564,40544,39269,38249,37229,35954,34934,33659,32639,31619,30344,29324,28049,27029,26009,24734,23714,22439,21419, _
                    20399,19124,18104,16829,15809,14789,13514,12494,11219,10199,9179,7904,6884,5609,4589,3569,2294,1274, _
                    255,131325,262396,393467,524538,721145,852216,983287,1114358,1245429,1442036,1573107,1704177,1835248,1966319,2162926,2293997,2425068,2556139,2687210, _
                    2883817,3014888,3145959,3277030,3408100,3604707,3735778,3866849,3997920,4128991,4325598,4456669,4587740,4718811,4915418,5046488,5177559,5308630,5439701,5636308, _
                    5767379,5898450,6029521,6160592,6357199,6488270,6619341,6750411,6881482,7078089,7209160,7340231,7471302,7602373,7798980,7930051,8061122,8192193,8388800     )

Sub tmrAttractModeLighting_Timer
    Dim i,seqtime,c,a
    tmrAttractModeLighting.Enabled = False
    i=1
    Select Case Int(tmrAttractModeLighting.UserValue)
        Case 0  ' Random
            LightSeqAttract.StopPlay
            RestorePlayfieldLightState True
            LightSeqAttract.UpdateInterval = 75
            LightSeqAttract.Play SeqRandom,25,,10000
            LightSeqAttract.Play SeqAllOff
            seqtime = 10000
        Case 1,9
            ' Step through the colorwheel values, once every 30ms (about 10 seconds to fade between the 6 main colours)
            seqtime = 30:i=0.001
            c = int((tmrAttractModeLighting.UserValue - Int(tmrAttractModeLighting.UserValue))*1000)
            if c = 0 Then
                LightSeqAttract.StopPlay
                PlayfieldSlowFade red,10
                For each a in aPlayfieldLights
                    a.State = 1
                Next
            End if
            If c > 290 then 
                ' Jump to the next effect
                i = 0: tmrAttractModeLighting.UserValue = Int(tmrAttractModeLighting.UserValue)+1
                For each a in aPlayfieldLights
                    a.State = 0
                Next
            Else
                c = ColorWheel(c)
                For each a in aPlayfieldLights
                    a.colorfull = c
                Next
            End If
        Case 2
            LightSeqAttract.StopPlay
            c = int((tmrAttractModeLighting.UserValue - Int(tmrAttractModeLighting.UserValue))*10)
            if c = 5 then Me.UserValue = 3:i = 0 Else i = 0.1
            PlayfieldSlowFade AttractPFcolors(c),0.1
            LightSeqAttract.UpdateInterval = 20
            LightSeqAttract.Play SeqUpOn, 25, 1
            seqtime = 2500
        Case 3
            LightSeqAttract.StopPlay
            c = int((tmrAttractModeLighting.UserValue - Int(tmrAttractModeLighting.UserValue))*10)
            if c = 5 then Me.UserValue = 4:i = 0 Else i = 0.1
            PlayfieldSlowFade AttractPFcolors(c),0.1
            LightSeqAttract.UpdateInterval = 20
            LightSeqAttract.Play SeqDownOn, 25, 1
            seqtime = 2500
        Case 4
            LightSeqAttract.StopPlay
            c = int((tmrAttractModeLighting.UserValue - Int(tmrAttractModeLighting.UserValue))*10)
            if c = 5 then Me.UserValue = 5:i = 0 Else i = 0.1
            PlayfieldSlowFade AttractPFcolors(c),0.1
            LightSeqAttract.UpdateInterval = 10
            LightSeqAttract.Play SeqRightOn, 25, 1
            seqtime = 1000
        Case 5
            LightSeqAttract.StopPlay
            c = int((tmrAttractModeLighting.UserValue - Int(tmrAttractModeLighting.UserValue))*10)
            if c = 5 then Me.UserValue = 6:i = 0 Else i = 0.1
            PlayfieldSlowFade AttractPFcolors(c),0.1
            LightSeqAttract.UpdateInterval = 10
            LightSeqAttract.Play SeqLeftOn, 25, 1
            seqtime = 1000
        Case 6
            LightSeqAttract.StopPlay
            c = int((tmrAttractModeLighting.UserValue - Int(tmrAttractModeLighting.UserValue))*10)
            if c = 5 then Me.UserValue = 7:i = 0 Else i = 0.1
            PlayfieldSlowFade AttractPFcolors(c),0.1
            LightSeqAttract.UpdateInterval = 20
            LightSeqAttract.Play SeqCircleOutOn, 25, 1
            seqtime = 2500
        Case 7
            LightSeqAttract.StopPlay
            c = int((tmrAttractModeLighting.UserValue - Int(tmrAttractModeLighting.UserValue))*10)
            if c = 5 then Me.UserValue = 8:i = 0 Else i = 0.1
            PlayfieldSlowFade AttractPFcolors(c),0.1
            LightSeqAttract.UpdateInterval = 7
            LightSeqAttract.Play SeqClockLeftOn, 25, 1
            seqtime = 2500
        Case 8
            LightSeqAttract.StopPlay
            c = int((tmrAttractModeLighting.UserValue - Int(tmrAttractModeLighting.UserValue))*10)
            if c = 5 then Me.UserValue = 9:i = 0 Else i = 0.1
            PlayfieldSlowFade AttractPFcolors(c),0.1
            LightSeqAttract.UpdateInterval = 7
            LightSeqAttract.Play SeqRadarRightOn, 25, 1
            seqtime = 2500
        Case Else
            ' Loop back to first effect
			tmrAttractModeLighting.UserValue = 0:i=0:seqtime=10
    End Select
    tmrAttractModeLighting.UserValue = tmrAttractModeLighting.UserValue + i
    tmrAttractModeLighting.Interval = seqtime
    tmrAttractModeLighting.Enabled = True

End Sub

'**************************
' Game-specific DMD support
'**************************

' The SuperJackpot scene is pretty complicated, but a highlight of the real table, so
' we need to try and reproduce it.
' Sequence is:
'   - battering ram doors open on DMD leaving a space in the middle
'   - in the middle space, the letters S-U-P-E-R-J-A-C-K-P-O-T spell out sequential with a deep drum hit for each
'   - drum is timed with the letter showing, so need a timer that does both at once
'   - at the end of the letters, scene flashes rapidly between score and all white
'   - all lights on playfield flash. Can this be done with a single sequence?
Dim BWSJPScene
Sub DMDBlackwaterSJPScene(score)
    Dim i
    If bUseFlexDMD Then
        Set BWSJPScene = NewSceneWithVideo("bwsjp","got-blackwatersjp")
        For i = 1 to 12
            BWSJPScene.AddActor FlexDMD.NewImage("img"&i,"got-bwsjpletter"&i&".png")
            With BWSJPScene.GetImage("img"&i)
                .SetAlignedPosition 64,16,FlexDMD_Align_Center
                .Visible = 0
            End With
        Next
        ' Add the score and white background
        BWSJPScene.AddActor FlexDMD.NewLabel("score",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite, vbBlack, 0),score)
        BWSJPScene.AddActor FlexDMD.NewImage("blank","got-blankwhite.png")
        BWSJPScene.AddActor FlexDMD.NewLabel("scoreinv",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite, vbBlack, 0),score)
        With BWSJPScene.GetLabel("score")
            .SetAlignedPosition 64,16,FlexDMD_Align_Center
            .Visible = 0
        End With
        With BWSJPScene.GetLabel("scoreinv")
            .SetAlignedPosition 64,16,FlexDMD_Align_Center
            .Visible = 0
        End With
        BWSJPScene.GetImage("blank").Visible = 0

        DMDEnqueueScene BWSJPScene,0,2600,5000,1500,""
    Else
        DisplayDMDText "SUPER JACKPOT",score,2000
        PlaySoundVol "say-super-jackpot",VolDef
    End If
End Sub

'This timer is triggered from DMDUpdate_Timer once the super jackpot scene starts playing
Sub tmrSJPScene_Timer
    Dim i,delay
    Me.Enabled = False
    i = Me.UserValue
    i = i + 1
    delay = 175
    FlexDMD.LockRenderThread
    If i = 1 Then   ' Turn on the first letter
        BWSJPScene.GetImage("img"&i).Visible = 1
        PlaySoundVol "gotfx-sjpdrum",VolDef
        LightSeqAttract.UpdateInterval = 20
        LightSeqAttract.Play SeqBlinking, ,12, 62
        LightSeqGi.UpdateInterval = 20
        LightSeqGi.Play SeqBlinking, , 12, 62
    ElseIf i < 13 Then  ' turn on the next letter
        BWSJPScene.GetImage("img"&(i-1)).Visible = 0
        BWSJPScene.GetImage("img"&i).Visible = 1
        PlaySoundVol "gotfx-sjpdrum",VolDef
    ElseIf i = 13 Then ' turn off the last letter and turn on the score
        BWSJPScene.GetImage("img"&(i-1)).Visible = 0
        BWSJPScene.GetVideo("bwsjpvid").Visible = 0
        BWSJPScene.GetLabel("score").Visible = 1
        PlaySoundVol "say-super-jackpot",VolDef
        delay = 33
    ElseIf i < 73 Then  ' toggle inverted score with white background on and off
        delay = 50
        If (i MOD 2) = 0 Then
            BWSJPScene.GetLabel("scoreinv").Visible = 1
            BWSJPScene.GetImage("blank").Visible = 1
        Else
            BWSJPScene.GetLabel("scoreinv").Visible = 0
            BWSJPScene.GetImage("blank").Visible = 0
            PlayExistingSoundVol "gotfx-sjpdrum",VolDef,1
        End if
    Else
        FlexDMD.UnlockRenderThread
        Exit Sub
    End If
    FlexDMD.UnlockRenderThread
    Me.UserValue = i
    Me.Interval = delay
    Me.Enabled = True
End Sub

' Played at the end of Blackwater Multiball
Sub DMDBlackwaterCompleteScene
    Dim scene
    If bUseFlexDMD Then
        If BlackwaterScore > 0 Then
            Set scene = NewSceneWithVideo("bwcomplete","got-blackwatertotal")
            scene.AddActor FlexDMD.NewLabel("txt",FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbBlack, 0),"BLACKWATER TOTAL")
            scene.GetLabel("txt").SetAlignedPosition 64,10,FlexDMD_Align_Center
            scene.AddActor FlexDMD.NewLabel("score",FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite, vbBlack, 0),FormatScore(BlackwaterScore))
            scene.GetLabel("score").SetAlignedPosition 64,20,FlexDMD_Align_Center
            DMDEnqueueScene scene,0,5000,5000,2000,"gotfx-blackwatertotal"
        End if
    Else
        DisplayDMDText "BLACKWATER TOTAL",FormatScore(BlackwaterScore),4000
        PlaySoundVol "gotfx-blackwatertotal",VolDef
    End If
    If BlackwaterScore > 100000000 Then vpmTimer.addTimer 2500,"PlaySoundVol ""say-you-have-won"",VolDef '"
End Sub

Dim BaratheonSpinnerScene
Sub DMDBaratheonSpinnerScene(value)
    If bUseFlexDMD Then
        If AccumulatedSpinnerValue = 0 or IsEmpty(BaratheonSpinnerScene) Then ' Spinner has gone a little while without spinning. Start new scene
            Set BaratheonSpinnerScene = NewSceneWithVideo("barspin","got-baratheonbattlespinner")
            BaratheonSpinnerScene.AddActor FlexDMD.NewLabel("bartop",FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbBlack, 0),"BARATHEON")
            BaratheonSpinnerScene.AddActor FlexDMD.NewLabel("barmid",FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbBlack, 0),"VALUE"&vbLf&"INCREASES")
            BaratheonSpinnerScene.AddActor FlexDMD.NewLabel("barval",FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbBlack, 0),FormatScore(value))
            BaratheonSpinnerScene.GetLabel("bartop").SetAlignedPosition 2,2,FlexDMD_Align_TopLeft
            BaratheonSpinnerScene.GetLabel("barmid").SetAlignedPosition 2,11,FlexDMD_Align_TopLeft
        Else
            FlexDMD.LockRenderThread
            BaratheonSpinnerScene.GetLabel("barval").Text = FormatScore(value)
            FlexDMD.UnlockRenderThread
        End If
        BaratheonSpinnerScene.GetLabel("barval").SetAlignedPosition 2,30,FlexDMD_Align_BottomLeft
        DMDEnqueueScene BaratheonSpinnerScene,0,1000,2000,1000,"gotfx-baratheonbattlespinner"
    Else
        DisplayDMDText "VALUE INCREASES",value,0
        PlaySoundVol "gotfx-baratheonbattlespinner",VolDef
    End If
End Sub

' Create a "Hit" scene which plays every time a qualifying or battle target is hit
'  vid   - the name of the video for the first part of the scene
'  sound - the sound to play with the video
'  delay - How long to wait before cutting to the second part of the scene, in seconds (float)
'  line1-3 - Up to 3 lines of text
'  combo - If 0, text is full width. Otherwise, Combo multiplier is on the right side
'  format - The following formats (layouts) are supported
'           0 - top line 3x7, middle line 7x12 skinny, bottom line 3x5. This is used for all Qualfying hits
'           1 - top line 5x7, middle line 7x12 skinny, bottom line 7x5. Used for most battle scenes
'           2 - 3 lines of 3x7 font, used for lannister battle gold hits
'           3 - 2 lines of text. Top line 3x7, main line 6x8 score. Used for jackpots, Castle MB levels, and Targaryen hurry-up hits
'           4 - 2 lines of Skinny font. Used for Castle Multiball start
'           5 - 2 lines of text, same as 3, but no video, just a framed text scene and combo text. Used for UPF awards
'           6 - same layout as 0, but video is made using image sequence, and runs at same time as text. used for Targaryen qualify hits
'           7 - same text layout as 3, but video runs in the background at the same time
Sub DMDPlayHitScene(vid,sound,delay,line1,line2,line3,combo,format)
    Dim scene,scenevid,font1,font2,font3,x,y1,y2,y3,combotxt,pri
    Set scenevid = Nothing
    If bUseFlexDMD Then
        If format = 6 Then
            Set scene = FlexDMD.NewGroup("hitscene")
        Else
            Set scene = NewSceneWithVideo("hitscene",vid)
            Set scenevid = scene.GetVideo("hitscenevid")
            If scenevid is Nothing Then Set scenevid = scene.getImage("hitsceneimg")
        End If
        y1 = 4: y2 = 15: y3 = 26
        Select Case format
            Case 0,6
                Set font1 = FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbWhite, 0)
                Set font2 = FlexDMD.NewFont("skinny7x12.fnt", vbWhite, vbWhite, 0)
                Set font3 = FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0)
            Case 1
                Set font1 = FlexDMD.NewFont("FlexDMD.Resources.udmd-f5by7.fnt", vbWhite, vbWhite, 0)
                Set font2 = FlexDMD.NewFont("skinny7x12.fnt", vbWhite, vbWhite, 0)
                set font3 = font1
            Case 2
                Set font1 = FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbWhite, 0)
                Set font2 = font1
                Set font3 = font1
            Case 3,5,7
                Set font1 = FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbWhite, 0)
                Set font2 = FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite, vbWhite, 0)
                Set font3 = font1
            Case 4
                Set font1 = FlexDMD.NewFont("skinny10x12.fnt", vbWhite, vbWhite, 0)
                Set font2 = font1
                Set font3 = font1
                y1 = 8: y2 = 23
        End Select

        scene.AddActor FlexDMD.NewGroup("hitscenetext")
        With scene.GetGroup("hitscenetext")
            .AddActor FlexDMD.NewLabel("line1",font1,line1)
            .AddActor FlexDMD.NewLabel("line2",font2,line2)
            .AddActor FlexDMD.NewLabel("line3",font3,line3)
            .Visible = False
        End With
        x = 64
        ' If a combo multiplier was specified, set it up on the right side
        If combo > 0 Then
            x = 40
            combotxt = ""
            Select Case True
                Case (combo > 1 and PlayfieldMultiplierVal = 1) : combotxt = "COMBO"
                Case (combo = 1 and PlayfieldMultiplierVal > 1) : combotxt = "PLAYFIELD"
                Case (combo > 1 and PlayfieldMultiplierVal > 1) : combotxt = "MIXED"
                Case (format = 5 and combo > 1 and PlayfieldMultiplierVal = 1) : combotxt = "UPPER"
            End Select
            With scene.GetGroup("hitscenetext")
                .AddActor FlexDMD.NewLabel("combo",FlexDMD.NewFont("FlexDMD.Resources.udmd-f12by24.fnt", vbWhite, vbWhite, 0),combo&"X")
                .AddActor FlexDMD.NewLabel("combotxt",FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0),combotxt)
                .GetLabel("combo").SetAlignedPosition 104,19,FlexDMD_Align_Center
                .GetLabel("combotxt").SetAlignedPosition 104,3,FlexDMD_Align_Center
            End With
        End If
        With scene.GetGroup("hitscenetext")
            .GetLabel("line1").SetAlignedPosition x,y1,FlexDMD_Align_Center
            .GetLabel("line2").SetAlignedPosition x,y2,FlexDMD_Align_Center
            .GetLabel("line3").SetAlignedPosition x,y3,FlexDMD_Align_Center
        End With

        ' If line2 is a score, flash it
        If format <> 2 and format <> 4 and format <> 6 Then BlinkActor scene.GetGroup("hitscenetext").GetLabel("line2"),100,10        

        If format <> 6 And format > 2 Then scene.GetGroup("hitscenetext").GetLabel("line3").Visible = False

        ' After delay, disable video/image and enable text
        ' TODO: Make the transition from video to text cool.
        If format <> 6 And delay > 0 And Not (scenevid Is Nothing) Then
            DelayActor scenevid,delay,False
            DelayActor scene.GetGroup("hitscenetext"),delay,True
        Else
            scene.GetGroup("hitscenetext").Visible = True
            delay = 0
        End If
        If format = 6 Then
            Dim i
            Select Case vid
                Case "got-targaryenqualify1": i=32
                Case "got-targaryenqualify2": i=77
                Case "got-targaryenqualify3": i=62
            End Select
            scene.AddActor NewSceneFromImageSequence("hitscenevid",vid,i,25,0,0)
            delay = int(((i-30)/25)+1)
        End if

        'Special case - make Jackpot hit scenes priority 0
        If sound = "gotfx-bwexplosion" Then pri=0 Else pri=1

        DMDEnqueueScene scene,pri,delay*1000+1000,delay*1000+2000,3000,sound
    Else
        DisplayDMDText line1,line2,2000
        PlaySoundVol sound,VolDef
    End If

End Sub

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
        Set HouseFont  = FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbWhite, 0)
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
            ChooseHouseScene.GetLabel("choosetxt").SetAlignedPosition 72,5,FlexDMD_Align_Center
            ChooseHouseScene.GetLabel("house").SetAlignedPosition 72,16,FlexDMD_Align_Center
            ChooseHouseScene.GetLabel("action").SetAlignedPosition 72,27,FlexDMD_Align_Center
            Set DefaultScene = ChooseHouseScene
            DMDFlush
        Else
            FlexDMD.LockRenderThread
			Set sigilimage = ChooseHouseScene.GetImage("sigil")
            If Not sigilimage Is Nothing Then ChooseHouseScene.RemoveActor(sigilimage)
            Set sigilimage = FlexDMD.NewImage("sigil",sigil)
            If Not (sigilimage Is Nothing) Then ChooseHouseScene.AddActor sigilimage
            ChooseHouseScene.GetLabel("house").Text = line1
            ChooseHouseScene.GetLabel("action").Text = line2
            ChooseHouseScene.GetLabel("house").SetAlignedPosition 72,16,FlexDMD_Align_Center
            ChooseHouseScene.GetLabel("action").SetAlignedPosition 72,27,FlexDMD_Align_Center
            Set DefaultScene = ChooseHouseScene
            FlexDMD.UnlockRenderThread
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
            DMDFlush
            If Not bBattleInstructionsDone Then 
                Set instscene = FlexDMD.NewGroup("choosebattleinstr")
                instscene.AddActor FlexDMD.NewLabel("instructions",FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbWhite, 0), _ 
                        "CHOOSE YOUR BATTLE" & vbLf & "USE FLIPPERS TO" & vbLf & "CHANGE YOUR CHOICE" )
                instscene.GetLabel("instructions").SetAlignedPosition 64,16,FlexDMD_Align_Center
                DMDEnqueueScene instscene,0,1500,1500,100,""
            End If

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
            FlexDMD.LockRenderThread
            CBScene.GetLabel("house1").Text = line1
            If line2 = "" Then
                If SelectedHouse = Greyjoy Then
                    With CBScene.GetLabel("and")
                        .Text = "IN ALLIANCE WITH"
                        .SetAlignedPosition 64,20,FlexDMD_Align_Center
                        .Visible = True
                    End With
                    With CBScene.GetLabel("house2")
                        .Visible = True
                        .Text = "GREYJOY"
                        .SetAlignedPosition 64,28,FlexDMD_Align_Center
                    End With
                Else
                    CBScene.GetLabel("house1").SetAlignedPosition 64,20,FlexDMD_Align_Center
                    CBScene.GetLabel("and").Visible = False
                    CBScene.GetLabel("house2").Visible = False
                End if
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
            FlexDMD.UnlockRenderThread
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
Dim SceneSoundLengths: SceneSoundLengths = Array(0,4654,4855,7305,4368,4665,4702,5500,5500,5500)  ' Battle sound lengths in 1/1000th's of a second, minus half a second
Sub DMDHouseBattleScene(hse)
    Dim scene,vid,af,blink,hname,delay,vidname,lvl,h

    If hse = 0 Then Exit Sub
    h = hse
    If bUseFlexDMD Then
        hname = HouseToString(h)
        If h = Targaryen Then 
            lvl = House(CurrentPlayer).BattleState(Targaryen).TGLevel
            h = h + lvl
            vidname = "got-targaryen"&lvl+1&"battleintro"
        Else
            vidname = "got-"&hname&"battleintro"
        End If
        Set scene = NewSceneWithVideo(hname&"battleintro",vidname)
        Set vid = scene.GetVideo(hname&"battleintrovid")
        If vid is Nothing Then Set vid = scene.getImage(hname&"battleintroimg")
        scene.AddActor FlexDMD.NewLabel("objective",FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbWhite, 0),BattleObjectives(h))
        With scene.GetLabel("objective")
            .SetAlignedPosition 64,16, FlexDMD_Align_Center
            .Visible = False
        End With
        ' After x seconds, disable video/image and enable text objective
        Select Case h
            Case Stark: delay=1
            Case Martell: delay=1.9
            Case Lannister,Baratheon: delay=2.5
            Case Else: delay=3
        End Select
        If Not (vid Is Nothing) Then
            DelayActor vid,delay,False
            DelayActor scene.GetLabel("objective"),delay,True
        Else
            scene.GetLabel("objective").Visible = True
        End If
        DMDEnqueueScene scene,1,SceneSoundLengths(h),SceneSoundLengths(h),10000,"gotfx-"&hname&"battleintro"
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
                    .Visible = True
                End With
                ' If the bumpers all match, flash the text and keep scene on screen for a second
                If matched Then BlinkActor poplabel,0.1,5:mintime=1000:pri=1
            Next
            FlexDMD.UnlockRenderThread
        End If

        DMDEnqueueScene PictoScene,pri,mintime,1000,300,""
    Else
        'TODO: Needs work, as default DMD display may have too big a font for 24 chars across
        DMD "",CL(0,PictoPops(BumperVals(0))(1) & " " &  PictoPops(BumperVals(1))(1) & " " & PictoPops(BumperVals(2))(1)),"",eNone,eNone,eNone,250,True,""
    End If
End Sub

Dim MysteryScene
Sub DMDMysteryAwardScene
    Dim i
    Dim Frame(2),font,line1
    If bUseFlexDMD Then
        If IsEmpty(MysteryScene) Then
            ' Create the scene
            Set font = FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0)
            Set MysteryScene = FlexDMD.NewGroup("myst")

            ' Create 3 frames. In each frame, put the text of the corresponding mystery award
            Dim poplabel
            For i = 0 to 2
                MysteryScene.AddActor FlexDMD.NewFrame("popbox" & i)
                With MysteryScene.GetFrame("popbox" & i)
                    If i = MysterySelected Then .Thickness = 2 Else .Thickness = 1
                    .SetBounds i*42, 0, 43, 32      ' Each frame is 43W by 32H, and offset by 0, 42, or 84 pixels
                End With
                line1 = MysteryAwards(MysteryVals(i))(0) & vbLf & MysteryAwards(MysteryVals(i))(1) & " GOLD"
                Select Case MysteryVals(i)
                    Case 0: line1 = "KEEP MY" & vbLf & CurrentGold & " GOLD"
                    Case 1,18,28: line1 = CStr(MysteryAwards(MysteryVals(i))(0)*PlayfieldMultiplierVal) & vblf & "MILLION" & vbLf & "POINTS" & vbLf & MysteryAwards(MysteryVals(i))(1) & " GOLD"
                End Select
                MysteryScene.AddActor FlexDMD.NewLabel("pop"&i, font, line1)
                
                ' Place the text in the middle of the frame and let FlexDMD figure it out
                Set poplabel = MysteryScene.GetLabel("pop"&i)
                poplabel.SetAlignedPosition i*42+21, 16, FlexDMD_Align_Center
                ' Choice has been made, flash the selected option
                If i = MysterySelected And Not bMysteryAwardActive Then BlinkActor poplabel,0.1,5
            Next
            MysteryScene.AddActor FlexDMD.NewLabel("tmr",font,"10")
            MysteryScene.GetLabel("tmr").SetAlignedPosition 3,2,FlexDMD_Align_TopLeft
            If MATstep = 0 then DMDFlush
            Set DefaultScene = MysteryScene
        Else
            ' Existing scene. Update the text
            FlexDMD.LockRenderThread
            For i = 0 to 2
                With MysteryScene.GetFrame("popbox" & i)
                    If i = MysterySelected Then .Thickness = 2 Else .Thickness = 1
                    .SetBounds i*42, 0, 43, 32      ' Each frame is 43W by 32H, and offset by 0, 42, or 84 pixels
                End With
                line1 = MysteryAwards(MysteryVals(i))(0) & vbLf & MysteryAwards(MysteryVals(i))(1) & " GOLD"
                Select Case MysteryVals(i)
                    Case 0: line1 = "KEEP MY" & vbLf & CurrentGold & " GOLD"
                    Case 1,18,28: line1 = CStr(MysteryAwards(MysteryVals(i))(0)*PlayfieldMultiplierVal) & vblf & "MILLION" & vbLf & "POINTS" & vbLf & MysteryAwards(MysteryVals(i))(1) & " GOLD"
                End Select
                Set poplabel = MysteryScene.GetLabel("pop"&i)
                With poplabel
                    .Text = line1
                    .SetAlignedPosition i*42+21, 16, FlexDMD_Align_Center
                ' Remove any existing action
                    .ClearActions()
                    .Visible = True
                End With
                ' Choice has been made, flash the selected option
                If i = MysterySelected And Not bMysteryAwardActive Then BlinkActor poplabel,0.1,5
            Next
            MysteryScene.GetLabel("tmr").Text = CStr(10-MATstep)
            FlexDMD.UnlockRenderThread
            If MATstep = 0 Then DMDFlush : Set DefaultScene = MysteryScene
        End If
    Else
        DisplayDMDText MysteryAwards(MysteryVals(i))(0),MysteryAwards(MysteryVals(i))(1) & " GOLD",0
    End If
End Sub


' Summarize Battle. 2 scenes - animation and then summary. Format:
'
'   Battle Objective
'      SCORE             Combo X
'    "COMPLETED"
'
' Scenes: Stark: Arya stabbing guy on floor

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
        scene.AddActor FlexDMD.NewLabel("line2", FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),line2)
        scene.GetLabel("score").SetAlignedPosition x1,30,j3
        scene.GetLabel("line1").SetAlignedPosition x1,5,just1
        scene.GetLabel("line2").SetAlignedPosition x2,30,just2
        DMDEnqueueScene scene,1,2000,2000,1000,sound
    Else
        DisplayDMDText line1,score,2000
        PlaySoundVol sound,VolDef
    End If
End Sub

Dim SpinScene
Dim SpinNum
Sub DMDSpinnerScene(spinval)
    Dim suffix,x,y,locked,tinyfont
    locked=False
    If bUseFlexDMD Then
        Set tinyfont = FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0)
        If IsEmpty(SpinScene) Then
            SpinNum = 0
            Set SpinScene = FlexDMD.NewGroup("spinner")
            SpinScene.SetBounds 0,-8,128,40
        End If
        If Not IsEmpty(DisplayingScene) Then
            If DisplayingScene Is SpinScene Then FlexDMD.LockRenderThread:locked=true
        End If
        If spinval=AccumulatedSpinnerValue Then ' First spin this scene: clear the scene
            SpinScene.RemoveAll
            SpinScene.AddActor FlexDMD.NewLabel("level",tinyfont,"0")
            SpinScene.AddActor FlexDMD.NewLabel("spin", FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", RGB(167, 165, 165), vbWhite, 0),"SPINNER")
            SpinScene.AddActor FlexDMD.NewLabel("value",tinyfont,"0")
            SpinScene.GetLabel("spin").SetAlignedPosition 64,24, FlexDMD_Align_Center
        End If
        
        With SpinScene.GetLabel("level")
            .Text = "LEVEL "&SpinnerLevel
            .SetAlignedPosition 64,12, FlexDMD_Align_Center
        End With
        With SpinScene.GetLabel("value")
            .Text = FormatScore(AccumulatedSpinnerValue)
            .SetAlignedPosition 64,36, FlexDMD_Align_Center
        End With
        suffix="K":spinval = int(spinval/1000)
        If spinval >= 1000000 Then suffix="M":spinval = int(spinval/1000)
        SpinScene.AddActor FlexDMD.NewLabel("s"&SpinNum,FlexDMD.NewFont("udmd-f6by8.fnt", vbWhite, vbBlack, 1),spinval&suffix)
        x = RndNbr(100)+13
        y = RndNbr(20) + 16
        With SpinScene.GetLabel("s"&SpinNum)
            .SetAlignedPosition x,y, FlexDMD_Align_BottomLeft
            .AddAction SpinScene.GetLabel("s"&SpinNum).ActionFactory.MoveTo(x,0,0.4)
        End With
        SpinNum = SpinNum + 1
        If locked Then FlexDMD.UnlockRenderThread:locked=False
        DMDEnqueueScene SpinScene,2,500,2000,1500,""
    Else
        DisplayDMDText FormatScore(AccumulatedSpinnerValue),spinval,100
    End if
End Sub

Sub DMDCreateBWMBScoreScene
    If Not bUseFlexDMD Then Exit Sub
    Dim scene,i,ComboFont
    Set scene = FlexDMD.NewGroup("bwmb")
    scene.AddActor FlexDMD.NewLabel("line1", FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),"BLACKWATER"&vbLf&"PHASE 1")
    scene.AddActor FlexDMD.NewLabel("Score", FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),Score(CurrentPlayer))
    scene.GetLabel("Score").SetAlignedPosition 127,0,FlexDMD_Align_TopRight
    scene.AddActor FlexDMD.NewLabel("obj", FlexDMD.NewFont("udmd-f3by7.fnt", vbWhite, vbWhite, 0),"SHOOT GREEN JACKPOTS")
    scene.GetLabel("obj").SetAlignedPosition 64,18,FlexDMD_Align_Center
    BlinkActor scene.GetLabel("obj"),200,9999
    scene.AddActor FlexDMD.NewLabel("tmr1", FlexDMD.NewFont("udmd-f11by18.fnt", vbWhite, vbWhite, 0),"20")
    With scene.GetLabel("tmr1")
        .SetAlignedPosition 127,23,FlexDMD_Align_Center
        .Visible = 0
    End With
    ' Combo Multipliers
    Set ComboFont = FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0)
    For i = 1 to 5
        scene.AddActor FlexDMD.NewLabel("combo"&i, ComboFont, "0")
    Next
    DMDSetAlternateScoreScene scene,265     ' Score, Combos, SJP timer
    SetGameTimer tmrUpdateBattleMode,5
End Sub

' Set up an alternate score scene for battle mode. If two houses are stacked
' for battle, create a split screen scene
Sub DMDCreateAlternateScoreScene(h1,h2)
    Dim scene,scene1,scene2,vid,mask,i
    if Not bUseFlexDMD Then Exit Sub 
    If h2 <> 0 Then 
        Set scene = NewSceneWithVideo("battle","got-"&HouseToString(h2)&"battlesigil")
    ElseIf h1 = Baratheon or h1 = Greyjoy Then
        Set scene = NewSceneWithVideo("battle","got-"&HouseToString(h1)&"battlesigil")
    Else
        Set scene = NewSceneWithVideo("battle","got-"&HouseToString(h1)&"battleprogress")
    End If
    Set vid = scene.GetVideo("battlevid")
    If Not (vid Is Nothing) Then vid.SetAlignedPosition 127,0,FlexDMD_Align_TopRight
    If h2 <> 0 Then
        Set vid = FlexDMD.NewVideo("battlevid2","got-" & HouseToString(h1) & "battlesigil.gif")
        If Not (vid is Nothing) Then
            scene.AddActor vid
            Set vid = scene.GetVideo("battlevid2")
            vid.SetAlignedPosition 63,0,FlexDMD_Align_TopRight
        End If
        Set scene1 = FlexDMD.NewGroup(HouseToString(h1))
        Set scene2 = FlexDMD.NewGroup(HouseToString(h2))
        House(CurrentPlayer).BattleState(h1).CreateSmallBattleProgressScene scene1,1
        House(CurrentPlayer).BattleState(h2).CreateSmallBattleProgressScene scene2,2
        scene1.SetAlignedPosition 0,0,FlexDMD_Align_TopLeft
        scene2.SetAlignedPosition 64,0,FlexDMD_Align_TopLeft
        scene.AddActor scene1
        scene.AddActor scene2
        For i = 1 to 5
            scene.AddActor FlexDMD.NewLabel("combo"&i, FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbBlack, 1), "1X")
        Next
        mask = 104  ' combos, tmr1, tmr2
        If h1 = Targaryen or h2 = Targaryen Then 
            mask = mask Or 512 ' TGHurryUp
            If h1=Targaryen Then mask = mask And 223
            If h2=Targaryen Then mask = mask And 191
        End If
        If h1 = Martell or h2 = Martell Then mask = mask Or 144 'HurryUp, tmr3
    Else
        Set scene1 = FlexDMD.NewGroup(HouseToString(h1))
        House(CurrentPlayer).BattleState(h1).CreateBattleProgressScene scene1
        scene1.SetAlignedPosition 0,0,FlexDMD_Align_TopLeft
        scene.AddActor scene1
        mask = 41   ' score, combos, tmr1
        If h1 = Martell Then mask = 184
        If h1 = Targaryen Then mask = 521
    End If
    SetGameTimer tmrUpdateBattleMode,5
    DMDSetAlternateScoreScene scene,mask
End Sub

' We support multiple score "scenes", depending on what mode the table is in. Not all modes
' support all fields, so define a SceneMask that decides which fields need to be updated
'  bit   data (Label name)
'   0    Score
'   1    Ball
'   2    Credits
'   3    combo1 thru 5
'   4    HurryUp
'   5    BattleTimer1 (tmr1)
'   6    BattleTimer2 (tmr2)
'   7    MartellBattleTimer (tmr3)
'   8    SJP Timer (tmr1)
'   9    Targaryen HurryUp
'
' "scene" is a pre-created scene with all of the proper text labels already created. There MUST be a label
' corresponding with every bit set in the scenemask
Sub DMDSetAlternateScoreScene(scene,mask)
    bAlternateScoreScene = True
    Set ScoreScene = scene
    AlternateScoreSceneMask = mask
    DMDLocalScore
End Sub

' Set Score scene back to default for regular play
Sub DMDResetScoreScene
    bAlternateScoreScene = False
    If DisplayingScene Is ScoreScene Then DMDClearQueue
    ScoreScene = Empty
    AlternateScoreSceneMask = 0
    DMDLocalScore
End Sub

Dim ScoreScene,bAlternateScoreScene,AlternateScoreSceneMask
Sub DMDLocalScore
    Dim ComboFont,ScoreFont,i
    If bUseFlexDMD Then
        If IsEmpty(ScoreScene) And Not bAlternateScoreScene Then
            Set ScoreScene = FlexDMD.NewGroup("ScoreScene")
            Set ComboFont = FlexDMD.NewFont("FlexDMD.Resources.udmd-f4by5.fnt", vbWhite, vbWhite, 0)
            Set ScoreFont = FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbWhite, 0) 
            ' Score text
            ScoreScene.AddActor FlexDMD.NewLabel("Score", ScoreFont, "0")
            ' Ball, credits
            ScoreScene.AddActor FlexDMD.NewLabel("Ball", ComboFont, "BALL 1")
            ScoreScene.AddActor FlexDMD.NewLabel("Credit", ComboFont, "CREDITS 0")
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
            For i = 1 to 5
                ScoreScene.AddActor FlexDMD.NewLabel("combo"&i, ComboFont, "0")
            Next
        End If
        FlexDMD.LockRenderThread
        ' Update fields
        If bAlternateScoreScene = False or (AlternateScoreSceneMask And 1) = 1 Then ScoreScene.GetLabel("Score").Text = FormatScore(Score(CurrentPlayer))
        If bAlternateScoreScene = False or (AlternateScoreSceneMask And 2) = 2 Then ScoreScene.GetLabel("Ball").Text = "BALL " & CStr(BallsPerGame - BallsRemaining(CurrentPlayer) + 1)
        If Not bFreePlay And (bAlternateScoreScene = False or (AlternateScoreSceneMask And 4) = 4) Then 
            With ScoreScene.GetLabel("Credit")
                .Text = "CREDITS " & CStr(Credits)
                .SetAlignedPosition 96,20, FlexDMD_Align_Center
            End With
        End If
        
        If bAlternateScoreScene = False Then ScoreScene.GetLabel("Score").SetAlignedPosition 80,0, FlexDMD_Align_TopRight
        If bAlternateScoreScene = False or (AlternateScoreSceneMask And 8) = 8 Then
            ' Update combo x
            For i = 1 to 5
                With ScoreScene.GetLabel("combo"&i)
                    .Text = (ComboMultiplier(i)*PlayfieldMultiplierVal)&"X"
                    .SetAlignedPosition (i-1)*25,31,FlexDMD_Align_BottomLeft
                End With
            Next
        End If

        ' Update special battlemode fields
        If bAlternateScoreScene Then
            If (AlternateScoreSceneMask And 16) = 16 Then ScoreScene.GetLabel("HurryUp").Text = FormatScore(HurryUpValue)
            If (AlternateScoreSceneMask And 512)=512 Then ScoreScene.GetLabel("TGHurryUp").Text = FormatScore(TGHurryUpValue)
            If (AlternateScoreSceneMask And 32) = 32 Then ScoreScene.GetLabel("tmr1").Text = Int((TimerTimestamp(tmrBattleMode1) - GameTimeStamp)/10)
            If (AlternateScoreSceneMask And 64) = 64 Then ScoreScene.GetLabel("tmr2").Text = Int((TimerTimestamp(tmrBattleMode2) - GameTimeStamp)/10)
            If (AlternateScoreSceneMask And 128)=128 Then ScoreScene.GetLabel("tmr3").Text = Int((TimerTimestamp(tmrMartellBattle) - GameTimeStamp)/10)
            If (AlternateScoreSceneMask And 256)=256 Then ScoreScene.GetLabel("tmr1").Text = Int((TimerTimestamp(tmrBlackwaterSJP) - GameTimeStamp)/10)
        End If
        FlexDMD.UnlockRenderThread
        Set DefaultScene = ScoreScene
    Else
        DisplayDMDText "",FormatScore(Score(CurrentPlayer)),0
    End If
End Sub

Sub DMDDoMatchScene(m)
    Dim scene

    If bUseFlexDMD Then
        Set scene = FlexDMD.NewGroup("match")
        scene.AddActor FlexDMD.NewImage("bkgr","got-blankgrey.png")
        scene.AddActor FlexDMD.NewLabel("match1",FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbBlack, 1),"MATCH")
        scene.GetLabel("match1").SetAlignedPosition 84,16,FlexDMD_Align_CENTER
        If m = 0 Then m = "00"
        scene.AddActor FlexDMD.NewLabel("match2",FlexDMD.NewFont("FlexDMD.Resources.udmd-f7by13.fnt", vbWhite, vbBlack, 1),m)
        With scene.GetLabel("match2")
            .SetAlignedPosition 84,16,FlexDMD_Align_CENTER
            .Visible = 0
        End With
        DelayActor scene.GetLabel("match1"),4.2,False
        DelayActor scene.GetLabel("match2"),4.2,True
        scene.AddActor FlexDMD.NewLabel("Score1", FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),FormatScore(Score(1)))
        scene.GetLabel("Score1").SetAlignedPosition 1,1,FlexDMD_Align_TopLeft
        If PlayersPlayingGame > 1 Then 
            scene.AddActor FlexDMD.NewLabel("Score2", FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),FormatScore(Score(2)))
            scene.GetLabel("Score2").SetAlignedPosition 1,30,FlexDMD_Align_BottomLeft
        End If
        If PlayersPlayingGame > 2 Then
            scene.AddActor FlexDMD.NewLabel("Score3", FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),FormatScore(Score(3)))
            scene.GetLabel("Score3").SetAlignedPosition 126,1,FlexDMD_Align_TopRight
        End If
        If PlayersPlayingGame > 3 Then
            scene.AddActor FlexDMD.NewLabel("Score4", FlexDMD.NewFont("FlexDMD.Resources.teeny_tiny_pixls-5.fnt", vbWhite, vbWhite, 0),FormatScore(Score(4)))
            scene.GetLabel("Score4").SetAlignedPosition 126,30,FlexDMD_Align_BottomRight
        End If

        scene.AddActor NewSceneFromImageSequence("img1","match",280,30,0,0)
        DMDFlush
        DMDEnqueueScene scene,0,9000,9000,4000,"gotfx-match"
    Else
        DisplayDMDText "","MATCH "&m,8000
    End If
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

' √? Implement LoL outlanes - they should release new ball as soon as existing ball rolls over outlane, if ball saver not lit
'   - need to modify Drain and CreateNewBall code to not think we’re in multiball mode
' √ implement elevator logic
' - fix right ramp to upper PF
' - Implement playfield lighting effects
' √? Implement Wall MB countdown. Wall MB comes later
' √? Implement Extra Ball
' - Implement Flashers

' √? Baratheon didn't light as qualified until LOL targets had been completed 4 times
' √? need to reset drop targets for Baratheon mode
' √? top right gate doesn't close. top left does
' √? UFP targets got reset, maybe by "pass for now"?
' √? if you press "start" during end-of-game sequence, it'll start a new game but then go into attract mode
' √? At end of Martell mode, without scoring HurryUp, too many points were awarded. BattleTotal said 144M
' √? under some circumstances, last scene stays on indefinitely instead of returning to score or next scene
' - wrong top gate is left open after multi ball
' - no super jackpot said during SJP award
' √? after wic scored, shield didn’t change color right away
' √? after SJP ran out, didn’t relight shields of jackpots but was in that mode - Alter IncreaseBWJackpotLevel to set shield lights
' - instant info should not activate in battle or multi ball mode. 
' - testing for color=0 in flasher doesn't work

' Targaryen battle mode:
' - tmrhurryup is sometimes getting turned off during Targaryen
' - tmrhurryup didn't get started when mode was restarted
' √? In Targaryen mode, final hit of each level doesn’t register. Score isn’t included and doesn’t register. Oh, it probably executes too early. 
' √? Targaryen level 3 lights too many shots. 
' √? Match screen score font is too small. 
' - diverter doesn’t always close. 
' √ match win plays coin instead of knocker
' √? in attract mode, 11x18 score font is gigantic
' √ left ramp needs roof. 
' √? Targaryen battle mode needs to reset target bank
' √? in Battle mode, UPF shots don't turn off when hit (they used to!)
' √ UPF needs a down deflector on back exit ramp so ball can't bounce back into playfield
' - Elevator kickers are visible on UPF but are unfinished

' √? combo multiplier, or score, doesn't update until ball is back in play
''
' - gold targets need to be bouncier. 
' - battering ram needs to be less bouncy and more scattery
' - need more things awarding bonus
' - UPF can't handle multiball and battle at the same time - does it need to?


' √? If playing as Greyjoy, BattleReady is lit at start, even though no houses are qualified

' - Import DMD code for non FlexDMD. Use JP's Deadpool charset for now




' Nice-To-Haves
' - Change the timer for selecting which house mode to play. It will start at three seconds. Each button press will add eight seconds. The timer will max out at 20 seconds.
'    - Also, only display the instructions once per player.
' √? make "<n>X" in bonus multiplier image flash rapidly
' - fix blink patterns. Some lights do "110" pattern rather than 10
