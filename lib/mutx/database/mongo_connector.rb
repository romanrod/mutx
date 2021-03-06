# encoding: utf-8
require_relative './mongo_connection'

module Mutx
  module Database
    class MongoConnector

      #include Mongo

      def initialize(opts={host: "localhost", port: 27017, username: nil, pass: nil})
        project_name = Dir.pwd.split("/").last
        mongo_connection = MongoConnection.instance
        mongo_connection.client(host: opts[:host],
                                port: opts[:port],
                                database: "#{project_name}_mutx",
                                username: opts[:username],
                                password: opts[:pass])

        $db = mongo_connection.db
        set_task_collection
        set_custom_param_collection
        set_config_collection
        set_results_collection
        set_commits_collection
        set_documentation_collection
        set_input_collection
        set_repos_collection
        set_logger
      end

      def set_logger
        #Mongo::Logger.logger = ::Logger.new("mutx/logs/mongo.log")
        Mongo::Logger.logger.level = ::Logger::INFO
      end

      def set_db_name
        project_name = Dir.pwd.split("/").last
        Mutx::Support::Log.debug "Setting db name: #{project_name}_mutx" if Mutx::Support::Log
        $db_name = "#{project_name}_mutx"
      end

      def set_client opts
        Mutx::Support::Log.debug "Setting db client" if Mutx::Support::Log
        if !$client
          #$client = Mongo::Client.new("mongodb://#{opts[:host]}:#{opts[:port]}/#{set_db_name}")
          $client = Mongo::Client.new([ "#{opts[:host]}:#{opts[:port]}" ], :database => "#{set_db_name}")
        else
          $client
        end
      end

      def self.force_close
        $client.close if $client
      end

      def self.close
        MongoConnection.instance.close
      end

      def set_db
        Mutx::Support::Log.debug "Setting db" if Mutx::Support::Log
        $db = $client.database
        $client.close
        $client = nil
      end

      def authenticate opts
        Mutx::Support::Log.debug "db authenticating" if Mutx::Support::Log
        $auth = $db.authenticate(opts[:username], opts[:pass]) if opts[:username] and opts[:pass]
      end

      def set_task_collection
        Mutx::Support::Log.debug "Setting db tasks collection" if Mutx::Support::Log
        $tasks  = $db.collection("tasks")
        # $tasks.ensure_index({"name" => 1})
        # $tasks.indexes.create_one({ "name" => 1 }, :unique => true)
      end

      def set_custom_param_collection
        Mutx::Support::Log.debug "Setting db custom param collection" if Mutx::Support::Log
        $custom_params  = $db.collection("custom_params")
        # $custom_params.ensure_index({"name" => 1})
      end

      def set_input_collection
        Mutx::Support::Log.debug "Setting db Input collection" if Mutx::Support::Log
        $inputs = $db.collection("inputs")
        $inputs.indexes.create_one({"reference" => 1})
      end

      def set_repos_collection
        Mutx::Support::Log.debug "Setting db Repos collection" if Mutx::Support::Log
        $repos = $db.collection("repos")
      end

      def set_commits_collection
        Mutx::Support::Log.debug "Setting db commits collection" if Mutx::Support::Log
        $commits   = $db.collection("commits")
      end

      def set_results_collection
        Mutx::Support::Log.debug "Setting db results collection" if Mutx::Support::Log
        $results   = $db.collection("results")
        # $results.ensure_index({"started_at" => 1})
        # $results.ensure_index({"_id" => 1})
      end

      def set_documentation_collection
        Mutx::Support::Log.debug "Setting db documentation collection" if Mutx::Support::Log
        $documentation = $db.collection("documentation")
      end

      def set_config_collection
        Mutx::Support::Log.debug "Setting db configuration collection" if Mutx::Support::Log
        $configuration = $db.collection("configuration")
      end
      ##########################
      # DOCUMENTATION
      #
      #

      # Removes all documents of documentation from the DB
      def self.clean_documentation
        Mutx::Support::Log.debug "Cleanning db documentation collection" if Mutx::Support::Log
        $documentation.drop
        # $db.drop_collection("documentation")
      end

      # Inserts a document of documentation in the DB
      def self.insert_documentation document
        Mutx::Support::Log.debug "db insert documentation [#{document}]" if Mutx::Support::Log
        $documentation.insert_one(document)
      end

      # Return an array with all documents of documentation
      def self.get_all_documentation
        Mutx::Support::Log.debug "getting db all documentation" if Mutx::Support::Log
        $documentation.find().to_a
      end

      # Returns the body html of a page
      def self.help_body page
        Mutx::Support::Log.debug "getting db help body" if Mutx::Support::Log
        result = $documentation.find({"title" => page}).to_a.first
        result["body"].to_s if result != nil
      end

      # Returns the title of a page
      def self.help_title page
        Mutx::Support::Log.debug "getting db help title" if Mutx::Support::Log        
        result = $documentation.find({"title" => page}).to_a.first
        result["title"].to_s.gsub('_', ' ').capitalize if result != nil
      end

      # Returns a document from the DB for a certain title
      def self.help_search title
        Mutx::Support::Log.debug "Searching on db help colection for title #{title}" if Mutx::Support::Log
        $documentation.find({:$or => [{ "title" => /#{title}/ },{ "title" => /#{title.upcase}/ },{ "body" => /#{title}/ }]}).to_a
      end


      ###########################
      # COMMONS
      #
      #

      def self.connected?
        begin
          $db and true
        rescue
          false
        end
      end

      def self.generate_id
        value = Time.now.to_f.to_s.gsub( ".","")[0..12].to_i
        Digest::MD5.hexdigest(value.to_s) #Added MD5 to generate a mongo id
      end

      def self.generate_token
        value = Time.now.to_f.to_s.gsub( ".","")[0..12].to_i + 10
        Digest::MD5.hexdigest(value.to_s)
      end

      # Returns a list of collections
      def self.collections
        ["tasks","results","custom_params","commit","configuration"]
      end

      def self.drop_collections hard=false
        collections_to_drop = self.collections
        ["custom_params","tasks"].each{|col| collections_to_drop.delete(col)} unless hard
        collections_to_drop.each do |collection|
          self..drop_collection(collection) if collection != "documentation"
        end
      end

    

      ##################################
      # COMMITS
      #
      #


      # Saves commit information
      # $param [Hash] commit_info = {"_id" => Fixnum, "commit_id" => String, "info" => String}
      def self.insert_commit commit_info
        $commits.insert_one({"_id" => self.generate_id, "log" => commit_info})
      end

      # Returns last saved commit info
      # $return [Hash] if exist
      def self.last_commit
        Mutx::Support::Log.debug "Getting last commit" if Mutx::Support::Log
        data = $commits.find({}).to_a || []
        unless data.empty?
          data.last["log"]
        end
      end

      ##################################
      # TASKS
      #

      # Inserts a task in tasks collection
      # $param [Hash] task_data (see task_data_structure method)
      def self.insert_task task_data
        Mutx::Support::Log.debug "Inserting task [#{task_data}]" if Mutx::Support::Log
        $tasks.insert_one(task_data)
      end

      # Update record for a given task
      # $param [Hash] task_data
      def self.update_task task_data
        #Fix because MD5 as _id
        #task_data["_id"] = task_data["_id"].to_i
        task_data.delete("action")
        Mutx::Support::Log.debug "Updating task [#{task_data}]" if Mutx::Support::Log
        res = $tasks.update_one( {"_id" => task_data["_id"]}, task_data)
        res.n == 1
      end

      # Returns the entire record for a given task name
      # $param [String] task_name
      # $return [Hash] all task data
      def self.task_data_for task_id
        #task_id = task_id.to_i if task_id.respond_to? :to_i
        res = $tasks.find({"_id" => task_id}).to_a.first
        Mutx::Support::Log.debug "Getting db task data for task id #{task_id} => res = [#{res}]" if Mutx::Support::Log
        res
      end

      def self.task_data_for_name(task_name)
        Mutx::Support::Log.debug "Getting db task data for name #{task_name}" if Mutx::Support::Log
        $tasks.find({"name" => task_name}).to_a.first
      end

      # Returns the _id for a given task name
      # $param [String] task_name
      # $return [String] _id
      def self.task_id_for task_name, type=nil
        Mutx::Support::Log.debug "Getting db task id for task name #{task_name} [type: #{type}]" if Mutx::Support::Log
        criteria = {"name" => task_name}
        criteria["type"] = type if type
        res = $tasks.find(criteria, {:fields => ["_id"]}).to_a.first
        res["_id"] if res
      end

      def self.tasks type=nil
        Mutx::Support::Log.debug "Getting db tasks list [type: #{type}]" if Mutx::Support::Log
        criteria = {}
        criteria["type"]=type if type
        $tasks.find(criteria).sort("last_result" => -1).to_a
      end

      #Get cronneable tasks
      def self.cron_tasks
        Mutx::Support::Log.debug "Getting cronneable tasks" if Mutx::Support::Log
        criteria = {}
        criteria["cronneable"]="on"
        $tasks.find(criteria).sort("last_result" => -1).to_a
      end

      # Returns all active tasks
      def self.all_tasks
        self.tasks
      end

      def self.all_tests
        self.tasks "test"
      end

      def self.running_tasks
        self.running "task"
      end

      def self.running_tests
        self.running "test"
      end

      def self.running_now
        Mutx::Support::Log.debug "Getting db running tasks" if Mutx::Support::Log
        $results.find({"status" => /started|running/}).to_a
      end

      def self.running type
        Mutx::Support::Log.debug "Getting db running tasks" if Mutx::Support::Log
        $results.find({"status" => /started|running/, "task.type" => type}).to_a.map do |result|
          self.task_data_for result["task"]["id"]
        end.uniq
      end

      #Cron_start
      def self.running_for_task task_name
        Mutx::Support::Log.debug "Getting db running for task name #{task_name}" if Mutx::Support::Log
        $results.find({"status" => /started|running/, "task.name" => task_name}).to_a
      end

      def self.only_started_for_task task_name
        Mutx::Support::Log.debug "Getting db running for task name #{task_name}" if Mutx::Support::Log
        $results.find({"status" => "started", "task.name" => task_name}).to_a
      end

      #def self.update_only_started
      #  $results.update_many({"status" => "started"}, {"$set" => {"status" => "never_started"}})
      #end

      def self.started!
        $results.find({"status" => "started"}).to_a
      end

      def self.update_last_exec_time
        $results.update_many({"cronneable" => "on"}, {"$set" => {"last_exec_time" => Time.now.utc}})
      end

      def self.only_running_for_task task_name
        Mutx::Support::Log.debug "Getting db running for task name #{task_name}" if Mutx::Support::Log
        $results.find({"status" => "running", "task.name" => task_name}).to_a
      end

      def self.delete_started_result result_id
        Mutx::Support::Log.debug "Deletting db started result with id #{result_id}" if Mutx::Support::Log
        #Fix because MD5
        #task_id = task_id.to_i if task_id.respond_to? :to_i
        res = $results.delete_one({"_id" => result_id})
        res.n==1
      end
      #Cron_end

      def self.update_stop_bots_off task_id
        $tasks.update_one({"_id" => task_id}, {"$set" => {"stop_bots" => "off"}})
      end

      def self.update_stop_bots_on task_id
        $tasks.update_one({"_id" => task_id}, {"$set" => {"stop_bots" => "on"}})
      end

      def self.mark_notified result_id
        $results.update_one({"_id" => result_id}, {"$set" => {"notified" => "yes"}})
      end

      def self.last_notified(quantity) #get last N notified results
        quantity = 5 if ( (quantity.to_i.eql? 0) || (quantity.to_i <= 0) ) 
        $results.find({"notified" => "yes"}).limit(quantity.to_i).sort({"started_at" => -1}).to_a
      end

      def self.file_attached result_id
        $results.update_one({"_id" => result_id}, {"$set" => {"file_attached" => "yes"}})
      end

      def self.update_status task_id, status
        $tasks.update_one({"_id" => task_id}, {"$set" => {"task_status" => status}})
      end

      def self.active_tasks
        self.all_tasks
      end

      def self.delete_task task_id
        Mutx::Support::Log.debug "Deletting db task with id #{task_id}" if Mutx::Support::Log
        #Fix because MD5
        #task_id = task_id.to_i if task_id.respond_to? :to_i
        res = $tasks.delete_one({"_id" => task_id})
        res.n==1
      end

      def self.update_tasks_with_custom_param_id custom_param_id
        self.tasks_with_custom_param_id(custom_param_id).each do |task_data|
          task_data["custom_params"].delete(custom_param_id)
          self.update_task task_data
        end
      end

    ########################################
    # INPUTS
    #
    #
    #


    def self.insert_input input_data
      Mutx::Support::Log.debug "Inserting input [#{input_data}]" if Mutx::Support::Log
      $inputs.insert_one(input_data)
    end

    def self.input_data_for_id(id)
      res = $inputs.find({"_id" => id})
      res = res.to_a.first if res.respond_to? :to_a
      res
    end

    ########################################
    # REPOS
    #
    #
    #
    def self.all_repos
      res = $repos.find({})
      res.to_a if res.respond_to? :to_a
      res
    end

    def self.insert_repo repo_data
      res = $repos.find({"repo_name" => repo_data["repo_name"]})
      (Mutx::Support::Log.debug "Inserting repo [#{repo_data}]" if Mutx::Support::Log
      $repos.insert_one(repo_data)) if res.to_a.empty?
    end

    def self.update_repo_data repo_data
=begin
      aux = repo_data["value"].to_json
      aux_1 = JSON.parse(aux) #=> HASH
      repo_data["value"] = JSON.parse aux_1#value en json!
=end
      aux = JSON.parse repo_data["value"].gsub('=>', ':')
      repo_data["value"] = aux
      #only update if repo exists and token is valid
      res = $repos.find({"repo_name" => repo_data["repo_name"]})
      (Mutx::Support::Log.debug "Updating repo #{repo_data["repo_name"]}" if Mutx::Support::Log
      $repos.update_one({"repo_name" => repo_data["repo_name"]}, {"$set" => {"value" => repo_data["value"], "last_update" => repo_data["last_update"]} }) ) if ( (!res.to_a.empty?) && (res.to_a[0]["repo_token"].eql? repo_data["repo_token"]) )
    end

    def self.repo_data_for_name(name)
      res = $repos.find({"repo_name" => name})
      res = res.to_a.first if res.respond_to? :to_a
      res
    end


    ########################################
    # CUSTOM PARAMS
    #
    #
    #

    def self.custom_params_list
      Mutx::Support::Log.debug "Getting db custom params list" if Mutx::Support::Log
      $custom_params.find({}).to_a
    end

    def self.insert_custom_param custom_param_data
      Mutx::Support::Log.debug "Inserting custom param [#{custom_param_data}]" if Mutx::Support::Log
      $custom_params.insert_one(custom_param_data)
    end

    # Update record for a given custom param
    # $param [Hash] custom_param_data
    def self.update_custom_param custom_param_data
      Mutx::Support::Log.debug "Updating db custom param [#{custom_param_data}]" if Mutx::Support::Log
      id = custom_param_data["_id"]
      $custom_params.update_one( {"_id" => custom_param_data["_id"]}, custom_param_data)
    end

    # Returns the entire record for a given id
    # $param [String] custom_param_id
    # $return [Hash] all custom param data
    def self.get_custom_param custom_param_id
      Mutx::Support::Log.debug "Getting db custom param data for custom param id #{custom_param_id}" if Mutx::Support::Log

      res = $custom_params.find({"_id" => custom_param_id}).to_a.first
    end

    def self.param_id_for_name custom_param_name
      Mutx::Support::Log.debug "Getting db custom param id for custom param name [#{custom_param_name}]" if Mutx::Support::Log
      res = self.custom_param_for_name(custom_param_name)
      res["_id"] if res
    end

    def self.custom_param_for_name custom_param_name
      Mutx::Support::Log.debug "Getting db custom param data for custom param name [#{custom_param_name}]" if Mutx::Support::Log
      $custom_params.find({"name" => custom_param_name}).to_a.first
    end

    def self.exist_custom_param_name? name
      !self.param_id_for_name(name).nil?
    end

    def self.exist_custom_param_id? param_id
      # !$custom_params.find({"_id" => param_id}).nil?
      $custom_params.find({"_id" => param_id})
    end

    def self.delete_custom_param custom_param_id
      Mutx::Support::Log.debug "Deleting db custom param for custom param id [#{custom_param_id}]" if Mutx::Support::Log
      $custom_params.delete_one({"_id" => custom_param_id})

      self.update_tasks_with_custom_param_id(custom_param_id)
    end



    def self.required_params_ids
      $custom_params.find({"required" => true},{:fields => ["_id"]})
    end

    def self.exist_task_with_custom_param_id? custom_param_id
      !self.tasks_with_custom_param_id(custom_param_id).empty?
    end

    def self.tasks_names_with_custom_param_id custom_param_id
      self.tasks_with_custom_param_id(custom_param_id).map do |task|
        task["name"]
      end
    end

    def self.tasks_with_custom_param_id custom_param_id
      $tasks.find({}).to_a.select do |task|
        task["custom_params"].include? custom_param_id
      end
    end


    ######################################3
    # RESULTS
    #
    #

      # Creates a result data andc
      # returns de id for that register
      # $param [Hash] execution_data
      # $return [String] id for created result
      def self.insert_result(result_data)
        begin
          $results.insert_one(result_data)
          true
        rescue
          false
        end
      end

      # Returns all results for a given task_id
      def self.results_for task_id
        #FIXED
        #$results.find({"task.id" => ensure_int(task_id)}).sort("started_at" => -1).to_a #Cant convert MD5 to integer
        $results.find({"task.id" => (task_id)}).sort("started_at" => -1).to_a

      end

      # Updates result register with the given data
      #
      def self.update_result result_data_structure
        begin
          $results.update_one( {"_id" => result_data_structure["_id"]}, result_data_structure)
          true
        rescue
          false
        end
      end

      def self.result_data_for_id(result_id)
        #FIXED
        #result_id = self.ensure_int(result_id) #Cant convert MD5 to integer
        res = $results.find({"_id" => result_id})
        res = res.to_a.first if res.respond_to? :to_a
        res
      end

      def self.running_results_for_task_id task_id
        $results.find({"task.id" => task_id, "status" => /running|started/}).sort("started_at" => -1).to_a
      end

      def self.running_results
        $results.find({"status" => /running|started/}).to_a
      end


      # Returns value as Fixnum if it is not
      # $param [Object] value
      # $return [Fixnum]
      def self.ensure_int(value)
        value = value.to_i if value.respond_to? :to_i
        value
      end

      # Returns all result
      # $return [Array] results from results coll
      def self.all_results
        $results.find({}).sort('_id' => -1).to_a
      end

      def self.all_results_ids
        $results.find({},{"_id" => 1}, :sort => ['_id', -1]).to_a
      end

      def self.find_results_for_key key
        $results.find({$or => [{"task.name" => /#{key}/}, {"execution_name" => /#{key}/ }, {"summary" => /#{key}/ }, {"command" => /#{key}/ }]}).to_a
      end

      def self.last_result_for_task task_id
        $results.find({}, :sort => ['_id', -1])
      end

      def self.find_results_for_task task_name
        task_id = self.task_id_for task_name
        self.results_for task_id
      end

      def self.find_results_for_status status
        $results.find({$or => [{"summary" => /#{status}/}, {"status" => /#{status}/ }]},{"_id" => 1}).to_a
      end

    ######################################3
    # CONFIG
    #
    #  
      def self.insert_config config_object
        Mutx::Support::Log.debug "db insert configuration [#{document}]" if Mutx::Support::Log
        $configuration.insert_one(config_object)
      end

      def self.configuration
        Mutx::Support::Log.debug "Getting db configuration data" if Mutx::Support::Log
        $configuration.find({}).to_a.first
      end


    end
  end
end
