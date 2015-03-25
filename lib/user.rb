require 'yaml'
require 'io/console'
require 'fileutils'

module User
  LOGIN_PATH = '/home/justin/buildTool/build_tool.yaml'
  class User
    attr_reader :client, :instance, :instance_url, :oauth_token

    def initialize( fields={} )
      @client, @instance = fields["client"], fields["instance"]
    end

    def login
      ENV["SF_INSTANCE"] = instance
      ENV["SF_CLIENT"] = client
      ENV["SF_USERNAME"] = username
      ENV["SF_PASSWORD"] = password
      ENV["SF_CLIENT_SECRET"] = client_secret
      ENV["SF_CLIENT_ID"] = client_id
      ENV["SF_SECURITY_TOKEN"] = security_token
      ENV["SF_HOST"] = is_production ? "login.salesforce.com" : "test.salesforce.com"
      @instance_url = Salesforce.instance.restforce.instance_url
      @oauth_token = Salesforce.instance.restforce.options[:oauth_token]
      ENV["SF_INSTANCE_URL"] = @instance_url
      ENV["SF_OAUTH"] = @oauth_token
      FileUtils.mkdir_p "/home/justin/work/#{local_root_directory}"
    end

    def username
      data = YAML.load_file LOGIN_PATH
      data["clients"][client][instance]["username"]
    end

    def to_hash
      hash = {}
      self.instance_variables.each {|var| hash[var.to_s.delete("@")] = self.instance_variable_get(var) }
      hash
    end

    def client_id
      data = YAML.load_file LOGIN_PATH
      data["client_id"].to_s
    end

    def security_token
      data = YAML.load_file LOGIN_PATH
      data["clients"][client][instance]["security_token"]
    end

    def client_secret
      data = YAML.load_file LOGIN_PATH
      data["client_secret"].to_s
    end    

    def is_production
      data = YAML.load_file LOGIN_PATH
      data["clients"][client][instance]["is_production"]
    end

    def local_root_directory
      data = YAML.load_file LOGIN_PATH
      data["clients"][client][instance]["local_root"]
    end

    def password
      data = YAML.load_file LOGIN_PATH
      data["clients"][client][instance]["password"]
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
    data = YAML.load_file LOGIN_PATH
    data.delete("running_user")
    File.open(LOGIN_PATH, 'w') { |f| YAML.dump(data, f) }
  end

  def self.logins client=nil
    data = YAML.load_file LOGIN_PATH
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
      data = YAML.load_file LOGIN_PATH
      yaml_data = data["clients"][client][environment]
      yaml_data["client"] = client
      yaml_data["instance"] = environment
      running_user = User.new yaml_data
    else
      running_user = who_am_i
    end
    running_user
  end

  def self.create_new_user client, instance
    if client && instance
      data = YAML.load_file LOGIN_PATH
      puts "Username:"
      username = $stdin.gets.chomp
      puts "Password:"
      password = $stdin.gets.chomp
      puts "is production?"
      is_production = $stdin.gets.chomp
      if !data["clients"]
        data["clients"] = {}
      end
      if !data["clients"][client]
        data["clients"][client] = {}
      end
      data["clients"][client][instance] = {
        "username"=>username,
        "password"=>password,
        "local_root"=>"#{client}/codebase/#{instance}",
        "is_production"=>is_production == 'true'
      }
      File.open( LOGIN_PATH, 'w' ){ |f| YAML.dump(data, f) }
    else
      raise "You must enter a client and instance"
    end

  end

  def self.who_am_i
    data = YAML.load_file LOGIN_PATH
    client = data["running_user"]
  end

  private
    def self.login_with_creds client, environment
      data = YAML.load_file LOGIN_PATH
      theClient = data["clients"][client]

      if theClient && theClient[environment]
        creds = theClient[environment]
        creds["client"] = client
        creds["instance"] = environment
        usr = User.new creds
        usr.login
        data["running_user"] = usr
        File.open(LOGIN_PATH, 'w') { |f| YAML.dump(data, f) }
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