require 'byebug'
require 'fileutils'
require 'date'
require 'yaml'
require_relative 'lib/containerasyncrequest'
require_relative 'lib/metadatacontainer'
require_relative 'lib/apexclass'
require_relative 'lib/apexpage'
require_relative 'lib/apexcomponent'
require_relative 'lib/apexstaticresource'
require_relative 'lib/apextrigger'

@logins_path = '/home/justin/buildTool/build_tool.yaml'

def write files
  files.each do |sf_file|
    sf_file.find_symbol_local_link
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
    begin
      type = apex_member_factory( file )
      member = type.pull( [file_name] )

      files.concat( member )
    rescue Exception=>e
    end
  end
  write files
  puts "done"
end

def apex_member_factory(file_name)
  type = File.extname( file_name )
  whole_name = file_name
  file_name = File.basename file_name, File.extname(file_name)

  if( type == ".cls" )
    ApexClass
  elsif( type == ".page" )
    ApexPage
  elsif( type == ".component" )
    ApexComponent
  elsif( type == ".trigger" )
    ApexTrigger
  elsif( type == ".resource" || File.dirname(whole_name).end_with?("staticresources") )
    ApexStaticResource
  else
    raise "Not Supported Type #{type}"
  end
end

def push files_paths_to_save
  puts 'pushing...'
  container = MetadataContainer.new( DateTime.now.to_time.to_i.to_s )
  container.save()
  if files_paths_to_save.class != Array then files_paths_to_save = [files_paths_to_save] end
  files_paths_to_save.each do |to_save_path|
    begin
      type = apex_member_factory( to_save_path )
      base_name = File.basename(to_save_path, File.extname(to_save_path))
      cls = type.new({Name: base_name })
      cls.load_from_local_file(to_save_path)
      puts cls.save( container )
      puts "saving..."
    rescue Exception=>e
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
    results = results.current_page[0]
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
      puts "For class: #{message.fileName}\n\n"
    end
  end

  if !has_errors
    puts "Saved"
  end
end

def login client=nil, environment=nil
  if client && environment
    login_as_user client, environment
  else
    login_with_current_credentials
  end
end

def login_as_user client, environment
  data = YAML.load_file @logins_path
  theClient = data["clients"][client]

  if theClient && theClient[environment]
    data["client"] = client
    data["environment"] = environment
    File.open(@logins_path, 'w') { |f| YAML.dump(data, f) }
  else
    raise "#{client.to_s} #{environment.to_s} does not exist"
  end
end

def login_with_current_credentials
  creds = who_am_i

  begin
    ENV["SF_USERNAME"] = creds["username"]
    ENV["SF_PASSWORD"] = creds["password"]
    isProd = creds["is_production"]
    ENV["SF_CLIENT_SECRET"] = "2764242436952695913"
    ENV["SF_HOST"] = isProd ? "login.salesforce.com" : "test.salesforce.com"
  rescue Exception=>e
    puts "Ensure you have a \"username\" and \"password\" for #{client} #{sandbox}"
  end
end

def who_am_i
  data = YAML.load_file @logins_path
  client = data["client"]
  sandbox = data["environment"]
  begin
    creds = data["clients"][client][sandbox]
  rescue Exception=>e
    puts "Please login first"
    return
  end
  creds
end
