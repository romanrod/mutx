# encoding: utf-8
module Mutx
  module Commands
    def self.bye
        Mutx::Support::Log.debug "#{self}:#{__method__}" if Mutx::Support::Log
        self.stop
        Mutx::Support::FilesCleanner.delete_mutx_folder
        puts "Files cleanned"
        puts "Bye!..."
    end
  end
end