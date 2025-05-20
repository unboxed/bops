# frozen_string_literal: true

module BopsApplicants
  class PagesController < ApplicationController
    def index
      respond_to do |format|
        format.html
      end
    end

    def accessibility
      respond_to do |format|
        format.html
      end
    end
  end
end
