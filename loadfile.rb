require 'byebug'
require 'fileutils'
require 'date'
require_relative 'lib/containerasyncrequest'
require_relative 'lib/metadatacontainer'
require_relative 'lib/apexclass'
require_relative 'lib/apexpage'
require_relative 'lib/apexcomponent'
require_relative 'lib/apexstaticresource'
require_relative 'lib/apextrigger'

def write files
  files.each do |sf_file|
    FileUtils.mkdir_p sf_file.folder
    f = File.new( sf_file.path, "w" )
    f.write( sf_file.body )
    f.close
  end
end

def pull file_names
  puts "pulling"
  files = []
  puts file_names.to_s
  file_names.each do |file|
    type = File.extname( file )
    file_name = File.basename file, File.extname(file)
    type = apex_member_factory( type )
    if( type  )
      member = type.pull( [file_name] )
      files.concat( member )
    end
  end
  write files
  puts "done"
end

def apex_member_factory(file_name)
  type = File.extname( file_name )
  file_name = File.basename file_name, File.extname(file_name)

  if( type == ".cls" )
    ApexClass
  elsif( type == ".page" )
    ApexPage
  elsif( type == ".component" )
    ApexComponent
  elsif( type == ".trigger" )
    ApexTrigger
  else
    puts "Not Supported Type #{type}"
    nil
  end
end

def push files_paths_to_save
  puts 'pushing...'
  container = MetadataContainer.new( DateTime.now.to_time.to_i.to_s )
  container.save()
  if files_paths_to_save.class != Array then files_paths_to_save = [files_paths_to_save] end
  files_paths_to_save.each do |to_save_path|
    type = apex_member_factory( to_save_path )

    if( type )
      cls = type.new()
      cls.load_from_local_file(to_save_path)
      saving_classes = { cls.name=>cls }
      puts cls.save( container )
      puts "saving..."
    else
      puts "Failed to save #{to_save_path}"
    end
  end

  asynch = ContainerAsyncRequest.new( container.id )
  deploy_id = asynch.save
  results = nil
  while !results || (results.State != 'Completed' && results.State != 'Failed')
    puts "sleeping"
    sleep(1)
    results = Salesforce.instance.metadata_query "Select DeployDetails, State from ContainerAsyncRequest where id = \'#{deploy_id}\'"
    results = results.body.current_page[0]
  end

  has_errors = false
  results.DeployDetails.allComponentMessages.each do |message|
    fileName = message.fileName.to_s
    if message.success then puts "Success" else puts "Oh No!" end
    if !message.success
      has_errors = true
      puts message.problem.to_s
      puts message.lineNumber.to_s
      puts message.problemType.to_s
      #puts saving_classes[fileName].local_name
    end
  end

  if !has_errors
    puts "Saved"
  end
end
