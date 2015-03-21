require_relative 'lib/apexbase'
require_relative 'lib/workflowrule'
require_relative 'lib/validationrule'

namespace :apexclass do
  task :new do
    ApexBase.create "template.cls"
  end
end

namespace :apextrigger do
  task :new do
    ApexBase.create "template.trigger"
  end

  task :deactivate,[:name] do |t,args|
    User::login
    inst = ApexTrigger.get_class_sf_instance(args[:name]).current_page[0]

    trg = ApexTrigger.new( inst )
    trg.metadata.status = 'inactive'
    container = MetadataContainer.new( DateTime.now.to_time.to_i.to_s )
    container.save()
    trg.save( container )
    asynch = ContainerAsyncRequest.new( container.id )
    deploy_id = asynch.save
    asynch.monitor_until_complete
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

namespace :validationrule do
  task :pull,[:name] do |t, args|
    User::login
    validation_rule = ApexBase.do_pull ValidationRule,''
    byebug
    res = validation_rule.save
  end
end