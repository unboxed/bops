# frozen_string_literal: true

module PreappTaskHelpers
  extend ActiveSupport::Concern

  class TaskDefinitions
    WORKFLOW_FILE = Rails.root.join("config/task_workflows/pre_application.yml")

    Task = Struct.new(:name, :slug_path, :section, :hidden, keyword_init: true) do
      def visible?
        !hidden
      end
    end

    class << self
      def all_tasks
        @all_tasks ||= flatten_workflow
      end

      def find_by_name(name)
        all_tasks.find { |t| t.name == name }
      end

      def visible_tasks_for_section(section_name)
        all_tasks.select { |t| t.section == section_name && t.visible? }
      end

      private

      def workflow
        @workflow ||= YAML.load_file(WORKFLOW_FILE)
      end

      def flatten_workflow
        workflow.flat_map do |section|
          collect_tasks(section["tasks"], section["name"].parameterize, section["section"])
        end
      end

      def collect_tasks(nodes, parent_slug, section_name)
        return [] unless nodes

        nodes.flat_map do |node|
          slug = node["name"].parameterize
          full_slug = [parent_slug, slug].compact.join("/")

          if node["tasks"]
            collect_tasks(node["tasks"], full_slug, section_name)
          else
            Task.new(
              name: node["name"],
              slug_path: full_slug,
              section: section_name,
              hidden: node["hidden"] || node["status_hidden"]
            )
          end
        end
      end
    end
  end

  # Usage: task("Site description"), task("Add and assign consultees"), etc.
  def task(name)
    task_cache[name]
  end

  def task_cache
    @task_cache ||= Hash.new(&method(:find_task))
  end

  def find_task(tasks, name)
    if (definition = TaskDefinitions.find_by_name(name))
      tasks[name] = planning_application.case_record.find_task_by_slug_path!(definition.slug_path)
    else
      raise "Unknown task: #{name}. Available: #{available_tasks}"
    end
  end

  def available_tasks
    TaskDefinitions.all_tasks.map(&:name).join(", ")
  end

  def assessment_tasks
    TaskDefinitions.visible_tasks_for_section("Assessment").map { |t| task(t.name) }
  end

  def validation_tasks
    TaskDefinitions.visible_tasks_for_section("Validation").map { |t| task(t.name) }
  end

  def consultees_section
    @consultees_section ||= planning_application.case_record.find_task_by_slug_path!("consultees")
  end
end

RSpec.configure do |config|
  config.include PreappTaskHelpers, type: :system
end
