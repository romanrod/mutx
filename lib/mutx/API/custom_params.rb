# enconding: utf-8
module Mutx
  module API
    module CustomParams


      def self.set data

        # Sanity

        data = self.sanitize data


        response = case data["action"]
        when "new"
          Mutx::Tasks::Custom::Param.validate_and_create(data)
        when "edit"
          Mutx::Tasks::Custom::Param.validate_and_update(data)
        when "delete"
          Mutx::Tasks::Custom::Param.delete_this(data)
        end
        response
      end

      def self.get custom_param_name
        custom_param_name.gsub!("%20"," ")
        param = Mutx::Database::MongoConnector.custom_param_for_name custom_param_name
        param || {}
      end

      # DATABASE COLLECTION ACTIONS

      def self.list
        Mutx::Database::MongoConnector.custom_params_list
      end

      def self.sanitize data
        if data["type"]
          case data["type"].downcase
            when /select/
              data["options"] = data["options"].split(",").uniq.sort
              data["options"].unshift "none" unless data["required"]
              data.delete("value")
            when /text/
              data.delete("options")
            when /json/
              data.delete("options")
              Mutx::Support::Log.debug "custom_param: value for json#{data["value"]}"
          end

          data["required"] = data["required"]=="on"

        end
        data["_id"] = data["_id"].to_i if data.keys.include? "_id"

        data
      end


    end
  end
end