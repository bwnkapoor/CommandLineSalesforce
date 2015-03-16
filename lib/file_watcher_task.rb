require 'filewatcher'
require_relative '../loadfile'
require 'byebug'

def do_watch
  puts "Monitoring Salesforce files..."
  FileWatcher.new(".").watch(0.25) do |filename, event|
    store_environment_login
    begin
      type = apex_member_factory filename
      if type
        if event == :new
          puts "the file is new"
        elsif event == :changed
          puts "Saving #{filename}"
          container = MetadataContainer.new( DateTime.now.to_time.to_i.to_s )
          container.save()
          basename = File.basename(filename, File.extname(filename))
          cls = type.new({Name: basename})
          cls.load_from_local_file filename
          metadata = cls.save container
          puts "Saving the file with id #{metadata}"

          asynch = ContainerAsyncRequest.new( container.id )
          asynch.save
          results = asynch.monitor_until_complete
          asynch.save_results_log
        end
        puts "-----------------------------------------------------------"
      end
    rescue Exception=>e

    end
  end
end