---
sidebar_position: 8
---

# Troubleshooting

General list of things that may come up. For those looking to post a bug or submit a feature request find use at [Real Print Github Issues](https://github.com/virtualizebrief/realprint/issues).

<details>

  <summary>Unable to connect to database</summary>

Make user end user can get to the Real Print database path and at minimum read / open files. If they cannot, the Real Print agent will be unable to aquire printer information.

#### Example Real Print database location
```
\\server\realprint\database 
```

</details>

<details>

  <summary>Default printer not set</summary>

This is tricky since other applications, services, group policy, endpoint passthrough all can be working to, in addition to Real Print, set a default printer.

## Adjust defalut retry attempts

Edit `realtype-agent.ps` and increase the number of attemps to set the default. The goal here is for Real Print to have the last say, to be the last one to set default printer.

```
# default printer tries
$maxTries = 5 #adjust maxTries until Real Print wins the day for setting default.
$tries = 0 #do not adjust, this is needed to start ties at 0.
$condition = $false #do not adjust, this keeps the agent knowing default has yet to be set.
```
  
</details>
