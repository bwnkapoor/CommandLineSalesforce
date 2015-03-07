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
      if sf_instance
        @id = sf_instance.current_page[0].Id
      end
    end

    @name = "#{folder}/#{fName}"
  end
end