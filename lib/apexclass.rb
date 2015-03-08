require 'yaml'
require_relative 'salesforce'
require_relative 'apexbase'
require_relative 'apextestresults'

class ApexClass
  include ApexBase
  attr_reader :name, :folder, :id, :body, :local_name, :test_results

  def file_ext
    return '.cls'
  end

  def initialize(options={})
    @body = options[:Body]
    @test_results = options[:TestResults]
    @folder = 'classes'
    @name = options[:Name]
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  def self.get_dependencies class_name
    dependencies = []
    x = Salesforce.instance.metadata_query("Select SymbolTable, FullName from ApexClassMember where FullName = \'#{class_name}\' order by createddate desc limit 1")
    x.body.current_page.each do |classMember|
      if classMember.SymbolTable
        classMember.SymbolTable.externalReferences.each do |xRef|
          dependencies.push xRef.name.to_s
        end
      end
    end
    puts "Dependencies for #{class_name}\n#{dependencies}"
    dependencies
  end

  def pull
    file_request = get_class_sf_instance
    cls = file_request.current_page[0]
    @body = cls.Body
    @id = cls.Id
  end

  def self.pull fileNames
    classes = []
    fileNames.each do |file|
      cls = ApexClass.new( {Name: file} )
      cls.pull
      classes.push cls
    end

    classes
  end

  def self.dependencies class_names
    name_to_dependencies = {}
    class_names = if class_names.class == Array then class_names else [class_names] end
    class_names.each do |cls_name|
      name_to_dependencies[cls_name] = ApexClass.get_dependencies cls_name
    end

    name_to_dependencies
  end

  def run_test
    puts "Running a test...For class \"#{name}\""
    results = Salesforce.instance.run_tests_synchronously name
    @test_results = ApexTestResults.new results
  end

  def self.only_test_classes all_classes
    all_classes.select{ |cls| cls.test_cls? }
  end

  def self.load_from_test_coverage
    classes = []
    data = YAML.load_file "/home/justin/Desktop/Loreal/Test_Results2.yml"
    data["items"].each do |result|
      name = result.delete("class")
      test_results = ApexTestResults.new result
      cls = ApexClass.new( { Name: name, TestResults: test_results} )
      classes.push cls
    end
    classes
  end

  def save( metadataContainer )
    cls_member_id = Salesforce.instance.restforce.create( "ApexClassMember", Body: body,
                                                             MetadataContainerId: metadataContainer.id,
                                                             ContentEntityId: id
                                            )
    puts cls_member_id
  end

  def get_class_sf_instance( searching_name=name )
    Salesforce.instance.query("Select+Id,Name,Body,BodyCrc,SystemModstamp,NamespacePrefix+from+ApexClass+where+name=\'#{searching_name}\'")
  end

  def test_cls?
    if test_results
      return test_results.num_tests_ran > 0
    end
    raise SystemCallError, "There are no test results so it is difficult to determine"
  end

end