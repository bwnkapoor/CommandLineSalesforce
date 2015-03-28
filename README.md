# CommandLineSalesforce

Salesforce file structure is crappy, lets admit it.  We cannot create subpackages, seperate controllers from Models, and have an actual extension for our static resouces.

This project aims to resolve this problem, by allowing you to build your own custom filing system.


**Salesforce Directory Hierarchy**
```
|
|--Classes
|   |--TestingUtils.cls
|   |--SomeCtrl.cls
|   |--SomeCtrlTest.cls
|   |--SomethingElse.cls
|--Triggers
|   |--Opportunity.trigger
|   |--Account.trigger
|   |--Ext.trigger
|--StaticResources
|   |--CssFileWithResourceExtForSomeReason.resource
|   |--JsFileWithResourceExtForSomeReason.resource
|--Pages
|   |--SomePage.page
    |--AnotherPage.page
```
Wouldn't you like to organize these files a little better?

**Custom Directory Hierarchy Example**
```
|
|--Controllers
|  |--SomeCtrl.cls
|  |--OtherCtrl.cls
|--Models
|  |--OpportunityModel.cls
|  |--AccountModel.cls
|  |--LeadModel.cls
|--Tests
|  |--OppportunityModelTest.cls
|  |--AccountModelTest.cls
|  |--LeadModelTest.cls
|--Triggers
|  |--Account.trigger
|  |--Opportunity.trigger
|--StaticResources
   |--css
   |  |--ssomething.css
   |  |--somethingElse.css
   |--js
      |--pageA.js
      |--pageB.js
```

To log-into salesforce you will need to create a user.

```
rake user:new
```


Now it's time to get to work
```
mkdir my_clients_project
cd my_clients_project
rake login[your_client_name,your_client_instance]
rake pull[TestingUtils.cls]
#rake pull without args can be used if a package.xml exists
rake save[classes/TestingUtils.cls]
```

Once you have pulled your files; you may move them to the desired file directory and execute.
```
rake log_symbolic_links
```
`Note, all static resources must exist within the base StaticResources directory in order to save the file again.`

This will produce "symbolic_table.yaml". Now when you rake pull for a file, it will pull the file into your clients root directory and create a symbolic link in your expected directory.

Current support allows for saving/pulling ApexClass, ApexPage, ApexComponent, StaticResource, and ApexTrigger
