require_relative 'salesforce'

class ApexStaticResource
  attr_reader :body, :name, :folder, :content_type

  def file_ext
    return '.resource'
  end

  def initialize(options={})
    @name = options[:Name]
    @folder = 'staticresources'
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  def pull
    file_request = Salesforce.instance.query("Select+Id,Name,ContentType,Body+from+StaticResource+where+name=\'#{name}\'")
    cls = file_request.current_page[0]
    @id = cls.Id
    @content_type = cls.ContentType
    @body = get_body cls.Body
  end

  def get_body body_url
    @body = Salesforce.instance.restforce.get( body_url ).body
  end
end
