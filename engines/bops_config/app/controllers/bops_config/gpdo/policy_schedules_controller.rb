# frozen_string_literal: true

module BopsConfig
  module Gpdo
    class PolicySchedulesController < ApplicationController
      before_action :build_policy_schedule, only: %i[new]
      before_action :set_policy_schedules, only: %i[index]
      before_action :set_policy_schedule, only: %i[edit update]

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

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @application_type.update(policy_schedule_params)
            format.html do
              redirect_to policy_schedules_path, notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def policy_schedule_params
        params.require(:policy_schedule).permit(:number, :name)
      end

      def set_policy_schedule
        @schedule = PolicySchedule.find(policy_schedule_id)
      end

      def set_policy_schedules
        @schedules = PolicySchedule.all
      end

      def policy_schedule_id
        Integer(params[:id])
      rescue
        raise ActionController::BadRequest, "Invalid policy schedule id: #{params[:id].inspect}"
      end
    end
  end
end
