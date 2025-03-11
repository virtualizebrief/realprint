---
sidebar_position: 1
---

# Quick start

:::info Lets do this
🚀 Ready, set, go! 🚀
:::

## Network location

Create a network location: smb, unc, server share with these two folders.

```
\\server\realprint
\\server\realprint\database
```

## Download Real Print code 


> Link to [Github code](https://github.com/virtualizebrief/realprint).

Place files in `realprint` folder location

- realprint-agent.ps1
- realprint-manager.ps1
- convertto-textasciiart.ps1

## Edit Agent & Manager

Answer the following in each `realprint*.ps1` file. Once again same as above.

```
Set-Location "\\server\realprint\"
$dataBase = "\\server\realprint\database\"
```

## Configure endpoint and printer(s)

Run the following commands:

- `realprint-manager.ps1` to add a device, assign printer(s) and set default.
- `realprint-agent.ps1` on the device you just assigned printers.

Printers should now be connect tothe endpoint. Log files in `c:\support` with detailed results.

:::tip Mission Accomplished
You did it! Your first Real Print. Now if your feeling up to it lets dive deeper into what this thing can do.
:::








