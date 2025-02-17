# frozen_string_literal: true

module BopsConfig
  module Gpdo
    class BaseController < ApplicationController
      private

      def set_policy_schedule
        @schedule = PolicySchedule.find_by_number(policy_schedule_number)
      end

      def set_policy_schedules
        @schedules = PolicySchedule.by_number
      end

      def policy_schedule_number
        Integer(policy_schedule_number_params)
      rescue
        raise ActionController::BadRequest, "Invalid policy schedule number: #{policy_schedule_number_params.inspect}"
      end

      def set_policy_parts
        @parts = @schedule.policy_parts
      end

      def set_policy_classes
        @policy_classes = @part.policy_classes
      end

      def policy_part_number
        Integer(policy_part_number_params)
      rescue
        raise ActionController::BadRequest, "Invalid policy part number: #{policy_schedule_number_params.inspect}"
      end

      def policy_class_section
        policy_class_section_params
      rescue
        raise ActionController::BadRequest, "Invalid policy class section: #{policy_class_section_params.inspect}"
      end
    end
  end
end
