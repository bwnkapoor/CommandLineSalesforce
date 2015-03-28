require 'configatron'

configatron.logins = Dir.home + "/work/logins.yaml"
configatron.templates_dir = File.dirname(__FILE__).to_s + "/templates/"
configatron.root_client_dir = Dir.home + "/work"
#configatron.client_secret = "create_your_own_salesforce_app"
#configatron.client_id = "under setup/create/apps new connected app"
