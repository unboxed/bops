# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class << self
      def form_for(slug)
        const_get("#{slug.underscore}_form".camelcase)
      rescue NameError
        nil
      end
    end
  end
end
