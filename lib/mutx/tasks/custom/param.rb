module Mutx
  module Tasks
    module Custom
      class Param

        attr_reader  :id, :name, :type, :options, :required

        VALID_typeS = ["text","select_list","json"]

        def initialize definition
          Mutx::Support::Log.debug "definition in new => #{definition}"
          id = definition["_id"] || Mutx::Database::MongoConnector.generate_id
          @id       = id
          @name     = definition["name"]
          @type     = definition["type"]
          @options  = definition["options"] || []
          # @required = definition["required"]=="on" || false
          @required = definition["required"]
          @value    = definition["value"]
        end

        def self.get custom_id
          data = Mutx::Database::MongoConnector.get_custom_param(custom_id)
          Mutx::Support::Log.debug "#{data}"
          raise "Could not get Custom Param CUSTOM-ID[#{custom_id}]" if data.nil?
          data["value"] = data["value"].to_json if data["type"]=="json"
          Mutx::Support::Log.debug "En self.get antes de hacer self.new(#{data})"
          self.new data
        end

        def structure
          {
            "_id" => id,
            "name" => name,
            "type" => type,
            "options" => options,
            "required" => required,
            "value" => get_value
          }
        end

        def get_value
          if self.type == "json"
            begin
              value = JSON.parse(@value)
            rescue
              @value
            end
          else
            @value
          end
        end

        def self.types
          VALID_typeS
        end

        def self.validate_and_create definition
          errors = validate(definition)
          return { success:false, message:errors.join(" ")} unless errors.empty?
          if insert!(definition)
            {action:"create", success:true, message:"Custom Param #{definition["name"]} created"}
          else
            {action:"create", success:false, message:"Custom Param #{definition["name"]} could not be created"}
          end
        end

        def self.validate_and_update definition
          errors = self.validate(definition)
          return { success:false, message:errors.join(" ")} unless errors.empty?
          if self.update! definition
            {action:"edit", success:true, message:"Custom Param #{definition["name"]} updated"}
          else
            {action:"edit", success:false, message:"Custom Param #{definition["name"]} could not be updated"}
          end
        end

        def self.delete_this data
          if self.delete data["_id"]
            {action:"delete", success:true, message:"Custom Param #{data["name"]} deleted"}
          else
            {action:"delete", success:false, message:"Could not delete custom param #{data["name"]}"}
          end
        end

        def self.validate definition
          errors = []
          if definition["action"] == "edit"

            errors << self.validate_name_with_id(definition)
          else
            errors << self.validate_name(definition)
          end
          errors << self.validate_type(definition["type"])
          errors << self.validate_options(definition["options"])
          errors << self.validate_value_for_type(definition)
          errors.compact
        end

        def self.validate_value_for_type definition
          case definition["type"]
          when "select_list"
            self.validate_required_for_select definition
          when "json"
            self.validate_json_format definition
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

        def self.validate_required_for_select definition
          # cannot define as required select list with no values on options
          if definition["required"]
             return "At least one value on options field must be defined for required Select List custom parameter." if definition["options"].size.zero?
          end
        end

        def self.insert! definition
          definition.delete("action")
          Mutx::Database::MongoConnector.insert_custom_param(self.new(definition).structure)
        end

        def self.update! definition
          definition.delete("action")
          Mutx::Database::MongoConnector.update_custom_param(self.new(definition).structure)
        end

        def self.delete param_id
          Mutx::Database::MongoConnector.delete_custom_param param_id
        end

        def self.validate_name definition
          return "Custom param name not povided" if definition["name"].nil?
          if (param_id = Mutx::Database::MongoConnector.param_id_for_name(definition["name"]))
            return "A custom param with the name #{definition['name']} already exists (#{param_id})"
          end
          self.validate_special_chars_for_name definition
        end

        def self.validate_name_with_id definition
          db_id = Mutx::Database::MongoConnector.param_id_for_name(definition["name"]).to_i
          unless db_id.zero?
            return "There is another custom param with the name (#{definition['name']})" if db_id != definition["_id"]
          end
          self.validate_special_chars_for_name definition
        end

        def self.validate_special_chars_for_name definition
          return "Only word chars are allowed in name definition" if definition["name"].gsub(" ","") =~ /\W/
        end

        def self.validate_type type
          return "You have to select type of custom param" if type == "Select..."
          "Invalid type '#{type}'" unless VALID_typeS.include? type.downcase
        end

        def self.validate_options options
        end



      end
    end
  end
end
