# frozen_string_literal: true

module BopsEnforcements
  class AssignUsersController < ApplicationController
    include BopsCore::CaseRecords::AssignUsersController

    before_action :set_enforcement

    private

    def set_case_record
      @case_record = @current_local_authority.enforcements.find_by!(reference: params[:reference]).case_record
    end

    def set_enforcement
      @enforcement = @case_record.caseable
    end

    def redirect_path
      enforcement_path(@enforcement)
    end
  end
end
