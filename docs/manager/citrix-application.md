# Citrix application

*Simple to deploy Citrix application settings for Real Print manager*

## Code for launch file

Create a file named `realprint-manager.bat` and place it in the Real Print location.

- realprint-manager.bat

```
cls
@echo off
title Citrix Application Launcher
mode 75,15

@echo Real Print Manager
@echo Loading application. This could take a second...

powershell.exe -ExecutionPolicy Bypass -File "\\server\realprint\realprint-manager.ps1"
```

## Citrix Studio

Real Print Manager can be assigned to any delivery group. There is no local vda software required.


- Citrix application settings

<table>
  <tr>
    <td>**Executable**</td>
    <td>"\\\server\realprint\realprint-manager.bat"</td>
  </tr>
  <tr>
    <td>**Argument**</td>
    <td>(empty)</td>
  </tr>
  <tr>
    <td>**Working directory**</td>
    <td>"\\\server\realprint\"</td>
  </tr>
</table>


