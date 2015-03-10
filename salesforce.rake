require_relative 'loadfile'
require 'yaml'
require 'find'
require_relative 'dependencies'
require_relative 'lib/readpackagexml'

@logins_path = '/home/justin/buildTool/build_tool.yaml'

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

task :play do
  store_environment_login
  cls = ApexClass.new( {Name: 'SendEmailWithSF_Attachments'} )
  ext = cls.extends
end

# cannot delete some components...
task :lazy do
  to_delete = find_members_of_type_in_package "ApexClass"
  known_cannot_delete = ["cc_ctrl_JQueryInclude",
  "cc_ctrl_Footer",
  "cc_ctrl_Schema",
  "cc_ctrl_SiteLogin",
  "cc_ctrl_HomePage",
  "cc_ctrl_ShippingAndHandling",
  "cc_ctrl_mediaTab",
  "cc_ctrl_CheckOut",
  "cc_ctrl_ProductDetail",
  "cc_ctrl_promotionExtension",
  "cc_ctrl_Coupon",
  "cc_ctrl_BreadCrumb",
  "cc_extn_ProductCatalog",
  "cc_ctrl_PriceList",
  "cc_hlpr_CyberSourceHOP",
  "cc_ctrl_documentTab",
  "cc_ctrl_GetSession",
  "cc_ctrl_GuidedSellingProfile",
  "cc_ctrl_ChangePassword",
  "cc_extn_HomePage",
  "cc_ctrl_SendEmail",
  "cc_ctrl_WishList",
  "cc_extn_cart",
  "cc_extn_PaymentShippingInfo",
  "cc_ctrl_InitData",
  "cc_ctrl_MyProfile",
  "cc_ctrl_ProductList",
  "cc_ctrl_PriceListItemTiers",
  "cc_ctrl_HTMLHead",
  "cc_ctrl_ProductListDisplayWidget",
  "cc_ctrl_Cart",
  "cc_ctrl_QuickOrder",
  "cc_util_Order",
  "cc_ctrl_MyOrderList",
  "cc_ctrl_IEIncludes",
  "cc_ctrl_RichText",
  "cc_ctrl_CartList",
  "cc_ctrl_PriceListExtension",
  "cc_ctrl_promotion",
  "cc_ctrl_RecentlyVisited",
  "cc_ctrl_Formatter",
  "cc_ctrl_Content",
  "cc_ctrl_MenuBar",
  "cc_ctrl_FeaturedProducts",
  "cc_bean_ProductForm",
  "cc_ctrl_CyberSourceReceipt",
  "cc_ctrl_CCPayPalJump",
  "cc_ctrl_CyberSourceHOP",
  "cc_ctrl_SpecificationsTab",
  "cc_ctrl_RelatedItems",
  "cc_extn_UserInfo",
  "cc_bean_ProductListViewData",
  "cc_ctrl_Admin",
  "cc_ctrl_CloudCraze",
  "cc_ctrl_AddToCart",
  "cc_ctrl_LocaleExtension",
  "cc_ctrl_CheckoutYourInformation"]
  cannot_delete = find_elements_cannot_delete to_delete, known_cannot_delete
  x = to_delete - cannot_delete
  x = x - known_cannot_delete
  byebug
  File.open('destruction.xml', 'w'){ |f| f.write "<members>" + x.join("</members>\n<members>") + "</members>" }
end

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

task :run_test, [:file_name, :sync] do |t, args|
  store_environment_login
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
  store_environment_login
  class_names = Salesforce.instance.query("Select Name from ApexClass where NamespacePrefix=null").map(&:Name)
  classes = ApexClass.dependencies class_names
  File.open('dependencies.yaml', 'w') {|f| f.write classes[:dependencies].to_yaml }
  File.open('not_defined.yaml', 'w') {|f| f.write classes[:symbol_tables_not_defined].to_yaml }
end

task :compile_all do
  store_environment_login

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
  store_environment_login
  all_apex_classes = Salesforce.instance.query( "Select Name from ApexClass where NamespacePrefix=null").map(&:Name)
  results = []
  all_apex_classes.each_with_index do |cls_name, i|
    puts "Running #{cls_name}"
    cls = ApexClass.new( Name: cls_name )
    cls.run_test
    res = cls.test_results.to_hash
    res['class'] = cls_name
    results.push res
    puts "#{i+1}/#{all_apex_classes.length} tests have ran"
  end
  File.open("test_results.yaml", 'w') { |f| YAML.dump(results, f) }
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

def find_classes_unaccounted_for
  store_environment_login
  all_apex_classes = []
  Salesforce.instance.query( "Select Name from ApexClass where NamespacePrefix=null").each { |pg|
    all_apex_classes.push( pg )
  }
  all_apex_classes = all_apex_classes.map(&:Name)
  all_apex_classes.each_index { |i| all_apex_classes[i] = all_apex_classes[i].upcase }
  classes = ApexClass.load_from_test_coverage
  accounted_for_classes = classes.map(&:name)
  byebug
  accounted_for_classes.each_index { |i| accounted_for_classes[i] = accounted_for_classes[i].upcase }
  missing_classes = all_apex_classes.select{ |class_name|
    !accounted_for_classes.include?(class_name)
  }
  missing_classes
end


def load_from_dependencies
  classes = {}
  data = YAML.load_file "./dependencies.yaml"
  data.each_key do |cls_name|
    classes[cls_name] = data[cls_name]
  end
  classes
end

def find_elements_cannot_delete attempt_to_delete, known_cannot_delete=[]
  all = load_from_dependencies
  list_to_delete = attempt_to_delete
  puts "Size: #{list_to_delete.length}"
  list_to_delete = list_to_delete - known_cannot_delete
  puts "Size: #{list_to_delete.length}"
  cannot_delete = []
  all.each_key do |org_class|
    classes_to_stay_due_to_dependencies = all[org_class] & list_to_delete
    if( ( classes_to_stay_due_to_dependencies ).length > 0 && !list_to_delete.include?(org_class) )
      cannot_delete.concat classes_to_stay_due_to_dependencies
    end
  end

  cannot_delete.uniq!
  if( !cannot_delete.empty? )
    puts "how many times?" + cannot_delete.length.to_s
    cannot_delete.concat find_elements_cannot_delete (attempt_to_delete-cannot_delete), cannot_delete
  end

  cannot_delete
end