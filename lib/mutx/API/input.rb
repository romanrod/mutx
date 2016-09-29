module Mutx
  module API
    class Input

        attr_reader  :id, :name, :type, :options, :required, :value, :created_at, :reference

        def initialize definition
          Mutx::Support::Log.debug "definition in new => #{definition}"
          id = definition["_id"] || Mutx::Database::MongoConnector.generate_id
          @id       = id
          @reference = definition["reference"] 
          @name     = definition["name"]
          @value    = definition["value"]
          @created_at = Time.now.utc
        end

        def structure
          {
            "_id" => id,
            "reference" => reference,
            "name" => name,
            "value" => value,
            "created_at" => created_at
          }
        end

        def self.validate_and_create definition
          if insert!(definition)
            {action:"create", success:true, message:"Input #{definition["name"]} created"}
          else
            {action:"create", success:false, message:"Input #{definition["name"]} could not be created"}
          end
        end

        #GET
				def self.get_data id, query_string=nil
				  result = self.info id
				end

				def self.info id
				  result = Mutx::Database::MongoConnector.input_data_for_id(id)
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
          #definition.delete("action")
          Mutx::Database::MongoConnector.insert_input(self.new(definition).structure)
        end

        def self.update! definition
          definition.delete("action")
          Mutx::Database::MongoConnector.update_custom_param(self.new(definition).structure)
        end

        def self.delete param_id
          Mutx::Database::MongoConnector.delete_custom_param param_id
        end

    end
  end
end
