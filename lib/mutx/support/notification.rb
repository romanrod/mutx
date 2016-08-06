# encoding: utf-8
require 'gmail'

module Mutx
  module Support
    class Notification

      include Gmail

      def initialize project_name, base_url=nil
        @project_name = project_name
        @base_url = base_url
        @subject_prefix = "[Mutx] [#{@project_name}] "
        if Mutx::Support::Configuration.notification?
          begin
            @email = Gmail.connect!(Mutx::Support::Configuration.notification_username,Mutx::Support::Configuration.notification_password)
            Mutx::Support::Log.debug "Notification: Login to Gmail Succesfully"
            Mutx::Support::Log.debug "Notification: USING notification TO #{Mutx::Support::Configuration.recipients}"
          rescue => e
            Mutx::Support::Log.error "Notification: ERROR TO CONNECT TO GMAIL #{e}".red
            Mutx::Support::Log.error "Notification: Connecting to GMail error => #{e}"
            @email = NoEmail.new
          end
        else
          @email = NoEmail.new
        end

      end

      def notificate subject, body
        send_email subject, body, Mutx::Support::Configuration.notifications_to
      end

      def send_email message_subject, message_body, path_to_file=nil
        message_subject = "#{@subject_prefix} #{message_subject}"
        begin
          email = @email.compose do
            to Mutx::Support::Configuration.recipients
            subject message_subject
            text_part do
              body message_body
            end
            html_part do
              Mutx::Support::Log.debug "Notification: Attaching report file (#{path_to_file})"
              content_type 'text/html; charset=UTF-8'
              body "<p>#{message_body}</p>"
            end
            add_file path_to_file
          end
          email.deliver!
          Mutx::Support::Log.debug "Notification: Email sent to (#{Mutx::Support::Configuration.recipients}) | Subject: '#{message_subject}' | Message: #{message_body}" if Mutx::Support::Log
        rescue => e
          Mutx::Support::Log.error "Notification: Could not sent email to (#{Mutx::Support::Configuration.recipients}) | Subject: '#{message_subject}' | Message: #{message_body} | #{e}\n #{e.backtrace}" if Mutx::Support::Log
        end

        if path_to_file
          begin
            File.delete path_to_file
            Mutx::Support::Log.debug "Notification: File #{path_to_file} deleted"
          rescue
            Mutx::Support::Log.error "Notification: Could not delete file #{path_to_file}"
          end
        end
      end



      def execution_finished result
        body = "
    Result Summary: #{result.summary}

    Command: #{result.command}

    Execution name: #{result.execution_name}

    Started at: #{result.started_at_formatted}

    Finished at: #{result.finished_at_formatted}

    Elapsed Time: #{result.elapsed_time} seconds

    Custom Params: #{result.custom_params}

    See log at http://#{@base_url}/mutx/results/#{result.id}/log"

        if Mutx::Support::Configuration.attach_report?
          path_to_file = "#{Dir.pwd}/mutx/temp/#{result.id}.html"
          Mutx::Support::Log.debug "Notification: Creating file report to attach to mail (#{path_to_file})"
          File.open("#{path_to_file}","a+"){|f| f.write result.html_report}
          Mutx::Support::Log.debug "Notification: File created (#{path_to_file})"
        end
        message_subject = "Execution Finished (#{result.id}) "
        send_email message_subject, body, path_to_file
      end

      def execution_stopped result, additional_text=nil
        body = "Execution stopped \n#{additional_text}"
        message_subject = "Execution stopped (#{result.id})"
        send_email message_subject, body
      end
    end

    class NoEmail

      def initialize

      end

      def method_missing meth, *args
        begin
        rescue
          Mutx::Support::Log.error "Notification: #{meth} invoked but email is not configured"
        end
      end

    end
  end
end
