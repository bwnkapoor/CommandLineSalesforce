require_relative 'lib/apexbase'
require_relative 'lib/workflowrule'

namespace :apexclass do
  task :new do
    ApexBase.create "template.cls"
  end
end

namespace :apextrigger do
  task :new do
    ApexBase.create "template.trigger"
  end
end

namespace :apexpage do
  task :new do
    ApexBase.create "template.page"
  end
end

namespace :apexcomponent do
  task :new do
    ApexBase.create "template.component"
  end
end

namespace :staticresource do
  task :new do
    ApexBase.create "template.resource"
  end
end

namespace :workflowrule do
  task :pull,[:name] do |t, args|
    User::login
    workflow_rule = ApexBase.do_pull WorkflowRule,''
    res = workflow_rule.save
  end
end