# Scheduled task

*Automate running Real Print agent*

Setup Real Print to run at user login and user reconnect on machines to run Real Print agent.

# Windows server or desktop
- Open: `Computer Management`
- System Tools > Task Schedule > Right click: Task Scheduler Library & select: `Create Task...`

#### General tab
- Run only when user is logged on, change user to: `Users`

#### Triggers tab
- On connection to user session
- On workstation unlock

#### Actions tab
- Start a program
- Program/script: mshta
- Add arguments: vbscript:Execute("CreateObject(""WScript.Shell"").Run ""powershell -ExecutionPolicy Bypass & '\\\server\realprint\realprint-agent.ps1'"", 0:close")

## Thoughts

There are a few different ways to run the command, some pure powershell, others with an accompanying bat file and the above with a call to mshta. In the end the result should be silent with a hidden function, not displaying a box for the end user to see.


