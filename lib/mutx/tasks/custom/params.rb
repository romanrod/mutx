module Mutx
  module Tasks
    module Custom
      module Params
        def self.list
          Mutx::API::CustomParams.list
        end

        def self.param_name_exist? name
          Mutx::Database::MongoConnector.exist_custom_param_name? name
        end

        def self.exist? param_id
          Mutx::Database::MongoConnector.exist_custom_param_id? param_id
        end

        def self.all_required_ids
          Mutx::Database::MongoConnector.required_params_ids
        end

      end
    end
  end
end