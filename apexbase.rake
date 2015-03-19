require_relative 'lib/apexbase'

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