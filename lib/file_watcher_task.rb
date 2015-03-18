require 'filewatcher'
require_relative '../loadfile'
require 'byebug'
require 'io/console'
require 'timeout'

def do_watch
  puts "Monitoring Salesforce files..."
  FileWatcher.new(".").watch(0.25) do |filename, event|
    if !filename.end_with? "~"
      begin
        type = apex_member_factory filename
        if type
          puts "The time is #{Time.now}"
          basename = File.basename(filename, File.extname(filename))
          cls = type.new({Name: basename})
          if event == :new
            puts "Would you like to save this file to SFDC?"
            begin
              y_or_n = Timeout::timeout(5){
                $stdin.gets.chomp.downcase
              }
            rescue Exception=>e
              puts "User did not respond to delete request"
              y_or_n = "n"
            end

            if y_or_n == "y"
              save_file_routine cls, filename
            end
          elsif event == :changed
            puts "Saving #{filename}"
            save_file_routine cls, filename
          elsif event == :delete
            puts "Would you like to delete from SFDC?"
            begin
              y_or_n = Timeout::timeout(5){
                $stdin.gets.chomp.downcase
              }
            rescue Exception=>e
              puts "User did not respond to delete request"
              y_or_n = "n"
            end

            if y_or_n == "y"
              cls.delete
            end
          end
          puts "-----------------------------------------------------------"
        end
      rescue Exception=>e

      end
    end
  end
end

def save_file_routine cls, filename
  container = MetadataContainer.new( DateTime.now.to_time.to_i.to_s )
  container.save()
  cls.load_from_local_file filename
  metadata = cls.save container
  puts "Saving the file with id #{metadata}"

  asynch = ContainerAsyncRequest.new( container.id )
  asynch.save
  results = asynch.monitor_until_complete
  asynch.save_results_log
end