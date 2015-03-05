require 'fileutils'
require 'date'
require_relative 'lib/containerasyncrequest'
require_relative 'lib/metadatacontainer'
require_relative 'lib/apexclass'
require_relative 'lib/apexpage'
require_relative 'lib/apexcomponent'
require_relative 'lib/apexstaticresource'

def write files
  files.each do |sf_file|
    FileUtils.mkdir_p sf_file.folder
    f = File.new( sf_file.path, "w" )
    f.write( sf_file.body )
    f.close
  end
end

def pull
  cls = ApexClass.new( { :Name=>'TestController' } )
  cls.pull
  cls2 = ApexClass.new( { :Name=>'TestController2' } )
  cls2.pull
  pg = ApexPage.new( {:Name=>"SendEmailWithSF_Attachments"} )
  pg.pull
  comp = ApexComponent.new( {:Name=>"Test"} )
  comp.pull
  resource = ApexStaticResource.new( {:Name=>"sobject_lookup"} )
  resource.pull
  write [cls, cls2, pg, comp, resource]
end

def push
  container = MetadataContainer.new('test', '1dcj0000000gyfB')

  cls = ApexClass.new()
  cls.save container

  asynch = ContainerAsyncRequest.new('1dcj0000000gyfB')
  puts "Saving..."
  puts asynch.save
  puts "done"
end

container = MetadataContainer.new( DateTime.now.to_time.to_i.to_s )
container.save()
cls = ApexClass.new()
cls.load_from_local_file("humbug/TestController2.cls")
saving_classes = { cls.name=>cls }
puts cls.save( container )
puts "saving..."
asynch = ContainerAsyncRequest.new( container.id )
deploy_id = asynch.save
puts "done"
results = nil
while !results || (results.State != 'Completed' && results.State != 'Failed')
  puts "sleeping"
  sleep(1)
  results = Salesforce.instance.metadata_query "Select DeployDetails, State from ContainerAsyncRequest where id = \'#{deploy_id}\'"
  results = results.body.current_page[0]
end

results.DeployDetails.allComponentMessages.each do |message|
  fileName = message.fileName.to_s
	if message.success then puts "Success" else puts "Oh No!" end
	if !message.success
		puts message.problem.to_s
		puts message.lineNumber.to_s
		puts message.problemType.to_s
		puts saving_classes[fileName].local_name
	end
end
