# CommandLineSalesforce

Salesforce file structure is crappy, lets admit it.  We cannot create subpackages, seperate controllers from Models, and have an actual extension for our static resouces.

This project aims to resolve this problem, by allowing you to build your own filing system.


Salesforce Directory Hierarchy
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

Wouldn't you rather have something like this?
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

To create a new login run

```
rake user:new
```


Here is how you would begin working on a project for a client.
```
mkdir my_clients_project
cd my_clients_project
rake login[your_client_name,your_client_instance]
rake pull[TestingUtils.cls]
#rake pull without args can be used if a package.xml exists
rake save[classes/TestingUtils.cls]
```

You may now begin to build your file structure.  Note, all static resources must exist in some directory within StaticResources in order to determine a file is actually a salesforce static resource.

Once you have decided on a file structure you may run,
```
rake log_symbolic_links
```
You will end with a file called "symbolic_table.yaml", now when you rake pull for a file, it will place the file in the directory you have choosen for that file.

Here is an example of what your file structure could look like.  Current support allows for saving 
ApexClass, ApexPage, ApexComponent, StaticResource, and ApexTrigger


