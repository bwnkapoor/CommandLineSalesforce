require 'io/console'
require 'yaml'
require 'find'
require 'fileutils'

require_relative 'config'
require_relative 'loadfile'
require_relative 'dependencies'
require_relative 'lib/readpackagexml'
require_relative 'lib/file_watcher_task'
require_relative 'lib/user'
require_relative 'lib/apexbase'

task :monitor,[:client,:instance] do |t,args|
  User::login args[:client], args[:instance]
  do_watch
end

namespace :user do
  task :new do
    puts "Client:"
    client = $stdin.gets.chomp
    puts "Instance:"
    instance = $stdin.gets.chomp
    puts "Username:"
    username = $stdin.gets.chomp
    puts "Password:"
    password = $stdin.gets.chomp
    puts "Security Token:"
    security_token = $stdin.gets.chomp
    puts "is production?"
    is_production = $stdin.gets.chomp
    user = User::User.new({
                     "client": client, "instance": instance,
                     "username": username, "password": password,
                     "security_token": security_token, "is_production": is_production
            })
    user.save
  end
end

task :clients_working_directory,[:client,:instance] do |t,args|
  usr = User::get_credentials args[:client], args[:instance]
  if !Dir.exists?usr.full_path
    FileUtils.mkdir_p usr.full_path
  end
  puts usr.full_path
end

task :log_symbolic_links do
  User::login
  Find.find('.') do |file|
    begin
      cls = ApexBase::apex_member_factory(file)
      file_name = File.basename file, File.extname(file)
      cls = cls.new({Name: file_name})
      cls.load_from_local_file file
      cls.log_symbolic_link
    rescue Exception=>e
    end
  end
end

task :output_test_results do
  classes = ApexClass.load_from_test_coverage
  puts "Classes Ran: #{classes.length}"
  classes.each do |cls|
    if cls.test_results.failures?
      puts "Failing Class: #{cls.name}\n\n"
      puts cls.test_results.to_s
    end
  end
end

task :delete, [:file_path] do |t,args|
  User::login
  file_name = args[:file_path]
  member = ApexBase::apex_member_factory(file_name)
  type = File.extname( file_name )
  file_name = File.basename file_name, File.extname(file_name)
  to_delete = member.new( {Name: file_name} )
  res = to_delete.delete
  puts res
end

task :save, [:file_paths] do |t, args|
  User::login
  to_save = args[:file_paths]
  if( !to_save )
    to_save = find_to_save
  end

  push to_save
end

task :active do
  running_user = User::who_am_i
  puts "#{running_user.client.to_s},#{running_user.instance.to_s}"
  puts "session: #{running_user.oauth_token}"
end

task :creds, [:client, :environment] do |t, args|
  t = User::get_credentials args[:client], args[:environment]
  puts "Username: #{t.username}\nPassword: #{t.password}\nSecurity Token: #{t.security_token}"
end

task :force, [:client, :environment] do |t, args|
  client = User::get_credentials args[:client], args[:environment]
  cmd = "force login "
  if !client.is_production
    cmd += "-i=test "
  end
  cmd += "-u=#{client.username} -p=#{client.password}#{client.security_token}"
  system cmd
end

task :run_test, [:file_name, :sync] do |t, args|
  User::login
  test_file = args[:file_name]
  cls = ApexClass.new( {Name: test_file } )
  if args[:sync]
    cls.run_test
    test_results = cls.test_results
  else
    job = cls.run_test_async
    test_results = job.monitor_until_done
  end
  puts test_results.to_s
end

task :run_all_tests do
  User::login
  ApexClass.run_all_tests
end

task :pull, [:file_names] do |t, args|
  User::login
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
  User::logins args[:client]
end

task :chrome_incog, [:client, :environment] do |t, args|
  client = User::get_credentials args[:client], args[:environment]
  server_url = client.is_production ? "https://login.salesforce.com" : "https://test.salesforce.com"
  cmd = "google-chrome --incognito \"#{server_url}?un=#{client.username}&pw=#{client.password}\""
  system cmd
end

task :chrome, [:client, :environment] do |t, args|
  client = User::get_credentials args[:client], args[:environment]
  server_url = client.is_production ? "https://login.salesforce.com" : "https://test.salesforce.com"
  cmd = "google-chrome \"#{server_url}?un=#{client.username}&pw=#{client.password}\""
  system cmd
end

task :logout do
  User::logout
end

task :login, [:client, :environment] do |t, args|
  User::login args[:client], args[:environment]
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
