# frozen_string_literal: true

module BopsCore
  module Tasksable
    def form_for(slug)
      const_get("#{slug.underscore}_form".camelcase)
    rescue NameError
      nil
    end

    def templates_prefix
      @templates_prefix ||= name.underscore
    end
  end
end
