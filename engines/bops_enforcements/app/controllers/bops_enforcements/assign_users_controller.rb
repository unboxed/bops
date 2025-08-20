# frozen_string_literal: true

module BopsEnforcements
  class AssignUsersController < ApplicationController
    include BopsCore::CaseRecords::AssignUsersController

    before_action :set_enforcement

    private

    def set_enforcement
      @enforcement = @case_record.caseable
    end

    def redirect_path
      enforcement_path(@case_record)
    end
  end
end
