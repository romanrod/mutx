# encoding: utf-8
require 'mutx'
require 'mail'
require 'erb'
require 'ostruct'
#require 'sidekiq/testing/inline'

module Mutx
  module Workers
    class EmailSender
      include Sidekiq::Worker
      def perform(result_id, subject, email, name, id, type, cucumber, notify_on)
        Mutx::Support::MailSender.new.sender(result_id, subject, email, name, id, type, cucumber, notify_on)
      end
    end
  end
end