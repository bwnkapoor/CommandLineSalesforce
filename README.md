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

Logging in to Salesforce is done via a file existing in
~/buildTool/build_tool.yaml
Below is an example of what build_tool.yaml would look like.

```
---
client_secret: "..."
client_id: "...."
clients:
  your_client_name:
    you_client_instance:
      username: username
      password: password
      local_root: client_name/codebase/staging/
      client: client_name
      instance: client_sandbox_name
      security_token: abc
      is_production: true/false
```

You will need to make some changes to lib/User.rb
  1. The LOGIN_PATH will need to point to where you store your build_tool.yaml
  2. the ROOT_DIR is the root of where the Salesforce files will be stored, files in this directory will match Salesforces file schema.  When a pull is done, files get stored in User.full_path
  
Once you are finished you may begin to work.

```
mkdir my_client_dir
cd my_client_dir
rake login[your_client_name,your_client_instance]
rake pull[TestingUtils.cls]
#rake pull without args can be used if a package.xml exists
rake save[classes/TestingUtils.cls]
```

You may then begin to build your file structure.  Note, all static resources must exist in some directory within StaticResources in order to determine a file is actually a salesforce static resource.

Once you have decided on a file structure you like run,
```
rake log_symbolic_links
```
You will end with a file called "symbolic_table.yaml", now when you rake pull it will know what directory to go to.

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

