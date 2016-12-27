# encoding: utf-8
module Mutx
  class Execution

    def self.run! execution_request_data

        result = Mutx::Results::Result.new(execution_request_data)
        Mutx::Support::Log.debug "Result created with id => #{result.id}" if Mutx::Support::Log

        Dir.mkdir "#{Dir.pwd}/mutx/out" unless Dir.exist? "#{Dir.pwd}/mutx/out"
        Dir.mkdir "#{Dir.pwd}/mutx/out/#{result.id}/attachment"

        result.save!

        Mutx::Support::Log.debug "Execution type #{result.task_type}" if Mutx::Support::Log
        Mutx::Workers::Executor.perform_async(result.id)
        Mutx::Support::Log.debug "#{result.task_type.capitalize}(#{result.id}) started" if Mutx::Support::Log
        result.id
    end

    def self.attachment_path
      str = ARGV.select{|arg| arg.start_with? "_id="}.first
      raise "Could not find execution id" if str.nil?
      id = str.split("=").last
      "#{Dir.pwd}/mutx/out/#{id}/attachment"
    end

  end
end