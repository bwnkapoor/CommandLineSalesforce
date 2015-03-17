require 'io/console'
require 'yaml'
require 'find'

require_relative 'loadfile'
require_relative 'dependencies'
require_relative 'lib/readpackagexml'
require_relative 'lib/file_watcher_task'
require_relative 'lib/user'

task :monitor do
  User::login
  do_watch
end

task :log_symbolic_links do
  User::login
  Find.find('.') do |file|
    begin
      cls = apex_member_factory(file)
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
      cls.test_results.failures.each do |fail|
        puts "MethodName: #{fail['methodName']}"
        puts "Trace: #{fail['stackTrace']}"
        puts "Message: #{fail['message']}\n\n"
        log_id = fail['logid']
        if log_id
          puts "LogId: #{log_id}"
        end
      end
      puts "------------------------------------------------------------------------------------------------------------------------------------------"
    end
  end
end

task :delete, [:file_path] do |t,args|
  User::login
  file_name = args[:file_path]
  member = apex_member_factory(file_name)
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
  puts "#{running_user.username.to_s},#{running_user.instance.to_s}"
end

task :creds, [:client, :environment] do |t, args|
  t = User::get_credentials args[:client], args[:environment]
  puts "Username: #{t.username}\nPassword: #{t.password}"
end

task :force, [:client, :environment] do |t, args|
  client = User::get_credentials args[:client], args[:environment]
  cmd = "force login "
  if !client.is_production
    cmd += "-i=test "
  end
  cmd += "-u=#{client.username} -p=#{client.password}"
  system cmd
end

task :run_test, [:file_name, :sync] do |t, args|
  User::login
  test_file = args[:file_name]
  cls = ApexClass.new( {Name: test_file } )
  if args[:sync]
    cls.run_test
  else
    cls.run_test_async
  end

  if( cls.test_results )
    puts "Success Rate: #{cls.test_results.successes.length}/#{cls.test_results.num_tests_ran}"
    cls.test_results.failures.each do |fail|
      puts "MethodName: #{fail['methodName']}"
      puts "Message: #{fail['message']}"
      puts "StackTrace: #{fail['stackTrace']}"
      log_id = fail['logid']
      if( log_id )
        puts "LogId: #{log_id}"
      end
      puts "-----------------------"
    end
  end
end

task :log_dependencies do
  User::login
  pages = ApexPage.dependencies Salesforce.instance.query("Select Name from ApexPage where NamespacePrefix=null").map(&:Name)
  components = ApexComponent.dependencies Salesforce.instance.query("Select Name from ApexComponent where NamespacePrefix=null").map(&:Name)
  classes = ApexClass.dependencies Salesforce.instance.query("Select Name from ApexClass where NamespacePrefix=null").map(&:Name)
  dependencies = {"components"=>components, "pages"=>pages, "classes"=>classes[:dependencies]}
  File.open('dependencies.yaml', 'w') {|f| f.write dependencies.to_yaml }
  File.open('not_defined.yaml', 'w') {|f| f.write classes[:symbol_tables_not_defined].to_yaml }
end

task :compile_all do
  User::login

  classes = Salesforce.instance.query( "Select Id,Name,Body from ApexClass where NamespacePrefix=null")
  chunking_size = 20
  classes.each_slice( chunking_size ).to_a.each_with_index do |chunk, i|
    container = MetadataContainer.new( DateTime.now.to_time.to_i.to_s )
    puts "saving the container"
    container.save()

    chunk.each_with_index do |cls, i|
      puts "Saving... #{cls.Name}"
      cls = ApexClass.new( cls )
      cls.save container
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
    else
      puts "Failed to save #{container.id}"
    end

    puts "Compiled #{i+1}/#{chunking_size}"
  end
end

task :run_all_tests do
  User::login
  all_apex_classes = Salesforce.instance.query( "Select Name from ApexClass where NamespacePrefix=null").map(&:Name)
  all_apex_classes.each_with_index do |cls_name, i|
    puts "Running #{cls_name}"
    cls = ApexClass.new( Name: cls_name )
    cls.run_test
    puts "#{i+1}/#{all_apex_classes.length} tests have ran"
  end
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
