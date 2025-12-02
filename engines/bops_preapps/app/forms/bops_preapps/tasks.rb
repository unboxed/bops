# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class << self
      def form_for(slug)
        form_class_for(slug) || BaseForm
      end

      private

      def form_class_for(slug)
        form_name = "#{slug.underscore}_form".camelcase
        "BopsPreapps::Tasks::#{form_name}".constantize
      rescue NameError
        nil
      end
    end
  end
end
