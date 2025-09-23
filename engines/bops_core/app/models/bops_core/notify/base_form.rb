# frozen_string_literal: true

require "notifications/client"

module BopsCore
  module Notify
    class BaseForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attr_reader :local_authority, :params, :response
      delegate :param_key, to: :model_name

      def initialize(local_authority, params)
        @local_authority = local_authority
        @params = params
        @checked = false

        super(form_params)
      end

      def check
        return false unless valid?

        begin
          yield if block_given?

          @checked = true
        rescue Notifications::Client::RequestError => error
          errors.add :base, message: "Notify Error: #{error.message}"
        end

        @checked
      end

      def checked?
        @checked
      end

      def reference
        @reference ||= SecureRandom.base36
      end

      private

      def form_params
        params.fetch(param_key, {}).permit(permitted_params)
      end

      def permitted_params
        self.class.attribute_names
      end

      def api_key
        local_authority.notify_api_key
      end

      def client
        @client ||= Notifications::Client.new(api_key)
      end
    end
  end
end
