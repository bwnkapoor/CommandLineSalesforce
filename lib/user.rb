require 'yaml'
require 'io/console'
require 'fileutils'
require 'configatron'
require_relative '../patches/hash'

module User

  class User
    attr_reader :client, :instance, :instance_url, :oauth_token

    def initialize( fields={} )
      @client, @instance = fields[:client], fields[:instance]
      @username, @client_id = fields[:username], fields[:client_id]
      @security_token, @client_secret = fields[:security_token], fields[:client_secret]
      @is_production, @local_root_directory = fields[:is_production], fields[:local_root_directory]
      @password = fields[:password]
    end

    def save
      login_file = configatron.logins
      if File.exists?login_file
        data = YAML.load_file login_file
      else
        FileUtils.mkdir_p File.dirname( configatron.logins )
        data = {}
      end

      if !data["clients"]
        data["clients"] = {}
      end
      if !data["clients"][client]
        data["clients"][client] = {}
      end
      data["clients"][client][instance] = to_hash

      File.open( configatron.logins, 'w' ){ |f| YAML.dump(data, f) }
    end


    def login
      ENV["SF_INSTANCE"] = instance
      ENV["SF_CLIENT"] = client
      ENV["SF_USERNAME"] = username
      ENV["SF_PASSWORD"] = password
      begin
        ENV["SF_CLIENT_SECRET"] = configatron.client_secret!
        ENV["SF_CLIENT_ID"] = configatron.client_id!
      rescue
        raise "config.rb must contain \"client_secret\" and \"client_id\".  Modify config.rb and us your connected app credentials"
      end
      ENV["SF_SECURITY_TOKEN"] = security_token
      ENV["SF_HOST"] = is_production ? "login.salesforce.com" : "test.salesforce.com"
      @instance_url = Salesforce.instance.restforce.instance_url
      @oauth_token = Salesforce.instance.restforce.options[:oauth_token]
      ENV["SF_INSTANCE_URL"] = @instance_url
      ENV["SF_OAUTH"] = @oauth_token
      FileUtils.mkdir_p full_path
    end

    def username
      if @username then return @username end
      data = YAML.load_file configatron.logins
      @username = data["clients"][client][instance][:username]
    end

    def to_hash
      {
      "username"=>username,
      "password"=>password,
      "local_root"=>"#{client}/codebase/#{instance}",
      "is_production"=>(is_production == 'true'|| is_production=='y'),
      "security_token"=>security_token,
      "client"=>client,
      "instance"=>instance
      }
    end

    def security_token
      if @security_token then return @security_token end
      data = YAML.load_file configatron.logins
      @security_token = data["clients"][client][instance][:security_token]
    end

    def is_production
      if @is_production then return @is_production end
      data = YAML.load_file configatron.logins
      @is_production = data["clients"][client][instance][:is_production]
    end

    def full_path
      configatron.root_client_dir + local_root_directory.to_s
    end

    def local_root_directory
      if @local_root_directory then return @local_root_directory end
      data = YAML.load_file configatron.logins
      @local_root_directory = data["clients"][client][instance][:local_root]
    end

    def password
      if @password then return @password end
      data = YAML.load_file configatron.logins
      @password = data["clients"][client][instance][:password]
    end

  end

  def self.login client=nil, environment=nil
    if client && environment
      login_with_creds client, environment
    else
      login_with_current_credentials
    end
  end

  def self.logout
    data = YAML.load_file configatron.logins
    data.delete("running_user")
    File.open(configatron.logins, 'w') { |f| YAML.dump(data, f) }
  end

  def self.logins client=nil
    data = YAML.load_file configatron.logins
    if( client )
      begin
        data["clients"][client].each_key do |sandbox|
          puts "#{client},#{sandbox}"
        end
      rescue Exception=>e
        raise "The Client: \"#{client}\" does not have a User::login"
      end
    else
      data["clients"].each_key do |client|
        data["clients"][client].each_key do |sandbox|
          puts "#{client},#{sandbox}"
        end
      end
    end
  end

  def self.session_user
    if ENV["SF_INSTANCE"]
      instance = ENV["SF_INSTANCE"]
      client = ENV["SF_CLIENT"]
      get_credentials client, instance
    else
      get_credentials
    end
  end

  def self.get_credentials client=nil, environment=nil
    if( client && environment )
      data = YAML.load_file configatron.logins
      yaml_data = data["clients"][client][environment]
      yaml_data["client"] = client
      yaml_data["instance"] = environment
      running_user = User.new yaml_data
    else
      running_user = who_am_i
    end
    running_user
  end

  def self.who_am_i
    data = YAML.load_file configatron.logins
    client = data["running_user"]
  end

  private
    def self.login_with_creds client, environment
      data = YAML.load_file configatron.logins
      theClient = data["clients"][client]

      if theClient && theClient[environment]
        creds = theClient[environment]
        creds["client"], creds["instance"] = client, environment
        usr = User.new creds.symbolize_keys
        usr.login
        data["running_user"] = usr
        File.open(configatron.logins, 'w') { |f| YAML.dump(data, f) }
        usr
      else
        raise "#{client.to_s} #{environment.to_s} does not exist"
      end
    end

    def self.login_with_current_credentials
      usr = who_am_i
      usr.login
      usr
    end
end