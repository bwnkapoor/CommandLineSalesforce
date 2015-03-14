require_relative 'apextestresults'

class ApexTrigger
  include ApexBase
  attr_reader :name, :folder, :id, :body

  def file_ext
    return '.trigger'
  end

  def type
    'ApexTrigger'
  end

  def table_enum_or_id
    matches = @body.match Regexp.new "trigger[ ]+([A-Za-z0-9_]+)[ ]+on[ ]+([A-Za-z0-9_]+)", true
    if matches
      return matches.captures[1]
    end
  end

  def initialize(options={})
    @body = options[:Body]
    @id = options[:Id]
    @test_results = options[:TestResults]
    @folder = 'triggers'
    @name = options[:Name]
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  # Dependencies currently are not supporting extends, implements and variables of the class
  def self.get_dependencies class_name
    dependencies = []
    x = Salesforce.instance.metadata_query( "Select SymbolTable, MetaData, FullName from ApexTriggerMember where FullName = \'#{class_name}\' order by createddate desc limit 1" )
    x.body.current_page.each do |classMember|
      if classMember.SymbolTable
        classMember.SymbolTable.externalReferences.each do |xRef|
          dependencies.push xRef.name.to_s
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
      raise "Trigger DNE #{self.name}"
    end
  end

  def self.pull fileNames
    classes = []
    fileNames.each do |file|
      cls = ApexTrigger.new( {Name: file} )
      begin
        cls.pull
        classes.push cls
      rescue Exception=>e
        puts e.to_s
      end
    end
    classes
  end

  def get_class_sf_instance( searching_name=name )
    Salesforce.instance.query("Select+Id,Name,Body,BodyCrc,SystemModstamp,NamespacePrefix+from+ApexTrigger+where+name=\'#{searching_name}\' and NamespacePrefix=null")
  end

  def save( metadataContainer )
    if( id )
      cls_member_id = Salesforce.instance.restforce.create( "ApexTriggerMember", Body: body,
                                                               MetadataContainerId: metadataContainer.id,
                                                               ContentEntityId: id
                                              )
    else
      cls_member_id = Salesforce.instance.sf_post_callout( "/services/data/v33.0/sobjects/ApexTrigger" , {

                                                              body: {
                                                                 "Name"=>name,
                                                                 "Body"=>body,
                                                                 "TableEnumOrId"=>table_enum_or_id
                                                              }.to_json
                                                           }
                                              )

    end
    puts cls_member_id
  end
end