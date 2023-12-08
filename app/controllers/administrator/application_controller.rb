# frozen_string_literal: true

module Administrator
  class ApplicationController < ApplicationController
    include Administratable
  end
end
