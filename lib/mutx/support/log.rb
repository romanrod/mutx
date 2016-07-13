module Mutx
	module Support
		class Log
			def self.start
				@@logger ||= Logger.new("#{Dir.pwd}/mutx/logs/mutx.log",1,1024*1024) if self.exist?
			end

			def self.debug output
				@@logger.debug output if self.exist?
			end

			def self.info output
				@@logger.info output if self.exist?
			end

			def self.error output
				@@logger.error output if self.exist?
			end

			def self.exist?
				Dir.exist? "#{Dir.pwd}/mutx/logs"
			end

		end
	end
end