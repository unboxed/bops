# frozen_string_literal: true

module BopsPreapps
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    helper BopsPreapps::FileTypesHelper
    helper PlanningApplicationHelper
    helper ValidationRequestHelper
    helper ConsulteesHelper

    before_action :require_local_authority!

    layout "application"
  end
end
