require 'fileutils'
require 'date'
require 'yaml'
require_relative 'lib/apexbase'
require_relative 'lib/containerasyncrequest'
require_relative 'lib/metadatacontainer'
require_relative 'lib/apexclass'
require_relative 'lib/apexpage'
require_relative 'lib/apexcomponent'
require_relative 'lib/apexstaticresource'
require_relative 'lib/apextrigger'

def pull file_names
  puts "pulling"
  files = []
  puts file_names.to_s
  file_names.each do |file|

    type = File.extname( file )
    file_name = File.basename file, File.extname(file)
    begin
      type = ApexBase::apex_member_factory( file )
      member = ApexBase::pull( [file_name], type )
      member.each{ |base|
        base.write_file
        base.write_symbolic_links
      }
      files.concat( member )
    rescue Exception=>e
      puts e
    end
  end
  puts "done"
end

def push files_paths_to_save
  puts 'pushing...'
  container = MetadataContainer.new( DateTime.now.to_time.to_i.to_s )
  container.save()
  if files_paths_to_save.class != Array then files_paths_to_save = [files_paths_to_save] end
  files_paths_to_save.each do |to_save_path|
    begin
      type = ApexBase::apex_member_factory( to_save_path )
      base_name = File.basename(to_save_path, File.extname(to_save_path))
      cls = type.new({Name: base_name })
      cls.load_from_local_file(to_save_path)
      puts cls.save( container )
      puts "saving..."
    rescue Exception=>e
      puts "Failed to save #{to_save_path} #{e}"
    end
  end

  asynch = ContainerAsyncRequest.new( container.id )
  deploy_id = asynch.save
  results = asynch.monitor_until_complete

  if results.State != "Error"
    has_errors = false
    results.DeployDetails.allComponentMessages.each do |message|
      fileName = message.fileName.to_s
      if message.success then puts "Success" else puts "Oh No!" end
      if !message.success
        has_errors = true
        puts message.problem.to_s
        puts message.lineNumber.to_s
        puts message.problemType.to_s
        puts "For class: #{message.fileName}\n\n"
      end
    end

    if !has_errors
      puts "Saved"
    end
  else
    puts "We have an unknown error"
  end
end
