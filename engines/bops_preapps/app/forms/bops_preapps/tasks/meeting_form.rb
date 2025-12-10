# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class MeetingForm < Form
      include DateValidateable

      class MeetingDecorator < SimpleDelegator
        def occurred_on
          occurred_at&.to_date&.to_fs
        end

        def created_by
          super&.name
        end
      end

      self.task_actions = %w[add_meeting save_draft save_and_complete]

      attribute :occurred_on, :date
      attribute :comments, :string

      with_options on: :add_meeting do
        validates :occurred_on, date: {format: true, message: "Enter a valid date for the meeting"}
        validates :occurred_on, date: {presence: true, message: "Enter the date of the meeting"}
        validates :occurred_on, date: {on_or_before: :current, message: "Enter a date on or before today’s date"}
      end

      def update(params)
        super do
          case action
          when "add_meeting"
            add_meeting
          when "save_draft"
            task.start!
          when "save_and_complete"
            task.complete!
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      def meetings
        @meetings ||= meetings_relation.load
      end

      def each_meeting
        meetings.each do |meeting|
          yield MeetingDecorator.new(meeting)
        end
      end

      def add_meeting_open?
        errors.any? || meetings.none?
      end

      private

      def meetings_relation
        planning_application.meetings.includes(:created_by).by_occurred_at_desc
      end

      def build_meeting
        planning_application.meetings.new do |m|
          m.occurred_at = occurred_on
          m.comment = comments
          m.created_by = Current.user
        end
      end

      def add_meeting
        transaction do
          build_meeting.save! && task.start!
        end
      end
    end
  end
end
