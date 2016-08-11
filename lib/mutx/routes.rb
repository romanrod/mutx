# encoding: utf-8
require "cuba"

include Mote::Helpers

# Mutx::Support::Log.start
Mutx::Support::Configuration.get

Mutx::Database::MongoConnector.new Mutx::Support::Configuration.db_connection_data

Cuba.define do

  $tasks_counter = 0

  request = Mutx::Support::Request.new(req)

  Mutx::Support::Log.debug "REQUEST '#{request.request}" if Mutx::Support::Log

  begin


# ========================================================================
# COMMON INIT
#
#
    on post do

      on "admin/config/reload" do
        on true do

          # Guarda el nuevo archivo de configuración si es válido

          Mutx::Support::Configuration.get
        end
      end



      on "admin/config/save" do
        on true do
          data = req.params.dup

          # Validar la data recibida
          # Insertar un nuevo registro y deshabilitar el resto

        end
      end

      on "admin/delete-custom-param" do

        on true do

          data = req.params.dup

          data["_id"] = data["_id"].to_i

          response = Mutx::API::CustomParams.set data # Creates or update

          path = "/admin/custom/params"
          path += "?msg=#{response[:message]}" if response[:message]

          res.redirect path
        end

      end

      # TO EDIT OR CREATE CUSTOM PARAM
      on "admin/custom-param" do

        on true do

          data = req.params.dup

          Mutx::Support::Log.debug "data is => #{data}"

          response = Mutx::API::CustomParams.set data # Creates or update

          path = "/admin/custom/params"

          # Si success es true
          Mutx::Support::Log.debug "#{response}"

          unless response[:success]

            path += "/#{data['_id']}" if data["_id"]
            path += "/#{data['action']}"
          end
          path += "?msg=#{response[:message]}"

          path += "&name=#{data['name']}&action=#{data['action']}&type=#{data['type']}&value=#{data['value']}&options=#{data['options']}&required=data['required']&clean=false" unless response[:success]

          res.redirect path

        end

      end


      on "admin/tasks/add-edit" do

        on true do

          data = req.params.dup

          Mutx::Support::Log.debug "#{data['action']} Task - Recieved data => #{data}"

          # Extracts custom params
          custom_params = data.keys.select do |field|
            field.start_with? "custom_param_" and data.delete(field)
          end.inject([]) do |res, value|
            res<<value.gsub("custom_param_",""); res
          end

          data["custom_params"] = custom_params

          Mutx::Support::Log.debug "DATA SENT TO Task.set is => #{data}"

          response = Mutx::API::Tasks.set data # Creates or update

          Mutx::Support::Log.debug "response => []#{response}"
          
          path = "/admin/tasks"

          Mutx::Support::Log.debug "#{response}"

          unless response[:success]

            path += "/#{data['_id']}" if data["_id"]
            path += "/#{data['action']}"
          else
            path+= "/list"
          end
          path += "?msg=#{response[:message]}"

          path += "&name=#{data['name']}&action=#{data['action']}&type=#{data['type']}&value=#{data['value']}&options=#{data['options']}&required=data['required']&clean=false" unless response[:success]

          res.redirect path

        end
      end

      on "admin/tasks/delete" do

        on true do

          data = req.params.dup

          Mutx::Support::Log.debug "DATA SENT TO Task.delete is => #{data}"

          result = Mutx::Tasks.delete! data["task_id"]
          path = "/admin/tasks/list"

          path += "?msg=#{result[:message]}"

          res.redirect path
        end
      end
    end




    on get do

# ========================================================================
# HELP
#
#
      on "help/:page" do |page|
        args ={page:page}
        template = Mote.parse(File.read("#{Mutx::View.path}/help.mote"),self, [:args])
        res.write template.call(:args => args)
      end

      on "help" do
        res.redirect "/help/main"
      end


# ========================================================================
# VIEW ROUTES
#
#
#
      # INVERTIR /log con  /:result_id

      on "results/:result_id/log" do |result_id|
        template = Mote.parse(File.read("#{Mutx::View.path}/results/console.mote"),self, [:result_id])
        res.write template.call(result_id:result_id)
      end


      # INVERTIR /log con  /:result_id
      on "results/report/:result_id" do |result_id|
        result = Mutx::Results::Result.get(result_id)
        res.redirect "/404/There%20is%20no%20result%20for%20id=#{result_id}" if result.nil?
        result.mark_as_saw! if (result.finished? or result.stopped?)
        if result.finished? and !result.stopped? and result.html_report.size > 0
          template = Mote.parse(File.read("#{Mutx::View.path}/results/report.mote"),self, [:result])
          res.write template.call(result:result)
        #else
        #  res.redirect "results/#{result_id}/log"
        end
      end

      on "results/:result_id/reset" do |result_id|
        result = Mutx::API::Execution.reset(result_id)
        res.redirect "/results?msg=#{result['message']}"
      end

      on "results/task/:task_name" do |task_name|
        query_string = Mutx::Support::QueryString.new req
        task_name.gsub!("%20"," ")
        args = {task_name:task_name, query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Results", args:args)
      end

      on "results/all" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"All Results", args:args)
      end

      on "results" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Results", args:args)
      end

