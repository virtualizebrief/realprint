---
sidebar_position: 1
---

# realprint-manager.ps1
:::info Database format
Real print uses a flat file database. You can use a sql database and we have successful implementions using them. For simplicity on GitHub code has been written to use a flat file database structure.
:::

Manager provides a frontend for assigning printers to endpoints. Screen capture tells the story.

![image](https://github.com/virtualizebrief/collection/assets/153381859/d9d288c0-3146-4a6e-b259-91d14e0e4190)

## [convertto-textasciiart.ps1](convertto-textasciiart.ps1)
:::tip
This feature is optional and can be disabled but it looks cool.
:::

Creates the cool banner logo for real print manager.

# List print servers and printers

:::danger Beta feature
Does not always work.
:::

Since some networks and endpoints are locked down more than others the code used to get a list of all printers on all print servers is suspect to being blocked or failing to run.

This can be tailored to your specific environment. There are some fancy means of using markdown and publishing to a frontend website with a polished look to present this data. Many things to consider and build out, endless possibilities for customization.
