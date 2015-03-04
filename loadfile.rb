require 'restforce'
require 'fileutils'
require_relative '../app/models/salesforce'

class ApexClass
  attr_reader :body, :name, :folder

  def file_ext
    return '.cls'
  end

  def initialize(options={})
    @body = options.Body
    @folder = 'classes'
    @name = folder + '/' + options.Name.to_s + file_ext
  end
end

class ApexPage
  attr_reader :body, :name, :folder

  def file_ext
    return '.page'
  end

  def initialize(options={})
    @body = options.Markup
    @folder = 'pages'
    @name = folder + '/' + options.Name.to_s + file_ext
  end
end

class ApexComponent
  attr_reader :body, :name, :folder

  def file_ext
    return '.component'
  end

  def initialize(options={})
    @body = options.Markup
    @folder = 'components'
    @name = folder + '/' + options.Name.to_s + file_ext
  end
end

class ApexStaticResource
  attr_reader :body, :name, :folder, :content_type

  def file_ext
    return '.resource'
  end

  def initialize(options={})
    get_body options.Body
    @folder = 'staticresources'
    @content_type = options.ContentType
    @name = folder + '/' + options.Name.to_s + file_ext
  end

  def get_body body_url
    sf = Salesforce.new
    @body = sf.get_body(body_url)
  end
end


# Pulls Down Apex Files individually
# returns the files
def pullClass file_names
  files = []
  file_names.each do |file_name|
    file_request = @sfdc.get_class( file_name )
    cls = file_request.current_page[0]
    files.push ApexClass.new cls
  end

  files
end

# Pulls Down ApexPage Files individually
# returns the files
def pullPage file_names
  files = []
  file_names.each do |file_name|
    file_request = @sfdc.get_page( file_name )
    cls = file_request.current_page[0]
    files.push ApexPage.new cls
  end

  files
end

# Pulls Down ApexComponent Files individually
# returns the files
def pullComponent file_names
  files = []
  file_names.each do |file_name|
    file_request = @sfdc.get_component( file_name )
    cls = file_request.current_page[0]
    files.push ApexComponent.new cls
  end

  files
end

# Pulls Down Static Resource Files individually
# returns the files
def pullResource file_names
  files = []
  file_names.each do |file_name|
    file_request = @sfdc.get_resource( file_name )
    cls = file_request.current_page[0]
    files.push ApexStaticResource.new cls
  end

  files
end

def write files
  files.each do |sf_file|
    FileUtils.mkdir_p sf_file.folder
    f = File.new( sf_file.name, "w" )
    f.write( sf_file.body )
    f.close
  end
end

@sfdc = Salesforce.new
files = pullClass( ["TestController"] )
files.concat( pullPage( ["SendEmailWithSF_Attachments"] ) )
files.concat( pullComponent( ["Test"] ) )
files.concat( pullResource( ["sobject_lookup"] ) )
write files