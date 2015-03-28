# CommandLineSalesforce

Salesforce file structure is crappy, lets admit it.  We cannot create subpackages, seperate controllers from Models, and have an actual extension for our static resouces.

This project aims to resolve this problem, with allowing you to build your own filing system.


Here is an example of the Salesforce File Hierarchy from what a developer cares about.
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

Your salesforce credentials will be stored in a yaml file.  Set configurator.logins in config.rb to the location of the credentials file.  Below is an example of the salesforce credentials file you will need to running the rake task login.

```
---
client_secret: "..."
client_id: "...."
clients:
  your_client_name:
    your_client_instance:
      username: username
      password: password
      local_root: client_name/codebase/staging/
      client: client_name
      instance: client_sandbox_name
      security_token: abc
      is_production: true/false
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

