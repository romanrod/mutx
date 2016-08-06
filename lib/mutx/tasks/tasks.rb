# encoding: utf-8
module Mutx
  module Tasks

    # def self.cucumber_yml
    #   Mutx::Support::Log.debug "Getting cucumber.yml content" if Mutx::Support::Log
    #   begin
    #     # Try to open cucumber.yml file from root folder
    #     content = YAML.load_file("#{Dir.pwd}/cucumber.yml")
    #   rescue  # Could not find the file
    #     # Try to open from /config/
    #     Mutx::Support::Log.warn "cucumber.yml file not found"  if Mutx::Support::Log
    #     begin
    #       content = YAML.load_file("#{Dir.pwd}/config/cucumber.yml")
    #     rescue # Could not find the file
    #       Mutx::Support::Log.warn "cucumber.yml file not found"  if Mutx::Support::Log
    #       content ={}
    #     end
    #   end

    #   begin
    #     unless content.empty?

    #       content.select do |task_name, command|
    #         command.include? "runnable=true"
    #       end.map do |task_name, command|

    #         command.gsub!(' runnable=true','').gsub!(', ',',')

    #         task_info = command.scan(/info\=\[(.*)\]/).flatten.first

    #         task_info.gsub('<br>','\n') if task_info.respond_to? :gsub

    #         command.gsub!(/info\=\[(.*)\]/,"")

    #         custom_params = command.scan(/custom\=\[(.*)\]/).flatten.first

    #         custom = Mutx::Tasks::Custom::Param.new(custom_params)

    #         command.gsub!(/custom\=\[(.*)\]/,"")

    #         {"task_name" => task_name, "command" => command, "custom" => {}, "info" => task_info}
    #       end
    #     else
    #       []
    #     end
    #   rescue => e
    #     Mutx::Support::Log.error "Tasks: #{e}#{e.backtrace}" if Mutx::Support::Log
    #     []
    #   end
    # end

    # def self.update_tasks
    #   self.update! if Mutx::Support::ChangeInspector.is_there_a_change? or Mutx::Database::MongoConnector.active_tasks.size.zero?
    # end

    # def self.update!
    #   Mutx::Support::Log.debug "Updating tasks" if Mutx::Support::Log
    #   existing_tasks_ids = self.tasks

    #   self.cucumber_yml.each do |task_data|
    #     # If is there a task for the given name task_id will be setted
    #     # and the id will be deleted from existing_tasks_ids
    #     existing_tasks_ids.delete(task_id = is_there_task_with?(task_data["name"]))

    #     if task_id # Update
    #       task = Mutx::Tasks::Task.get(task_id)
    #       task.name= task_data["task_name"]
    #     else
    #       task = Mutx::Tasks::Task.new_task(task_data["task_name"])
    #     end

    #     task.command= task_data["command"]
    #     task.custom = task_data["custom"]
    #     task.info=    task_data["info"]

    #     task.activate! if task_id
    #     Mutx::Support::Log.debug "[#{task.id}:#{task.name}] Task Updated" if Mutx::Support::Log
    #     task.save!
    #   end

    #   unless existing_tasks_ids.empty?
    #     existing_tasks_ids.each do |task_id|
    #       # task = Mutx::Tasks::Task.get(task_id)
    #       # task.deactivate!
    #       Mutx::Tasks.delete! task_id
    #     end
    #   end
    # end

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

    def self.reset!
      Mutx::Support::Log.debug "Resetting tasks status" if Mutx::Support::Log
      self.running_tasks.each do |task|
        Mutx::Tasks::Task.get(task["_id"]).set_ready!
      end
    end

  end
end