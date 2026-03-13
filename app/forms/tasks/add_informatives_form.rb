# frozen_string_literal: true

module Tasks
  class AddInformativesForm < Form
    self.task_actions = %w[save_and_complete save_draft add_informative update_informative]

    attribute :title, :string
    attribute :text, :string

    after_initialize do
      @informative_set = planning_application.informative_set
      @informatives = @informative_set.informatives.select(&:persisted?)
    end

    with_options on: %i[add_informative update_informative] do
      validates :title, presence: {message: "Enter informative"}
      validates :text, presence: {message: "Enter details for this informative"}
    end

    attr_reader :informative_set, :informatives

    def informative
      @informative ||= if params[:id].present?
        informative_set.informatives.find(params[:id])
      else
        informative_set.informatives.build
      end
    end

    def informative_url
      route_for(:task_component, planning_application, slug: task.full_slug, id: informative.id, only_path: true)
    end

    def edit_informative_url(informative)
      route_for(:edit_task_component, planning_application, slug: task.full_slug, id: informative.id, only_path: true)
    end

    def remove_informative_url(informative)
      route_for(:planning_application_assessment_informatives_item, planning_application, informative, redirect_to: url, only_path: true)
    end

    private

    def add_informative
      informative_set.informatives.create!(title:, text:)
      task.start!
    end

    def update_informative
      informative.update!(title:, text:)
      task.start!
    end
  end
end
