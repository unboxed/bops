# frozen_string_literal: true

module Presentable
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  delegate :to_param, to: :presented

  class_methods do
    def presents(presented)
      define_method(:presented) do
        @presented ||= send(presented)
      end
    end
  end

  private

  def method_missing(method_name, *args, &block)
    if presented.respond_to?(method_name)
      presented.send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, *args)
    presented.respond_to?(method_name) || super
  end
end
