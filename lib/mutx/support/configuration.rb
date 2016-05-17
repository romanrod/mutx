module Mutx
  module Support
    class Configuration

      attr_reader :input

      def self.get
        Mutx::Support::Log.debug "Creating configuration object" if Mutx::Support::Log

        if self.config_file_exists?
          @@input = Mutx::Support::Update.mutx_conf
        else
          @@input = self.default_input
          puts "Error loading mutx configuration file. Using default values".colorize(:red)
        end
      end

      

      def self.default_input
        Mutx::Support::Log.debug "#{self.class}Setting default input (from template)" if Mutx::Support::Log
        JSON.parse(IO.read(self.path_template))
      end

      def self.path
        "#{Dir.pwd}/mutx/conf/mutx.conf"
      end

      def self.path_template
        File.expand_path("../../../", __FILE__) + "/generators/templates/mutx.conf.tt"
      end

      def self.project_name
        Mutx::Support::Log.debug "Project name: #{Dir.pwd.split("/").last}"
        "#{Dir.pwd.split("/").last}"
      end

      def self.project_name= value
        @@project_name = value
      end

      def self.project_name
        @@project_name
      end

      def self.hostname
        @@input['app_name'] || 'localhost'
      end

      # Returns the configured port. If it isn't a number, port 8080 will be returned by defualt
      # @return [Fixnum] port number
      def self.port
        self.is_a_number?(@@input["app_port"]) ? @@input["app_port"] : 8080
      end

      def self.config_file_exists?
        File.exist? self.path
      end

      def self.project_name
        @@input['project_name'] || 'A project using Mutx'
      end

      def self.project_url
        url = @@input['project_url'] == "http://your.project.url" ? "" : @@input['project_url']
        url.empty? ? Mutx::Support::Git.remote_url : url
      end

      # def self.db_type
      #   @@input["database"]['type'] || 'mongodb'
      # end

      def self.db_host
        @@input["database"]['host'] || 'localhost'
      end

      def self.db_port
        @@input["database"]['port'] || 27017
      end

      def self.db_username
        @@input["database"]["username"] || nil
      end

      def self.db_pass
        @@input["database"]["password"] || nil
      end

      def self.db_connection_data
        {
          :host => self.db_host,
          :port => self.db_port,
          :username => self.db_username,
          :pass => self.db_pass
        }
      end

      def self.execution_check_time
        self.is_a_number?(@@input["execution_check_time"]) ? @@input["execution_check_time"] : 5
      end

      def self.maximum_execs_per_task
        self.is_a_number?(@@input["max_execs_per_task"]) ? @@input["max_execs_per_task"] : 3
      end

      def self.max_execs
        self.maximum_execs_per_task
      end

      def self.notification?
        self.notification_username and self.notification_password and self.use_gmail?
      end

      def self.notifications_to
        self.recipients
      end

      def self.recipients
        self.is_email_correct? ? @@input['notification']['recipients'] : ''
      end

      def self.notification_username
        @@input['notification']['username']
      end

      def self.notification_password
        @@input['notification']['password']
      end

      def self.refresh_time
        self.is_a_number?(@@input['refresh_time']) ? @@input['refresh_time'] : 0
      end

      def self.refresh?
        !self.refresh_time.zero?
      end

      def self.use_gmail?
        self.is_boolean? @@input['use_gmail'] ? @@input['use_gmail'] : false
      end

      def self.is_email_correct?
        begin
          !@@input['notification']['recipients'].scan(/\w+@[a-zA-Z]+?\.[a-zA-Z]{2,6}/).empty?
        rescue
          false
        end
      end

      def self.attach_report?
        value = @@input['notification']['attach_report']
        self.is_boolean? value ? value : false
      end



      def self.is_a_number? value
        !"#{value}".scan(/\d+/).empty?
      end

      def self.is_boolean? object
        [TrueClass, FalseClass].include? object.class
      end

      def self.use_git?
        self.validate_use_git_configuration_value
        @@input['use_git']
      end

      def self.validate_use_git_configuration_value
        raise "You have to set use_git config with true or false. Has #{@@input['use_git']}" unless self.is_boolean? @@input['use_git']
      end

      def self.formatted_datetime
        @@input['datetime_format'] || "%d/%m/%Y %H:%M:%S"
      end

      def self.company
        if @@input['footer_text'].is_a? String
          @@input['footer_text']
        else
          ""
        end
      end

      # After this period of time (in seconds) Mutx will show a stop execution button on result report and results list
      def self.inactivity_timeout
        self.is_a_number?(@@input["inactivity_timeout"]) ? @@input["inactivity_timeout"] : 60
      end

      # After this period of time (in seconds) Mutx will kill process execution automatically
      def self.execution_time_to_live
        self.is_a_number?(@@input["kill_inactive_executions_after"]) ? @@input["kill_inactive_executions_after"] : 3600
      end

      def self.kill_after_time?
        self.execution_time_to_live > 0
      end

      def self.reset_execution_availability?
        inactivity_timeout > 0
      end

      def self.auto_execution_id
        if @@input.has_key? "execution_tag_placeholder"
          if @@input["execution_tag_placeholder"]["datetime"]
            Time.now.strftime(@@input["execution_tag_placeholder"]["format"])
          else
            @@input["execution_tag_placeholder"]["default"]
          end
        end
      end

      def self.headless?
        if self.is_boolean? @@input["headless"]["active"]
          "xvfb-run --auto-servernum --server-args='-screen 0, #{self.resolution}x#{self.size}' " if @@input["headless"]["active"]
        end

        # begin
        #   @@input["headless"]["active"] if self.is_boolean? @@input["headless"]["active"]
        # rescue
        #   false
        # end
      end

      # Returns value for screen resolution
      # @return [String] resolution like 1024x768
      def self.resolution
        @@input["headless"]["resolution"]
      end

      # Returns value for screen size.
      # This is used by xvfb configuration
      # @return [String] value in inches
      def self.size
        @@input["headless"]["size"]
      end

      def self.pretty_configuration_values
        output = self.configuration_values
        JSON.pretty_generate(output).gsub("\"******\"", "******")
      end

      def self.configuration_values
        output = Marshal.load(Marshal.dump(@@input))
        output["database"]["username"] = "******"
        output["database"]["password"] = "******"
        output["notification"]["username"] = "******"
        output["notification"]["password"] = "******"
        output
      end

      def self.show_configuration_values
        puts "

    * Configuration values loaded at starting Mutx:

  #{self.pretty_configuration_values}"
      end

    end
  end
end