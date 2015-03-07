require_relative 'loadfile'
require 'yaml'
require 'find'
require_relative 'dependencies'
require_relative 'lib/readpackagexml'

@logins_path = '/home/justin/buildTool/build_tool.yaml'

task :save, [:file_paths] do |t, args|
  store_environment_login
  to_save = args[:file_paths]
  if( !to_save )
    to_save = find_to_save
  end

  push to_save
end

task :active do
  data = YAML.load_file @logins_path
  client = data["client"]
  sandbox = data["environment"]
  puts "#{client},#{sandbox}"
end

task :creds, [:client, :environment] do |t, args|
  t = get_creds( args )
  puts "Username: #{t['username']}\nPassword: #{t['password']}"
end

task :force, [:client, :environment] do |t, args|
  client = get_creds( args )
  cmd = "force login "
  if !client["is_production"]
    cmd += "-i=test "
  end
  cmd += "-u=#{client['username']} -p=#{client['password']}"
  system cmd
end

task :play, [:file_name] do |t, args|
  store_environment_login
  #records_to_delete = Array.new
  #records_to_delete.push( Hash[{"id"=>"01p17000000DNfyAAG"}] )
  x = Salesforce.instance.restforce.destroy( "ApexClass", "01pG0000004sytgIAA" )
=begin
  records_to_delete = []
  to_delete = {"Id"=>"01pj0000003DYg4AAG"}
  records_to_delete.push( to_delete )
  x = Salesforce.instance.bulk.delete( "ApexClass", records_to_delete, true )
=end
  byebug
  puts "Hello"
end

task :compile_find_dependencies, [:file_name] do |t, args|
  store_environment_login
=begin
  file_name = args[:file_name]
  puts "Reading package.xml"
  classes = find_members_of_type_in_package 'ApexClass'
  classes = ApexClass.dependencies classes
  File.open('test.yml', 'w') {|f| f.write classes.to_yaml }
=end
  data = YAML.load_file 'test.yml'
  puts data.keys.length
  name_to_dependencies = remove_non_keys( data )
  cyclical = findStrongTies(name_to_dependencies)

  puts "The following items have Cyclical Dependencies #{cyclical}"

  puts "We have cyclical: #{cyclical.length}"

  name_to_dependencies = non_cyclical( name_to_dependencies )
  byebug
  to_sort = remove_non_keys( name_to_dependencies )
  byebug
  our_sort = to_sort.tsort
  puts "We can remove: #{our_sort.length} items here is the order\n"
  puts our_sort

end

task :pull, [:file_names] do |t, args|
  store_environment_login
  to_pull = args[:file_names]
  if !to_pull
    to_pull = readPackageXML
  end

  if to_pull.class != Array
    to_pull = [to_pull]
  end
  pull to_pull
end

task :logins, [:client] do |t, args|
  data = YAML.load_file @logins_path
  if( args[:client] )
    begin
      data["clients"][args[:client]].each_key do |sandbox|
        puts "#{args[:client]},#{sandbox}"

      end
    rescue Exception=>e
      puts "The Client: \"#{args[:client]}\" does not have a login"
    end
  else
    data["clients"].each_key do |client|
      data["clients"][client].each_key do |sandbox|
        puts "#{client},#{sandbox}"
      end
    end
  end
end

task :chrome_incog, [:client, :environment] do |t, args|
  client = get_creds( args )
  server_url = client["is_production"] ? "login.salesforce.com" : "test.salesforce.com"
  cmd = "google-chrome --incognito \"#{server_url}?un=#{client['username']}&pw=#{client['password']}\""
  system cmd
end

task :chrome, [:client, :environment] do |t, args|
  client = get_creds( args )
  server_url = client["is_production"] ? "login.salesforce.com" : "test.salesforce.com"
  cmd = "google-chrome \"#{server_url}?un=#{client['username']}&pw=#{client['password']}\""
  system cmd
end

task :logout do
  data = YAML.load_file @logins_path
  data["client"] = ""
  data["environment"] = ""
  data["session_id"] = ""

  File.open(@logins_path, 'w') { |f| YAML.dump(data, f) }
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

task :sfwho do
  data = YAML.load_file @logins_path
  client = data["client"]
  sandbox = data["environment"]
  puts "Client: \"#{client}\"\nEnvironment: \"#{sandbox}\""
end

def store_environment_login
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

def get_creds( args )
  client = args[:client]
  enviro = args[:environment]
  if( client && enviro )
    data = YAML.load_file @logins_path
    client = data["clients"][client][enviro]
  else
    client = who_am_i
  end
end
