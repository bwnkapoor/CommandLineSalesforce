require 'yaml'

module ApexBase
  SYMBOLIC_FILE_NAME = 'symbolic_table.yaml'

  def load_from_local_file file_path
    file = File.open( file_path, 'r' )
    @body = file.read
    @full_name = file_path
    fName = File.basename file
    @local_name = file_path

    if !id
      puts "#{fName}"
      base_file_name = File.basename file, File.extname(file)
      sf_instance = get_class_sf_instance base_file_name
      if sf_instance && !sf_instance.current_page.empty?
        @id = sf_instance.current_page[0].Id
      end
    end
  end

  def delete
    url = "/services/data/v33.0/sobjects/#{self.class}/#{id}"
    res = Salesforce.instance.sf_delete_callout( url )
    puts res.response
  end

  def id
    if !@id
      definition = get_class_sf_instance.current_page
      if !definition.empty?
        @id = definition[0].Id
      end
    end

    @id
  end

  def log_symbolic_link
    symbolic_link = load_symbol_links
    if !symbolic_link[self.class]
      symbolic_link[self.class] = {}
    end
    symbolic_link[self.class][@name] = {
      "local_name"=>@local_name,
      "id"=>@id
    }
    File.open(SYMBOLIC_FILE_NAME, 'w'){ |f| f.write YAML.dump symbolic_link }
  end

  def find_symbol_local_link
    symbols = load_symbol_links
    if symbols[self.class] && symbols[self.class][@name]
      f = symbols[self.class][@name]["local_name"]
      @folder = File.dirname f
    else
      nil
    end
  end

  def load_symbol_links
    begin
      symbolic_link = YAML.load_file SYMBOLIC_FILE_NAME
    rescue Exception=>e
      symbolic_link = {}
      puts "Symbolic Table file Not found"
    end
    symbolic_link
  end

  def self.pull fileNames, type
    classes = []
    puts "Pulling #{type}"
    if fileNames.length == 1 && fileNames[0] == "*"
      fileNames = type.all.map(&:Name)
    end
    fileNames.each do |file|
      cls = type.new( {Name: file} )
      begin
        puts "Pulling #{file}"
        cls.pull
        classes.push cls
      rescue Exception=>e
        puts e.to_s
      end
    end
    classes
  end
end