# encoding: utf-8
module Mutx
  class Execution

    def self.run! execution_request_data

        result = Mutx::Results::Result.new(execution_request_data)
        Mutx::Support::Log.debug "Result created with id => #{result.id}" if Mutx::Support::Log

        result.save!

        Mutx::Support::Log.debug "Execution type #{result.task_type}" if Mutx::Support::Log
        Mutx::Workers::Executor.perform_async(result.id)
        Mutx::Support::Log.debug "#{result.task_type.capitalize}(#{result.id}) started" if Mutx::Support::Log
        result.id
    end

    def self.attachment_path
      "#{Dir.pwd}/mutx/out/" + ENV["_id"] + "/attachment"
    end
  end
end