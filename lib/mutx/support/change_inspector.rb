module Mutx
  module Support
    module ChangeInspector

      # Evaluates if code has been changed. If yes, performs a git reset hard and git pull
      # Update commit log into Database and return true
      # Returns true if there is a change in code.
      # Consider true if git usage is false
      # @return [Boolean]

      def self.is_there_a_change?
        if Mutx::Support::Configuration.use_git?
          if Mutx::Database::MongoConnector.last_commit != (last_repo_commit  = Mutx::Support::Git.last_remote_commit)
            Mutx::Support::Log.debug "Git has been changed. Perform code update" if Mutx::Support::Log
            Mutx::Support::Git.reset_hard_and_pull
            Mutx::Database::MongoConnector.insert_commit(last_repo_commit)
            Mutx::Support::Log.debug "Commit log updated on database" if Mutx::Support::Log
            true
          else
            Mutx::Support::Log.debug "No git changes" if Mutx::Support::Log
            false
          end
        else
          true
        end
      end

    end
  end
end