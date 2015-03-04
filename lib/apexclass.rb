require_relative 'salesforce'

class ApexClass
  attr_reader :body, :name, :folder, :id

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

  def pull
    file_request = Salesforce.instance.query("Select+Id,Name,Body,BodyCrc,SystemModstamp,NamespacePrefix+from+ApexClass+where+name=\'#{name}\'")
    cls = file_request.current_page[0]
    @body = cls.Body
    @id = cls.Id
  end
end