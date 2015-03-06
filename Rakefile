# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require_relative 'loadfile'

task :push, [:file_paths] do |t, args|
  push ["classes/ContactServices.cls",
       ]
        #args[:file_paths]]
end

task :pull, [:file_names] do |t, args|
  pull ["SendEmailWithSF_Attachments.cls", "SendEmailWithSF_Attachments.page"]#args[:file_names]
end
