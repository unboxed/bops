# frozen_string_literal: true

module BopsEnforcements
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper

    def activity(type_of_activity, args = nil)
      scope = %i[audits types]

      scope << :no_user if type_of_activity == "assigned" && args.blank?

      t(type_of_activity, raise: true, scope:, args:)
    rescue I18n::MissingTranslationData
      raise ArgumentError, "Activity type: #{type_of_activity} is not valid"
    end

    def get_relevant_audit_information(audit)
      audit.audit_comment.nil? ? audit.activity_information : audit.audit_comment
    end

    def valid_json?(comment)
      JSON.parse(comment)
      true
    rescue JSON::ParserError, TypeError
      false
    end

    def task_enabled?(task)
      enforcement = task.top_level_ancestor.parent

      slug = case task.section
      when "Check"
        nil
      when "Investigate"
        "check-breach-report/start-investigation"
      when "Review"
        "investigate-and-decide/summarise-and-decide/summarise-investigation-and-make-recommendation"
      else
        "review-recommendation/review-recommendation"
      end

      return true if slug.nil?

      depends_on = enforcement.find_task_by_slug_path!(slug)

      depends_on.completed?
    end
  end
end
