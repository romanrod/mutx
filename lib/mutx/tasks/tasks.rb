# encoding: utf-8
module Mutx
  module Tasks

    def self.is_there_task_with? name, type=nil
      self.task_id_for name, type
    end

    # Returns a list of tasks id
    # @param [Boolean] type or not
    # @return [Array] a list of task ids
    def self.tasks type=nil
      Mutx::Support::Log.debug "Tasks:Getting all tasks ids" if Mutx::Support::Log
      Mutx::Database::MongoConnector.tasks(type)
    end

    # Returns the id for given task name
    # @param [String] task name
    # @return [Fixnum] task id
    def self.task_id_for(task_name, type=nil)
      Mutx::Support::Log.debug "Tasks:Getting task id for #{task_name}" if Mutx::Support::Log
      Mutx::Database::MongoConnector.task_id_for(task_name, type)
    end

    # Returns the ids for running tasks
    # @return [Array] of task ids
    def self.running_tasks
      Mutx::Database::MongoConnector.running_tasks
    end

    def self.running_tests
      Mutx::Database::MongoConnector.running_tests
    end

    def self.exist_task? task_id
      !Mutx::Database::MongoConnector.task_data_for(task_id).nil?
    end

    def self.exist? task_id
        self.exist_task? task_id
    end

    def self.is_there_running_executions_for? task_name
        self.number_of_running_executions_for_task(task_name)>0
    end

    def self.number_of_running_executions_for_task task_name
      Mutx::Database::MongoConnector.running_for_task(task_name).size
    end

    def self.delete! task_id
      if self.exist_task? task_id
        Mutx::Database::MongoConnector.delete_task task_id
        success = true
        message = "Task deleted!"
      else
        success = false
        message = "Could not find task with id '#{task_id}'"
      end
      {success:success, message:message}
    end

  end
end