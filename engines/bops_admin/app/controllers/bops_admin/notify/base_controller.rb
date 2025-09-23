# frozen_string_literal: true

module BopsAdmin
  module Notify
    class BaseController < ApplicationController
      before_action :build_form

      def new
        respond_to do |format|
          format.html
        end
      end

      private

      def build_form
        raise NotImplementedError, "Subclasses need to implement a `build_form' method"
      end
    end
  end
end