## ========================================================================
# TASKS CRUD
#
#
#

      on "admin/tasks/new" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, action:"new"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Add Task", args:args)
      end

      on "admin/tasks/:task_id/edit" do |task_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, task_id:task_id, action:"edit"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Edit Task", args:args)
      end

      on "admin/tasks/:task_id/delete" do |task_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, task_id:task_id}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Delete Task", args:args)
      end

      on "admin/tasks/:task_id/view" do |task_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, task_id:task_id, action:"view"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"View Task", args:args)
      end

      on "admin/tasks" do
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Edit Tasks", args:{:query_string => Mutx::Support::QueryString.new(req)})
      end

      on "admin/custom/params/new" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, action:"new"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"New Custom Param", args:args)
      end

      on "admin/custom/params/:custom_id/edit" do |custom_param_id|
        query_string = Mutx::Support::QueryString.new req
        res.redirect "/admin/custom/params?msg=Could not find Custom Parameter" unless Mutx::Tasks::Custom::Params.exist? custom_param_id
        args = {query_string:query_string, custom_param_id:custom_param_id, action:"edit"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Edit Custom Param", args:args)
      end

      on "admin/custom/params/:custom_id/delete" do |custom_param_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, custom_param_id:custom_param_id, action:"delete"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Delete Custom Param", args:args)
      end

      on "admin/custom/params" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Custom Params", args:args)
      end

      on "admin/config" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"View Configuration", args:args)
      end

      on "admin/config/edit" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Edit Configuration", args:args)
      end




## ===============================================
# TASKS
#
#

      on "tasks/:task/run" do |task_name|
        query_string = Mutx::Support::QueryString.new req
        task_name.gsub!("%20"," ")
        result = Mutx::API::Execution.start task_name, query_string.values
        Mutx::Support::Log.debug "result => #{result}"
        path = if result["execution_id"]
         "/message/task/#{result['execution_id']}"
        else
          "/error?msg=#{result['message']}"
        end
        res.redirect path
      end


      on "message/task/:result_id" do |result_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, result_id:result_id}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Task Message", args:args)
      end


      on "tasks/:task_name" do |task_name|
        query_string = Mutx::Support::QueryString.new req
        task_name.gsub!("%20"," ")
        args = {query_string:query_string, task_name:task_name}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Tasks", args:args)
      end

      on "tasks" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Tasks", args:args)
      end

## ========================================================================
# TESTS
#
#
#

      on "tests/:task/run" do |task_name|
        query_string = Mutx::Support::QueryString.new req
        task_name.gsub!("%20"," ")
        result = Mutx::API::Execution.start task_name, query_string.values, "test"
        Mutx::Support::Log.debug "result => #{result}"
        path = if result["execution_id"]
         "/message/test/#{result['execution_id']}"
        else
          "/error?msg=#{result['message']}"
        end
        res.redirect path
      end

      on "message/test/:result_id" do |result_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, result_id:result_id}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Test Message", args:args)
      end

      on "tests/:task_name" do |task_name|
        query_string = Mutx::Support::QueryString.new req
        Mutx::Support::Log.debug "task_name => #{task_name}"
        task_name.gsub!("%20"," ")
        args = {query_string:query_string, task_name:task_name}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Tests", args:args)
      end

      on "tests" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Tests", args:args)
      end



## ========================================================================
# LOGS
#
#



      on "logs/:log_name" do |log_name|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, log_name:log_name}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Log", args:args)
      end

      on "logs" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Logs", args:args)
      end





# ========================================================================
# SCREENSHOTS
#
#

      on "screenshot/:file_name" do |file_name|
        template = Mote.parse(File.read("#{Mutx::View.path}/screenshot.mote"),self, [:file_name])
        res.write template.call(file_name:file_name)
      end

# ========================================================================
# FEATURE SHOW
#
#
      on "features/file" do
        template = Mote.parse(File.read("#{Mutx::View.path}/features.mote"),self, [:query_string])
        res.write template.call(query_string:Mutx::Support::QueryString.new(req))
      end

# ========================================================================
# FEATURES / LIST
#
#
      on "features" do
        template = Mote.parse(File.read("#{Mutx::View.path}/features.mote"),self, [:query_string])
        res.write template.call(query_string:Mutx::Support::QueryString.new(req))
      end


