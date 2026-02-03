# frozen_string_literal: true

module BopsConfig
  module LocalAuthorities
    module Notify
      class BaseController < ApplicationController
        self.page_key = "local_authorities"

        before_action :set_local_authority
        before_action :build_form

        def new
          respond_to do |format|
            format.html
          end
        end

        private

        def set_local_authority
          @local_authority = LocalAuthority.find_by!(subdomain: params[:local_authority_name])
        end

        def build_form
          raise NotImplementedError, "Subclasses need to implement a `build_form' method"
        end
      end
    end
  end
end
