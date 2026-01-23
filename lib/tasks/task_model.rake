# frozen_string_literal: true

def complete_tasks(case_record: nil, section: nil, parent_task: nil, status: :completed)
  if case_record.present?
    parent_task ||= case_record.tasks.find_by(section:)
  end

  if parent_task.nil?
    warn "No #{section} found for #{case_record.id} / #{case_record.caseable.reference}"
    return
  end

  parent_task.tasks.each do |task|
    if task.section.present?
      complete_tasks(parent_task: task, status:)
    else
      task.update!(status:)
    end
  end
end

def complete_application(application)
  ApplicationRecord.transaction do
    application.case_record.send(:reload_tasks!)
    application.reload

    next if application.case_record.tasks.none? # probably an application type that hasn't had tasks defined yet

    if application.validation_complete?
      complete_tasks(case_record: application.case_record, section: "Validation")

      if application.consultation&.complete?
        complete_tasks(case_record: application.case_record, section: "Consultation")
      elsif application.consultation&.started?
        complete_tasks(case_record: application.case_record, section: "Consultation", status: :in_progress)
      end
    end

    if application.assessment_complete?
      complete_tasks(case_record: application.case_record, section: "Assessment")
    end
  end
end

namespace :task_model do
  task migrate: :environment do
    application_type = ENV["APPLICATION_TYPE"]&.to_sym

    scope = if application_type == :preapps
      PlanningApplication.pre_applications
    elsif application_type == :all
      PlanningApplication.all
    else
      raise ArgumentError, "APPLICATION_TYPE must be one of `preapps` or `all`"
    end

    # planning_applications with no tasks at all
    scope = scope.left_joins(case_record: :tasks).where(tasks: {id: nil})

    scope.find_each do |application|
      complete_application(application)
    end

    # case records with top-level tasks (sections) but no subtasks
    # i.e. cases created before the tasks were fully defined.
    scope = CaseRecord.left_joins(tasks: :tasks)
      .where(tasks: {parent_type: "CaseRecord"}, tasks_tasks: {id: nil})
      .where.not(tasks: {section: "Review"}) # excluding review, because we expect it to have no subtasks
      .distinct

    scope.find_each do |case_record|
      next if application_type == :preapps && case_record.caseable.application_type.name != "pre_application"
      complete_application(case_record.caseable)
    end
  end
end