# ========================================================================
# API ROUTES
#
#
#
      on "api/version" do
        output = { "version" => Mutx::VERSION}
        res.write output.to_json
      end

      on "api/results/:id/data" do |result_id|
        query_string = Mutx::Support::QueryString.new req
        output = Mutx::API::Result.data(result_id, query_string.raw)
        res.write output.to_json
      end

      on "api/results/:id/status" do |result_id|
        output = Mutx::API::Result.status(result_id)
        res.write output.to_json
      end

      on "api/results/:id" do |result_id|
        res.write(Mutx::API::Result.info(result_id).to_json)
      end

      on "api/results/:id/reset" do |result_id|
        result = Mutx::API::Execution.reset(result_id)
        res.write result.to_json
      end

      on "api/tasks/:task/run" do |task_name|
        task_name.gsub!("%20"," ")
        query_string = Mutx::Support::QueryString.new req
        result = Mutx::API::Execution.start task_name, query_string.values
        res.write result.to_json
      end

      on "api/tests/:task/run" do |task_name|
        task_name.gsub!("%20"," ")
        query_string = Mutx::Support::QueryString.new req
        result = Mutx::API::Execution.start task_name, query_string.values
        res.write result.to_json
      end

      on "api/tasks/:id/status" do |task_id|
        output = Mutx::API::Task.status(task_id.to_i)
        res.write output.to_json
      end

      on "api/tests/:id/status" do |task_id|
        output = Mutx::API::Task.status(task_id.to_i)
        res.write output.to_json
      end

      on "api/tasks/running" do
        output = Mutx::API::Tasks.list({running:true, type:"task"})
        res.write output.to_json
      end

      on "api/tests/running" do
        output = Mutx::API::Tasks.list({running:true, type:"task"})
        res.write output.to_json
      end

      on "api/tasks/:id" do |task_id|
        output = Mutx::API::Task.info(task_id)
        res.write output.to_json
      end

      on "api/tests/:id" do |task_id|
        output = Mutx::API::Task.info(task_id)
        res.write output.to_json
      end

      on "api/tasks" do
        output = Mutx::API::Tasks.list({type:"task"})
        res.write output.to_json
      end

      on "api/tests" do
        output = Mutx::API::Tasks.list({type:"test"})
        res.write output.to_json
      end

      on "api/results" do
        output = Mutx::API::Results.show()
        res.write output.to_json
      end

      on "api/custom/params/:name/value" do |name|
        output = {}
        param = Mutx::API::CustomParams.get(name)
        output["app"] = Mutx::Support::Configuration.project_name
        output["request"] = "Custom Parameter value"
        output["custom_param_name"] = param["name"]
        output["value"] = param["value"]
        res.write output.to_json
      end

      on "api/custom/params/:name" do |name|
        output = {}
        param = Mutx::API::CustomParams.get(name)
        output["custom_param"] = param
        output["app"] = Mutx::Support::Configuration.project_name
        res.write output.to_json
      end

      on "api/custom/params" do
        output ={}
        output["custom_params"] = Mutx::API::CustomParams.list()
        output["request"]="Custom Params"
        output["app"]=Mutx::Support::Configuration.project_name
        res.write output.to_json
      end


      on "api/error" do
        query_string = Mutx::Support::QueryString.new req
        output = Mutx::API::Error.show(query_string)
        res.write output.to_json
      end

      on "api" do
        response = {"message" => "Please, refer to /help/api for more information"}
        res.write response.to_json
      end

      on "error" do
        args= {query_string:Mutx::Support::QueryString.new(req), exception:nil}
        template = Mote.parse(File.read("#{Mutx::View.path}/error_handler.mote"),self, [:args])
        res.write template.call(args:args)
      end


# ========================================================================
# CLEAN
#
#
      on "clean" do
        Mutx::Support::Clean.start
        res.redirect "/tasks?msg=Tasks and results cleanned"
      end

# ========================================================================
# REDIRECTS
#
      on "help" do
        res.redirect "/help/main"
      end

      on "404" do
        template = Mote.parse(File.read("#{Mutx::View.path}/not_found.mote"),self, [])
        res.write template.call()
      end

      on "version" do
        res.redirect "api/version"
      end

      on ":any" do
          res.redirect("/tests")
      end

      on "favicon" do
        res.write ""
      end
     
      on root do
        #When go to root path, check for updates on the branch and make a pull if its outdated
        Mutx::Support::Git.pull unless Mutx::Support::Git.up_to_date?
        res.redirect "/tasks"
      end

    end



  rescue => e
    Mutx::Support::Log.error "Cuba: #{e} #{e.backtrace}" if Mutx::Support::Log
    args= {query_string:Mutx::Support::QueryString.new(req), exception:e}
    template = Mote.parse(File.read("#{Mutx::View.path}/error_handler.mote"),self, [:args])
    res.write template.call(args:args)
  end
end