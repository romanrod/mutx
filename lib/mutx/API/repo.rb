require 'byebug'

module Mutx
  module API
    class Repo

        attr_reader  :id, :name, :type, :options, :required, :value, :last_update, :reference, :repo_token, :repo_name

        def initialize definition
          Mutx::Support::Log.debug "definition in new => #{definition}"
          id = definition["_id"] || Mutx::Database::MongoConnector.generate_id
          @id          = id 
          @repo_name   = definition["name"]
          @repo_token  = definition["token"] || Mutx::Database::MongoConnector.generate_token
          @value       = definition["value"]
          @last_update = Time.now.utc
        end

        def structure
          {
            "_id" => id,
            "repo_name" => repo_name.gsub(" ","_"),
            "repo_token" => repo_token,            
            "value" => value,
            "last_update" => last_update
          }
        end

        def self.validate_and_create definition
          if insert!(definition)
            {action:"create", success:true, message:"Repo #{definition["name"]} created"}
          else
            {action:"create", success:false, message:"Repo #{definition["name"]} could not be created"}
          end
        end

        #GET
				def self.get_data name, query_string=nil
				  result = self.info name
          if result
            result
          else
            {action:"get", success:false, message:"Repo get was nok"}
          end
				end

				def self.info name
				  result = Mutx::Database::MongoConnector.repo_data_for_name(name)
				end
        #GET    

        def self.delete_this data
          if self.delete data["_id"]
            {action:"delete", success:true, message:"Custom Param #{data["name"]} deleted"}
          else
            {action:"delete", success:false, message:"Could not delete custom param #{data["name"]}"}
          end
        end


        def self.validate_json_format definition
          Mutx::Support::Log.debug "Value is a => #{definition['value'].class} => #{definition["value"]}"
          begin
            value = JSON.parse(definition["value"])
            Mutx::Support::Log.debug "NOW Value is a => #{value.class} => #{value}"
            nil
          rescue
            return "Invalid json format"
          end
        end

        def self.insert! definition
          data = self.new(definition).structure
          Mutx::Database::MongoConnector.insert_repo(self.new(definition).structure)
        end

        def self.update! definition
          if Mutx::Database::MongoConnector.update_repo_data(self.new(definition).structure)
            {action:"update", success:true, message:"Repo updated"}
          else
            {action:"update", success:false, message:"Repo could not be updated"}
          end
        end

        def self.delete param_id
          Mutx::Database::MongoConnector.delete_custom_param param_id
        end

    end
  end
end
