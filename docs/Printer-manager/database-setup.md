# Database setup

*The real brains of the operation.*

# Flat file structure

In the past Real Print has been configured with SQL databases and the like. Yet in the spirit of demaking, simplifying and getting back to the basic things are now done with a flat file database. Using the popular [json](https://www.w3schools.com/js/js_json_intro.asp) format.


#### Example endpoint json file

```json
{
  "computer": {
    "name": "endpoint02",
    "printers": [
      {
        "name": "printer01",
        "server": "printserver01.domain.com",
        "isDefault": false
      },
      {
        "name": "printer02",
        "server": "printserver01.domain.com",
        "isDefault": true
      }
    ]
  }
}
```
