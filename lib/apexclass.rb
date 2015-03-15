require 'yaml'
require_relative 'salesforce'
require_relative 'apexbase'
require 'byebug'
require_relative 'apextestresults'
require_relative 'salesforce_job'

class ApexClass
  include ApexBase
  attr_reader :name, :folder, :id, :body, :local_name

  def file_ext
    return '.cls'
  end

  def test_results
    if !@test_results
       data = YAML.load_file 'test_results.yaml'
      if data[@name]
        @test_results = data[@name]
      else
        @test_results = run_test
      end
    end
    @test_results
  end

  def test_class?
    return test_results.num_tests_ran > 0
  end

  def initialize(options={})
    @body = options[:Body]
    @id = options[:Id]
    @test_results = options[:TestResults]
    @folder = 'classes'
    @name = options[:Name]
  end

  def type
    "ApexClass"
  end

  def id
    if !@id
      definition = get_class_sf_instance.current_page
      if !definition.empty?
        @id = definition[0].Id
      end
    end

    @id
  end

  def extends
    if !@body
      @body = get_class_sf_instance.current_page[0].Body
    end
    matches = @body.match Regexp.new( "[global|public|private][ ]+[with|without sharing]{0,1}[ ]*class[ ]+[A-Za-z0-9_]+[ ]+extends[ ]+([A-Za-z0-9_.]+)", true )

    if( matches )
      return matches.captures[0]
    end
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  # Dependencies currently are not supporting implements and variables of the class
  def self.get_dependencies class_name
    dependencies = []
    x = Salesforce.instance.metadata_query( "Select SymbolTable, MetaData, FullName from ApexClassMember where FullName = \'#{class_name}\' order by createddate desc limit 1" )
    x.current_page.each do |classMember|
      if classMember.SymbolTable
        classMember.SymbolTable.externalReferences.each do |xRef|
          dependencies.push xRef.name.to_s
        end
        cls = ApexClass.new( {Name: class_name} )
        ext = cls.extends
        if ext
          dependencies.push ext
        end
      else
        raise "No table exists! #{classMember}"
      end
    end
    puts "Dependencies for #{class_name}\n#{dependencies}"
    dependencies
  end

  def pull
    file_request = get_class_sf_instance
    cls = file_request.current_page[0]
    if cls
      @body = cls.Body
      @id = cls.Id
    else
      raise "Class DNE #{self.name}"
    end
  end

  def self.pull fileNames
    classes = []
    if fileNames.length == 1 && fileNames[0] == "*"
      fileNames = Salesforce.instance.query( "Select Name from ApexClass where Namespaceprefix=null" ).map(&:Name)
    end
    fileNames.each do |file|
      cls = ApexClass.new( {Name: file} )
      begin
        cls.pull
        classes.push cls
      rescue Exception=>e
        puts e.to_s
      end
    end
    classes
  end

  def self.dependencies class_names
    name_to_dependencies = {}
    not_defined = []
    class_names = if class_names.class == Array then class_names else [class_names] end
    class_names.each do |cls_name|
      begin
        name_to_dependencies[cls_name] = ApexClass.get_dependencies cls_name
      rescue Exception=>e
        not_defined.push cls_name
      end
    end

    {dependencies: name_to_dependencies, symbol_tables_not_defined: not_defined}
  end

  def run_test_async
    puts "Running the tests...For class asynch\"#{name}\""
    if !@id
      cls = get_class_sf_instance
      @id = cls.current_page[0]["Id"]
    end

    begin
      job = SalesforceJob.run_tests_asynchronously @id
      status = "Processing"
      escape_status = ["Aborted", "Completed", "Failed"]
      puts "Monitoring Job: #{@id}"
      while !escape_status.include?status
        sleep(5)
        monitoring_status = job.monitor.body.current_page[0]
        status = monitoring_status.Status
        puts "Status: #{status}"
      end
      puts "Keep this !#{monitoring_status.ParentJobId}'"
      results = Salesforce.instance.metadata_query( "Select MethodName,Outcome,StackTrace,TestTimestamp,Message,ApexLogId from ApexTestResult where AsyncApexJobId='#{monitoring_status.ParentJobId}'" )
      puts "we got results"
      ApexTestResults.new results
      puts "done"
    rescue Exception=>e
      puts "the job is already running"
    end
  end

  def run_test
    begin
      results = Salesforce.instance.run_tests_synchronously name
      test_res = ApexTestResults.new results
      test_res_file = "./test_results.yaml"
      begin
        data = YAML.load_file test_res_file
        if !data
          data = {}
        end
      rescue
        data = {}
      end
      data[name] = test_res
      File.open( test_res_file, 'w'){ |f| f.write YAML.dump( data ) }
      data[name]
    rescue Faraday::TimeoutError
      puts "timeout"
    end
  end

  def self.only_test_classes all_classes
    all_classes.select{ |cls| cls.test_cls? }
  end

  def self.load_from_test_coverage
    classes = []
    data = YAML.load_file "./test_results.yaml"
    data.each do |result|
      name = result.delete("class")
      test_results = ApexTestResults.new result
      cls = ApexClass.new( { Name: name, TestResults: test_results} )
      classes.push cls
    end
    classes
  end

  def save( metadataContainer )
    if id
      cls_member_id = Salesforce.instance.restforce.create( "ApexClassMember",
                                                               Body: body,
                                                               MetadataContainerId: metadataContainer.id,
                                                               ContentEntityId: id
                                              )

   else
      cls_member_id = Salesforce.instance.sf_post_callout( "/services/data/v33.0/sobjects/ApexClass" , {

                                                              body: {
                                                                 "Name"=>name,
                                                                 "Body"=>body
                                                              }.to_json
                                                           }
                                              )
   end
   cls_member_id
  end

  def get_class_sf_instance( searching_name=@name )
    Salesforce.instance.query("Select+Id,Name,Body,BodyCrc,SystemModstamp,NamespacePrefix+from+ApexClass+where+name=\'#{searching_name}\' and NamespacePrefix=null")
  end

  def test_cls?
    if test_results
      return test_results.num_tests_ran > 0
    end
    raise SystemCallError, "There are no test results so it is difficult to determine"
  end

end