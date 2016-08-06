# encoding: utf-8
module Mutx
  class Execution

    def self.run! execution_request_data

      if Mutx::Support::Configuration.use_git?
        Mutx::Support::Git.reset_hard and Mutx::Support::Git.pull
        Mutx::Support::Log.debug "Git pulled" if Mutx::Support::Log
      end
      
        result = Mutx::Results::Result.new(execution_request_data)
        Mutx::Support::Log.debug "Result created with id => #{result.id}" if Mutx::Support::Log

        result.save!

        Mutx::Support::Log.debug "Execution type #{result.task_type}" if Mutx::Support::Log
        Mutx::Workers::Executor.perform_async(result.id)
        Mutx::Support::Log.debug "#{result.task_type.capitalize}(#{result.id}) started" if Mutx::Support::Log
        result.id
    end
  end
end