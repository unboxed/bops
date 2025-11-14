# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class MeetingForm < BaseForm
      def update(params)
        ActiveRecord::Base.transaction do
          task.update!(status: :completed)
        end
      rescue ActiveRecord::RecordInvalid
        false
      end

      def permitted_fields(params)
        {} # no params sent: just a submit button
      end
    end
  end
end
