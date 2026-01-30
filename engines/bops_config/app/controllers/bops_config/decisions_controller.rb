# frozen_string_literal: true

module BopsConfig
  class DecisionsController < ApplicationController
    self.page_key = "decisions"

    before_action :build_decision, only: %i[new create]
    before_action :set_decisions, only: %i[index]
    before_action :set_decision, only: %i[edit update]

    def index
      respond_to do |format|
        format.html
      end
    end

    def new
      respond_to do |format|
        format.html
      end
    end

    def create
      @decision.attributes = decision_params

      respond_to do |format|
        if @decision.save
          format.html { redirect_to decisions_path, notice: t(".success") }
        else
          format.html { render :new }
        end
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      @decision.attributes = decision_params

      respond_to do |format|
        if @decision.save
          format.html { redirect_to decisions_path, notice: t(".success") }
        else
          format.html { render :edit }
        end
      end
    end

    private

    def decision_attributes
      %i[code description category]
    end

    def decision_params
      params.require(:decision).permit(*decision_attributes)
    end

    def build_decision
      @decision = Decision.new
    end

    def set_decisions
      @decisions = Decision.all
    end

    def decision_id
      Integer(params[:id])
    rescue
      raise ActionController::BadRequest, "Invalid decision type id: #{params[:id].inspect}"
    end

    def set_decision
      @decision = Decision.find(decision_id)
    end
  end
end
