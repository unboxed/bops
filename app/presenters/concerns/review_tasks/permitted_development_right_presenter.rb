# frozen_string_literal: true

module ReviewTasks
  extend ActiveSupport::Concern

  class PermittedDevelopmentRightPresenter
    include Presentable

    def initialize(template, planning_application)
      @planning_application = planning_application
      @template = template
      @permitted_development_right = planning_application.permitted_development_right
      @status = @permitted_development_right.review_status
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat permitted_development_right_link
      end

      html.concat permitted_development_rights_status_tag
    end

    private

    attr_reader :status, :permitted_development_right

    def permitted_development_right_link
      link_to("Permitted development rights", permitted_development_right_link_url, class: "govuk-link")
    end

    def permitted_development_right_link_url
      case status.humanize

      when "Review not started"
        edit_planning_application_review_permitted_development_right_path(planning_application,
                                                                          permitted_development_right)
      when "Review in progress", "Review complete"
        planning_application_review_permitted_development_right_path(planning_application, permitted_development_right)
      else
        raise ArgumentError, "The status provided: '#{status}' is not valid"
      end
    end

    def permitted_development_rights_status_tag
      classes = ["#{govuk_tag_class} app-task-list__task-tag"]

      tag.strong class: classes do
        I18n.t("permitted_development_rights.#{status}")
      end
    end

    def govuk_tag_class
      return "govuk-tag" unless permitted_development_right_status_colour

      "govuk-tag govuk-tag--#{permitted_development_right_status_colour}"
    end

    def permitted_development_right_status_colour
      case status.humanize

      when "Review not started"
        "grey"
      when "Review complete"
        "blue"
      when "Review in progress"
        nil
      else
        raise ArgumentError, "The status provided: '#{status}' is not valid"
      end
    end
  end
end
