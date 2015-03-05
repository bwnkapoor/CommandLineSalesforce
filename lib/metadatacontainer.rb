class MetadataContainer
  attr_reader :name, :id
  
  def initialize( name, id=nil )
    @name = name
    @id = id
  end

  def save
    id = Salesforce.instance.restforce.create( 'MetadataContainer', Name: name )
    if id
      @id = id
    else
      puts "Failed to Save!"
    end
  end
end