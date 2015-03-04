require 'restforce'
require 'fileutils'
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

class ApexPage
  attr_reader :body, :name, :folder

  def file_ext
    return '.page'
  end

  def initialize(options={})
    @body = options[:Markup]
    @folder = 'pages'
    @name = options[:Name]
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  def pull
    file_request = Salesforce.instance.query( "Select+Id,Name,Markup,SystemModstamp,NamespacePrefix+from+ApexPage+where+name=\'#{name}\'" )
    cls = file_request.current_page[0]
    @body = cls.Markup
    @id = cls.Id
  end
end

class ApexComponent
  attr_reader :body, :name, :folder

  def file_ext
    return '.component'
  end

  def path
    folder.to_s + "/" + name.to_s + file_ext.to_s
  end

  def initialize(options={})
    @body = options[:Markup]
    @folder = 'components'
    @name = options[:Name]
  end

  def pull
    file_request = Salesforce.instance.query( "Select+Id,Name,Markup,SystemModstamp,NamespacePrefix+from+ApexComponent+where+name=\'#{name}\'" )
    cls = file_request.current_page[0]
    @body = cls.Markup
    @id = cls.Id
  end
end

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

def write files
  files.each do |sf_file|
    FileUtils.mkdir_p sf_file.folder
    f = File.new( sf_file.path, "w" )
    f.write( sf_file.body )
    f.close
  end
end

cls = ApexClass.new( { :Name=>'TestController' } )
cls.pull
pg = ApexPage.new( {:Name=>"SendEmailWithSF_Attachments"} )
pg.pull
comp = ApexComponent.new( {:Name=>"Test"} )
comp.pull
resource = ApexStaticResource.new( {:Name=>"sobject_lookup"} )
resource.pull
write [cls, pg, comp, resource]
