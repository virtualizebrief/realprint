---
sidebar_position: 1
---

# Real Print agent

*How endpoints connect to printers: realprint-agent.ps1*

:::warning Database
User needs read permission to real print database.
:::

Endpoint agent for querying real print database and connecting printers. Call agent at user login and user reconnect in task scheduler or when whenever desired. 

### Performs the following
- [x] Connect to real print database by endpoint name
- [x] Get list of assigned printers and default
- [x] Compare to what end point already has connected
- [x] Attempt to connect printers missing and remove those not listed
- [x] Set default. this is attempted a number of times and can be customized
- [x] Write log file containing detailed results

Log file can be kept local to the machine and is by default in `c:\support`. This can be scripted to copied to a network location for archiving or quick historical access.

### Example log file
```
20240319T115446 =========================================
20240319T115446   Real Print
20240319T115446   Release: 2024.03.19
20240319T115446 =========================================
20240319T115446   ...Running User Processes
20240319T115446   ...User found: michaelwood
20240319T115446   ...Endpoint: Office
20240319T115446   ...Citrix Desktop: MyDesk
20240319T115446
20240319T115446   Printer processing...
20240319T115446   -------------------------------
20240319T115446   deleting: none
20240319T115447   adding  : \\printserver1.mydomain.com\printer1
20240319T115447   adding  : \\printserver1.mydomain.com\printer3
20240319T115447   default : \\printserver1.mydomain.com\printer3
20240319T115447   default : attempt 1 of 5 (20 second pause between)
20240319T115507   default : attempt 2 of 5 (20 second pause between)
20240319T115527   default : attempt 3 of 5 (20 second pause between)
20240319T115547   default : attempt 4 of 5 (20 second pause between)
20240319T115607   default : attempt 5 of 5 (20 second pause between)
20240319T115607   -------------------------------
20240319T115607   Seconds to complete work: 41
