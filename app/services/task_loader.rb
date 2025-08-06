# frozen_string_literal: true

class TaskLoader
  WORKFLOW_DIR = Rails.root.join("config/task_workflows")

  class << self
    def workflows
      @workflows ||= {}
    end

    def load_workflow(key)
      return workflows[key] if workflows.key?(key)

      path = WORKFLOW_DIR.join("#{key}.yml")
      raise ArgumentError, "Tasks workflow file not found: #{key}" unless File.exist?(path)

      parsed = YAML.load_file(path)
      raise ArgumentError, "Workflow not found: #{key}" if parsed.blank?

      workflows[key] = parsed
    end

    def clear_cache!
      @workflows = {}
    end
  end

  attr_reader :case_record, :workflow_key

  def initialize(case_record, workflow_key)
    @case_record = case_record
    @workflow_key = workflow_key
  end

  def load!
    workflow = self.class.load_workflow(workflow_key)
    build_tasks_for(case_record, workflow)
  end

  private

  def build_tasks_for(parent, nodes)
    Array(nodes).each_with_index do |node, index|
      task = parent.tasks.build(
        name: node["name"],
        slug: node["slug"],
        optional: node.key?("optional") ? node["optional"] : false,
        section: node["section"],
        status: node["status"],
        position: index
      )

      build_tasks_for(task, node["tasks"]) if node["tasks"].present?
    end
  end
end
