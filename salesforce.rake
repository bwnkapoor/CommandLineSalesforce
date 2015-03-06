# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require_relative 'loadfile'
require 'yaml'
require 'find'

@logins_path = '/home/justin/buildTool/build_tool.yaml'

task :save, [:file_paths] do |t, args|
  store_environment_login
  to_save = args[:file_paths]
  if( !to_save )
    to_save = find_to_save
  end

  push to_save
        #args[:file_paths]]
end

def find_to_save
  to_save = []
  Find.find( '.' ) do |file|
    if /.*[.].*[~]/.match( file )
      actual_file = file.slice(0, file.length - 1)
      to_save.push actual_file
    end
  end
  to_save
end

task :pull, [:file_names] do |t, args|
  store_environment_login
  pull ["SendEmailWithSF_Attachments.cls", "SendEmailWithSF_Attachments.page"]#args[:file_names]
end

task :login, [:client, :environment] do |t, args|
  client = args[:client]
  environment = args[:environment]
  data = YAML.load_file @logins_path
  theClient = data["clients"][client]

  if theClient && theClient[environment]
    data["client"] = client
    data["environment"] = environment

    File.open(@logins_path, 'w') { |f| YAML.dump(data, f) }
  else
    puts "#{client} #{environment} does not exist"
  end
end

def store_environment_login
  data = YAML.load_file @logins_path
  client = data["client"]
  sandbox = data["environment"]

  begin
    creds = data["clients"][client][sandbox]
  rescue Exception=>e
    puts "Please login first"
    return
  end

  begin
    ENV["SF_USERNAME"] = creds["username"]
    ENV["SF_PASSWORD"] = creds["password"]
    ENV["SF_CLIENT_SECRET"] = "2764242436952695913"
    ENV["SF_HOST"] = "login.salesforce.com"
  rescue Exception=>e
    puts "Ensure you have a \"username\" and \"password\" for #{client} #{sandbox}"
  end
end