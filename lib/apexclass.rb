require_relative 'salesforce'
require_relative 'apexbase'

class ApexClass
  include ApexBase
  attr_accessor :dependencies
  attr_reader :name, :folder, :id, :body, :local_name

  def file_ext
    return '.cls'
  end

  def initialize(options={})
    @body = options[:Body]
    @folder = 'classes'
    @name = options[:Name]
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  def get_dependencies
    @dependencies = []
    x = Salesforce.instance.metadata_query("Select SymbolTable, FullName from ApexClassMember where FullName = \'#{name}\' order by createddate desc limit 1")
    x.body.current_page.each do |classMember|
      if classMember.SymbolTable
        classMember.SymbolTable.externalReferences.each do |xRef|
          @dependencies.push xRef.name.to_s
        end
      end
    end
    @dependencies
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

end