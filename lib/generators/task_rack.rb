# encoding: utf-8
require 'erb'
require 'zip'
require 'fileutils'

module Mutx
  class TaskRack < Thor::Group

    	include Thor::Actions

      desc "Generates files needed by Mutx"


      def choose_working_branch

        # Gets the list of branches
        branch_list=Mutx::Support::Git.branch_list
        branch_list << "local files"

        begin
          system "clear"
          Mutx::Support::Logo.show
          puts "
  You have to choose one of the following branches to tell Mutx where to work with:"
          # Print the options
          branch_list.each_with_index do |branch_name, index|
            puts "\t(#{index + 1}) - #{branch_name}"
          end
          print "\n\t     Your option:"; option = STDIN.gets

          #Converted to Fixnum
          option = option.gsub!("\n","").to_i

        end until (1..branch_list.size).include? option


        selected_branch_name = branch_list[option-1]
        puts "
        Lets work on '#{selected_branch_name}'

        "
        
        Mutx::Support::Git.checkout_to(selected_branch_name) unless (@local = selected_branch_name == "local files")
        Mutx::Support::Git.pull
      end

  # ==============================
  # Start install task
  #
  #
  #
      def self.source_root
        File.dirname(__FILE__) + "/templates/"
      end

      def creates_mutx_folder
        empty_directory "mutx"
      end

      def creates_mutx_temp_folder
        empty_directory "mutx/temp"
      end

      def creates_mutx_out
        empty_directory "mutx/out"
      end

      def creates_mutx_log_dir
        empty_directory "mutx/logs"
      end

      def creates_mutx_pids_dir
        empty_directory "mutx/pids"
      end

      def creates_mutx_conf_dir
        empty_directory "mutx/conf"
      end

      def creates_mutx_cron_dir
        empty_directory "mutx/cron"
      end

      def creates_mutx_templates_dir
        empty_directory "mutx/templates"
      end


      def copy_server_file
        unless File.exist? "#{Dir.pwd}/mutx/config.ru"
      	 template "config.ru.tt", "#{Dir.pwd}/mutx/config.ru"

        else

          if yes?("\n  It seems that you already have a config.ru file. DO YOU WANT TO REPLACE IT? (yes/no)", color = :green)
            template "config.ru.tt", "#{Dir.pwd}/mutx/config.ru"
          else
            raise "The existing config.ru file must be replaced with config.ru file from Mutx"
          end
        end
      end


      def copy_mutx_conf
        template "mutx.conf.tt", "#{Dir.pwd}/mutx/conf/mutx.conf" unless File.exist? "#{Dir.pwd}/mutx/conf/mutx.conf"
      end

      def updating_git_usage_as_false_if_local
        if @local
          config_file_content = JSON.parse(IO.read("#{Dir.pwd}/mutx/conf/mutx.conf"))
          config_file_content["use_git"] = false
          content_to_save = config_file_content.to_json.gsub(",",",\n").gsub("{","{\n")
          IO.write("#{Dir.pwd}/mutx/conf/mutx.conf",content_to_save)
        end
      end

      def copy_mutx_log_file
        template "mutx.log.tt", "#{Dir.pwd}/mutx/logs/mutx.log" unless File.exist? "#{Dir.pwd}/mutx/logs/mutx.log"
      end

      def copy_mutx_cron_alive
        template "cron_alive.sh.tt", "#{Dir.pwd}/mutx/cron/cron_alive.sh" unless File.exist? "#{Dir.pwd}/mutx/cron/cron_alive.sh"
      end
      
      def copy_mutx_cron
        template "cron.rb.tt", "#{Dir.pwd}/mutx/cron/cron.rb" unless File.exist? "#{Dir.pwd}/mutx/cron/cron.rb"
      end

      def copy_mutx_templates
        dir = "#{Dir.pwd}"
        template "mutx_template.html.erb.zip", "#{Dir.pwd}/mutx/templates/mutx_template.html.erb.zip" unless File.exist? "#{Dir.pwd}/mutx/templates/mutx_template.html.erb.zip"
        FileUtils.cd("#{Dir.pwd}/mutx/templates/")
        `unzip mutx_template.html.erb.zip`
        `rm mutx_template.html.erb.zip`
        FileUtils.cd(dir)
      end
      
      def copy_mutx_cronned_task
        template "cronned_task.rb.tt", "#{Dir.pwd}/mutx/cron/cronned_task.rb" unless File.exist? "#{Dir.pwd}/mutx/cron/cronned_task.rb"
      end

      def copy_sidekiq_log_file
        template "sidekiq.log.tt", "#{Dir.pwd}/mutx/logs/sidekiq.log" unless File.exist? "#{Dir.pwd}/mutx/logs/sidekiq.log"
      end

      def copy_unicorn_config_file
        unless File.exist? "#{Dir.pwd}/mutx/unicorn.rb"
          template "unicorn.rb.tt", "#{Dir.pwd}/mutx/unicorn.rb"
          @unicorn_created = true
        end
      end

      def update_gitignore
        path = "#{Dir.pwd}/.gitignore"
        if File.exist? path
          f = File.open(path, "a+")
          content = ""
          f.each_line{|line| content += line}
          f.write "\n" unless content[-1] == "\n"
          f.write "mutx/\n" unless content.include? "mutx/"
          f.write "mutx/*\n" unless content.include? "mutx/*"


          f.close
        end
      end

      def update_gemfile
        path = "#{Dir.pwd}/Gemfile"
        if File.exist? path
          f = File.open(path, "a+")
          content = ""
          f.each_line{|line| content += line}
          f.write "\n" unless content[-1] == "\n"
          ["gem 'mutx'"].each do |file_name|
            f.write "#{file_name}\n" unless content.include? "#{file_name}"
          end
        end

      end

      def push_changes
        unless @local
          Mutx::Support::Git.add_commit "Mutx: Commit after install command execution"
          Mutx::Support::Git.push_origin_to_actual_branch
        end
      end

  end
end