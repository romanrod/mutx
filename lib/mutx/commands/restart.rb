module Mutx
  module Commands
    def self.restart
      Mutx::Support::Log.debug "#{self}:#{__method__}" if Mutx::Support::Log
      self.stop
      self.start
    end
  end
end