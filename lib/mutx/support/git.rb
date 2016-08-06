# encoding: UTF-8
# require "git"

module Mutx
  module Support
    class Git

          def self.branch_list
            self.remote_branches.map do |branch|
              branch.gsub("*","").gsub(" ","").gsub("origin/","")
            end.select do |branch|
              not (branch.include? "HEAD" or branch.include? "/")
            end
          end

          def self.remote_branches
            Mutx::Support::Console.execute("git branch -r")
          end

          def self.fetch
            Mutx::Support::Console.execute("git fetch")
          end

          def self.branch
            branch_name = self.branches.select{|branch| branch.include? "*"}.first
            if branch_name.respond_to? :gsub
              branch_name.gsub("*","").gsub(" ","") unless branch_name.nil?
            else
              branch_name
            end
          end

          def self.actual_branch; self.branch; end

          def self.branches
            Mutx::Support::Console.execute("git branch").split("\n")
          end

          def self.git_add_commit msg=nil
            self.add_all
            self.commit msg
          end

          def self.add_all
            Mutx::Support::Console.execute("git add .")
          end

          def self.add_file filename
            Mutx::Support::Console.execute("git add #{filename}")
          end

          def self.push
            Mutx::Support::Console.execute("git push")
          end

          def self.git_push_origin_to branch_name=nil
            branch_name = self.branch if branch_name.nil?
            Mutx::Support::Console.execute("git push origin #{branch_name}")
          end

          def self.reset_hard
            Mutx::Support::Console.execute("git reset --hard")
          end

          def self.reset_hard_and_pull
            self.reset_hard and self.pull
          end

          def self.git_push_origin_to_actual_branch
            branch_name = self.branch
            self.git_push_origin_to branch_name
          end

          def self.git_push_origin_to_actual_branch
            git_push_origin_to(self.actual_branch)
          end

          def self.commit msg = nil
            # self.ensure_being_at_mutx_branch
            msg = "KAYA COMMIT #{Time.new.strftime('%d %m %Y %H:%M:%S')}" if msg.nil?
            Mutx::Support::Console.execute"git commit -m '#{msg}'"
          end

          def self.create_branch_and_checkout branch
            Mutx::Support::Console.execute("git checkout -b #{branch}")
          end

          def self.delete_branch branch
            checkout_to "master"
            Mutx::Support::Console.execute("git branch -D #{branch}")
          end

          # Performs pull from actual branc
          def self.pull
            self.pull_from(self.actual_branch)
          end

          def self.pull_from(branch_name=nil)
            branch_name = self.branch if branch_name.nil?
            Mutx::Support::Console.execute("git pull origin #{branch_name}")
          end

          def self.return_to_branch branch
            self.checkout_to branch
          end

          def self.checkout_to branch
            Mutx::Support::Console.execute("git checkout #{branch}") unless self.actual_branch == branch
          end

          def self.checkout_and_pull_from branch_name=nil
            self.checkout_to(branch_name) if branch_name
            branch_name = self.branch if branch_name.nil?
            self.pull_from branch_name
          end

          # Returns las commit id.
          # This method is used by Execution class to verify changes before each execution
          # @param [String] the name of the project (folder project)
          # @return [String] the id for the las commit
          def self.get_last_commit_id
            self.commits_ids.map do |commit|
                commit.gsub("commit ","")
            end.first
          end

          def self.commits_ids
            log = self.log
            if log.respond_to? :split
              log.split('\n').select do |line|
                  self.is_commit_id? line
              end
            else
              []
            end
          end

          def self.commits
            log = self.log
            if log.respond_to? :split
              log.split("commit")[1..-1] 
            else
              []
            end
          end

          def self.is_commit_id? line
            line.start_with? "commit "
          end

          def self.last_remote_commit
            remotes = self.remote_commits
            remotes.first if remotes.respond_to? :first
          end

          def self.up_to_date?
            self.get_last_commit_id == self.last_remote_commit
          end

          def self.remote_commits
            self.remote_log.split("commit")[1..-1]
          end

          def self.remote_log
            self.fetch
            Mutx::Support::Console.execute "git log origin/#{self.actual_branch}"
          end

          def self.log
            res = Mutx::Support::Console.execute "git log"

          end

          def self.log_last_commit
            "Commit: #{self.commits.first}"
          end

          def self.last_commit
            self.commits.first
          end

          def self.is_there_commit_id_diff? obtained_commit
              obtained_commit != self.last_commit_id
          end

          def self.remote_url
            res = Mutx::Support::Console.execute("git config --get remote.origin.url").split("\n").first.gsub(":","/").gsub("git@", 'http://').chop
            res[0..-5] if res.end_with? ".git"
          end

          # Returns an Array with the existing files on .gitignore
          # @param [Array]
          def self.get_actual_lines
            f = File.open("#{Dir.pwd}/.gitignore","r")
            files_list = []
            f.each_line do |line|
              files_list << line.gsub("\n","").gsub(" ","")
            end
            files_list
          end
    end
  end
end