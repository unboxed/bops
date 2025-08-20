# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class << self
      def form_for(slug)
        form_name = "#{slug.underscore}_form".camelcase
        begin
          "BopsEnforcements::Tasks::#{form_name}".constantize
        rescue
          BaseForm
        end
      end
    end
  end
end
