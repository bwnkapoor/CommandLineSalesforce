require_relative 'salesforce'

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