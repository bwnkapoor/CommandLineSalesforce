require 'yaml'

require_relative 'salesforce'
require_relative 'apexbase'
require_relative 'apextestresults'
require_relative 'salesforce_job'

class ApexClass
  include ApexBase
  attr_reader :local_name

  def file_ext
    return '.cls'
  end

  def test_results
    begin
      data = YAML.load_file 'test_results.yaml'
    rescue Exception=>e
      data = {}
    end

    if data[@name]
      @test_results = data[@name]
    else
      @test_results = run_test
    end

    @test_results
  end

  def self.run_all_tests
    all_apex_classes = Salesforce.instance.query( "Select Name from ApexClass where NamespacePrefix=null").map(&:Name)
    all_apex_classes.each_with_index do |cls_name, i|
      puts "Running #{cls_name}"
      cls = ApexClass.new( Name: cls_name )
      cls.run_test
      puts "#{i+1}/#{all_apex_classes.length} tests have ran"
    end
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

  def extends
    if !@body
      @body = get_class_sf_instance.current_page[0].Body
    end
    matches = @body.match Regexp.new( "[global|public|private][ ]+[with|without sharing]{0,1}[ ]*class[ ]+[A-Za-z0-9_]+[ ]+extends[ ]+([A-Za-z0-9_.]+)", true )

    if( matches )
      return matches.captures[0]
    end
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

  def self.all
    Salesforce.instance.query( "Select Name from ApexClass where Namespaceprefix=null" )
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

    begin
      job = SalesforceJob.run_tests_asynchronously id
    rescue Exception=>e
      raise "the job is already running #{e}"
    end
  end

  def run_test
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
    test_res
  end

  def self.only_test_classes all_classes
    all_classes.select{ |cls| cls.test_cls? }
  end

  def self.load_from_test_coverage
    classes = []
    data = YAML.load_file "./test_results.yaml"
    data.each do |result|
      name = result[0]
      test_results = result[1]
      cls = ApexClass.new( { Name: name, TestResults: test_results} )
      classes.push cls
    end
    classes
  end

  def save( metadataContainer )
    puts "Saving #{name}"
    if id
      results = Salesforce.instance.metadata_create( "ApexClassMember", {
                                                               body: {
                                                                 Body: body,
                                                                 MetadataContainerId: metadataContainer.id,
                                                                 ContentEntityId: id
                                                               }.to_json
                                              })
   else
      results = Salesforce.instance.metadata_create( self.class.name, {

                                                              body: {
                                                                 "Name"=>name,
                                                                 "Body"=>body
                                                              }.to_json
                                                           }
                                              )
     puts results.to_s
   end
   results["id"]
  end

  def self.get_class_sf_instance( searching_name=@name )
    Salesforce.instance.query("Select+Id,Name,Body,BodyCrc,SystemModstamp,NamespacePrefix+from+ApexClass+where+name=\'#{searching_name}\' and NamespacePrefix=null")
  end

  def test_cls?
    if test_results
      return test_results.num_tests_ran > 0
    end
    raise SystemCallError, "There are no test results so it is difficult to determine"
  end

  def self.create_from_template template, name
    content = template.read
    content = content.sub("@className@", name)
    content
    self.new( {Name: name, Body: content} )
  end

end