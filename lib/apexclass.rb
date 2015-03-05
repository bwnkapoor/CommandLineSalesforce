require_relative 'salesforce'

class ApexClass
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

  def load_from_local_file file_path
    file = File.open( file_path, 'r' )
    @body = file.read
    fName = File.basename file
    @local_name = file_path
    @name = "classes/#{fName}"
  end

  def pull
    file_request = Salesforce.instance.query("Select+Id,Name,Body,BodyCrc,SystemModstamp,NamespacePrefix+from+ApexClass+where+name=\'#{name}\'")
    cls = file_request.current_page[0]
    @body = cls.Body
    @id = cls.Id
  end

  def save( metadataContainer )
    id = Salesforce.instance.restforce.create( "ApexClassMember", Body: body,
                                                             MetadataContainerId: metadataContainer.id,
                                                             ContentEntityId: '01pj0000003CtjZ'
                                            )
    puts id
  end

end