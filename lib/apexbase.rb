module ApexBase
  def load_from_local_file file_path
    file = File.open( file_path, 'r' )
    @body = file.read
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
    if !@id
      @id = get_class_sf_instance.current_page[0].Id
    end
    id = @id
    url = "/services/data/v33.0/sobjects/#{type}/#{id}"
    res = Salesforce.instance.sf_delete_callout( url )
    puts res.response
  end
end