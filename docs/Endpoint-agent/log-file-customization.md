# Log file customization

Files are created in two formats and placed in `c:\support`

- Plain text
- CSV / spreadsheet format 

## How data is stored

Data is appended to any existing log file. This provides for an easy way to see an endpoints Real Print actions taken through out the day.

If an end user is roaming a Citrix Desktop you'll find all of the endpoints they have accessed and each printer actions taken on those given endpoints in one log file.

# Network storage

Real Print can be been configured to place log files in a subsequent folder along with the Real Print code files and database. One method is to add code for the following to the Real Print agent.

:::tip Endpoint folder
An alternative is to name the folder after endpoint instead of user.
:::

- Create folder named after the date, example: `20250310`
- Create folder named after the user: `user01`
- Copy log file into this path: `\\server\realprint\logs\20250310\user01`

Now you'll have the ability to find out this users activity on a given day.
