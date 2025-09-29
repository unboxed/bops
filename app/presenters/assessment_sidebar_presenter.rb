# frozen_string_literal: true

class AssessmentSidebarPresenter
  Section = Struct.new(:id, :title, :items, keyword_init: true)
  Item = Struct.new(:id, :label, :path, :available, :hint, :state, keyword_init: true)

  OPTIONAL_ASSESSMENT_DETAIL_CATEGORIES = %w[site_description summary_of_work].freeze

  delegate :t, :consistency_checklist_path, :new_planning_application_assessment_assessment_detail_path,
    :edit_planning_application_assessment_assessment_detail_path,
    :planning_application_assessment_assessment_detail_path,
    :planning_application_assessment_consultees_path,
    :planning_application_assessment_site_histories_path,
    :planning_application_assessment_ownership_certificate_path,
    :edit_planning_application_assessment_ownership_certificate_path,
    :planning_application_assessment_permitted_development_rights_path,
    :edit_planning_application_assessment_permitted_development_rights_path,
    :planning_application_assessment_site_visits_path,
    :new_planning_application_assessment_site_visit_path,
    :planning_application_assessment_meetings_path,
    :planning_application_assessment_considerations_path,
    :new_planning_application_assessment_immunity_detail_path,
    :edit_planning_application_assessment_immunity_detail_path,
    :planning_application_assessment_immunity_detail_path,
    :new_planning_application_assessment_assess_immunity_detail_permitted_development_right_path,
    :edit_planning_application_assessment_assess_immunity_detail_permitted_development_right_path,
    :planning_application_assessment_assess_immunity_detail_permitted_development_right_path,
    :edit_planning_application_assessment_development_type_path,
    :edit_planning_application_assessment_policy_areas_policy_class_path,
    :planning_application_assessment_policy_areas_parts_path,
    :planning_application_review_documents_path,
    :new_planning_application_assessment_recommendation_path,
    :planning_application_assessment_recommended_application_type_path,
    :edit_planning_application_assessment_recommended_application_type_path,
    :planning_application_assessment_pre_commencement_conditions_path,
    :planning_application_assessment_conditions_path,
    :planning_application_assessment_informatives_path,
    :planning_application_assessment_requirements_path,
    :planning_application_assessment_terms_path,
    :bops_reports,
    :submit_recommendation_planning_application_path,
    to: :view

  def initialize(view_context, planning_application)
    @view = view_context
    @planning_application = planning_application
  end

  def sections
    [
      check_application_section,
      additional_services_section,
      assessment_information_section,
      assess_immunity_section,
      assess_against_policies_section,
      assess_against_legislation_section,
      complete_assessment_section
    ].compact
  end

  private

  attr_reader :view, :planning_application

  def check_application_section
    items = []

    items << Item.new(
      id: "consistency-check",
      label: t("planning_applications.assessment.tasks.check_consistency.description_documents_and"),
      path: consistency_checklist_path(planning_application.consistency_checklist),
      available: true
    )

    if planning_application.check_publicity? && !planning_application.pre_application?
      items << assessment_detail_item(:check_publicity)
    end

    if planning_application.ownership_details?
      items << ownership_certificate_item
    end

    if planning_application.consultation?
      items << Item.new(
        id: "check-consultees",
        label: t("task_list_items.assessment.consultees_consulted_component.consultees_consulted"),
        path: planning_application_assessment_consultees_path(planning_application),
        available: true
      )
    end

    items << Item.new(
      id: "check-site-history",
      label: "Check site history",
      path: planning_application_assessment_site_histories_path(planning_application),
      available: true
    )

    if planning_application.check_permitted_development_rights? && !planning_application.possibly_immune?
      items << permitted_development_right_item
    end

    Section.new(id: "check-application", title: t("planning_applications.assessment.tasks.check_consistency.check_application"), items: items)
  end

  def additional_services_section
    return unless planning_application.pre_application?

    items = []

    if planning_application.site_visits?
      path = if planning_application.site_visits.any?
        planning_application_assessment_site_visits_path(planning_application)
      else
        new_planning_application_assessment_site_visit_path(planning_application)
      end

      items << Item.new(
        id: "site-visit",
        label: t("task_list_items.assessment.site_visit_component.site_visit"),
        path: path,
        available: true
      )
    end

    if planning_application.additional_services.find_by(name: "meeting")
      items << Item.new(
        id: "meeting",
        label: t("task_list_items.assessment.meeting_component.meeting", default: "Meeting"),
        path: planning_application_assessment_meetings_path(planning_application),
        available: true
      )
    end

    return if items.empty?

    Section.new(id: "additional-services", title: "Additional services", items: items)
  end

  def assessment_information_section
    categories = planning_application.application_type.assessor_remarks
    return if categories.blank?

    items = categories.map { |category| assessment_detail_item(category) }

    Section.new(id: "assessment-information", title: "Assessment summaries", items: items.compact)
  end

  def assess_immunity_section
    return unless planning_application.possibly_immune?

    items = []

    items << immunity_details_item

    if planning_application.check_permitted_development_rights?
      items << immunity_permitted_development_right_item
    end

    Section.new(id: "assess-immunity", title: "Assess immunity", items: items.compact)
  end

  def assess_against_policies_section
    return unless planning_application.considerations? && !planning_application.pre_application?

    items = [
      Item.new(
        id: "assess-policies",
        label: t("task_list_items.assessment.considerations_component.link_text"),
        path: planning_application_assessment_considerations_path(planning_application),
        available: true
      )
    ]

    Section.new(id: "assess-policies", title: "Assess against policies and guidance", items: items)
  end

  def assess_against_legislation_section
    return unless planning_application.assess_against_policies? && !planning_application.pre_application?

    items = []

    items << Item.new(
      id: "development-type",
      label: "Check if the proposal is development",
      path: edit_planning_application_assessment_development_type_path(planning_application),
      available: true
    )

    if planning_application.no_policy_classes_after_assessment?
      # no tasks to add, but keep message for consistency as disabled row
      items << Item.new(
        id: "policy-classes",
        label: "No policy classes were added",
        path: nil,
        available: false
      )
    else
      planning_application.planning_application_policy_classes.order(:policy_class_id).each do |pa_policy_class|
        items << Item.new(
          id: "policy-class-#{pa_policy_class.id}",
          label: policy_class_label(pa_policy_class),
          path: edit_planning_application_assessment_policy_areas_policy_class_path(planning_application, pa_policy_class),
          available: true
        )
      end
    end

    items << add_new_assessment_area_item

    Section.new(id: "assess-legislation", title: "Assess against legislation", items: items.compact)
  end

  def complete_assessment_section
    items = []

    unless planning_application.pre_application?
      items << Item.new(
        id: "review-documents",
        label: t("task_list_items.reviewing.documents_component.review_documents_for"),
        path: planning_application_review_documents_path(planning_application),
        available: true
      )

      items << Item.new(
        id: "draft-recommendation",
        label: "Make draft recommendation",
        path: planning_application.can_assess? ? new_planning_application_assessment_recommendation_path(planning_application) : nil,
        available: planning_application.can_assess?,
        hint: planning_application.can_assess? ? nil : "Available once assessment tasks are ready"
      )
    end

    if planning_application.pre_application?
      items << recommended_application_type_item
    end

    if planning_application.planning_conditions?
      items << conditions_item(planning_application.condition_set)
      items << conditions_item(planning_application.pre_commencement_condition_set)
    end

    if planning_application.informatives?
      items << Item.new(
        id: "informatives",
        label: "Add informatives",
        path: planning_application_assessment_informatives_path(planning_application),
        available: true
      )
    end

    if planning_application.pre_application?
      items << requirements_item
    end

    if planning_application.heads_of_terms?
      items << Item.new(
        id: "heads-of-terms",
        label: "Add heads of terms",
        path: planning_application_assessment_terms_path(planning_application),
        available: true
      )
    end

    items << submission_item

    Section.new(id: "complete-assessment", title: "Complete assessment", items: items.compact)
  end

  # individual item builders -------------------------------------------------

  def assessment_detail_item(category)
    category = category.to_s
    assessment_detail = planning_application.send(category)
    status = assessment_detail_status(category, assessment_detail)

    path = case status
    when :not_started, :optional, :to_be_reviewed
      new_planning_application_assessment_assessment_detail_path(
        planning_application,
        category:
      )
    when :in_progress
      edit_planning_application_assessment_assessment_detail_path(
        planning_application,
        assessment_detail,
        category:
      )
    else
      planning_application_assessment_assessment_detail_path(
        planning_application,
        assessment_detail,
        category:
      )
    end

    Item.new(
      id: "assessment-detail-#{category.dasherize}",
      label: t("task_list_items.assessment.assessment_detail_component.#{category}"),
      path: path,
      available: true,
      state: status
    )
  end

  def assessment_detail_status(category, assessment_detail)
    return :not_started if assessment_detail.blank?

    if planning_application.recommendation&.rejected? && assessment_detail.update_required?
      :to_be_reviewed
    elsif begin
      assessment_detail.assessment_not_started?
    rescue
      false
    end
      OPTIONAL_ASSESSMENT_DETAIL_CATEGORIES.include?(category.to_s) ? :optional : :not_started
    elsif assessment_detail.assessment_in_progress?
      :in_progress
    else
      :complete
    end
  rescue NoMethodError
    OPTIONAL_ASSESSMENT_DETAIL_CATEGORIES.include?(category.to_s) ? :optional : :not_started
  end

  def ownership_certificate_item
    certificate = planning_application.ownership_certificate
    path = if certificate.present? && certificate.current_review&.status == "complete"
      planning_application_assessment_ownership_certificate_path(planning_application)
    else
      edit_planning_application_assessment_ownership_certificate_path(planning_application)
    end

    state = if certificate.blank?
      :not_started
    elsif certificate.current_review&.status == "complete"
      :complete
    else
      :in_progress
    end

    Item.new(
      id: "ownership-certificate",
      label: t("task_list_items.validating.ownership_certificate_component.link_text", default: "Check ownership certificate"),
      path: path,
      available: true,
      state: state
    )
  end

  def permitted_development_right_item
    pdr = planning_application.permitted_development_right

    path = if pdr&.complete? || pdr&.updated?
      planning_application_assessment_permitted_development_rights_path(planning_application)
    else
      edit_planning_application_assessment_permitted_development_rights_path(planning_application)
    end

    state = if pdr.blank?
      :not_started
    elsif pdr.complete?
      :complete
    elsif pdr.updated?
      :to_be_reviewed
    else
      :in_progress
    end

    Item.new(
      id: "permitted-development-rights",
      label: t("task_list_items.assessment.permitted_development_right_component.permitted_development_rights"),
      path: path,
      available: true,
      state: state
    )
  end

  def immunity_details_item
    immunity_detail = planning_application.immunity_detail
    status = if (review = immunity_detail&.current_evidence_review)
      review.status.to_sym
    else
      :not_started
    end

    path = case status
    when :not_started
      new_planning_application_assessment_immunity_detail_path(planning_application)
    when :in_progress, :to_be_reviewed
      edit_planning_application_assessment_immunity_detail_path(planning_application, immunity_detail)
    else
      planning_application_assessment_immunity_detail_path(planning_application, immunity_detail)
    end

    Item.new(
      id: "immunity-details",
      label: t("task_list_items.assessment.immunity_details_component.evidence_of_immunity"),
      path: path,
      available: true,
      state: status
    )
  end

  def immunity_permitted_development_right_item
    immunity_detail = planning_application.immunity_detail
    status = if (review = immunity_detail&.current_enforcement_review)
      review.status.to_sym
    else
      :not_started
    end

    path = case status
    when :not_started, :to_be_reviewed
      new_planning_application_assessment_assess_immunity_detail_permitted_development_right_path(planning_application)
    when :in_progress
      edit_planning_application_assessment_assess_immunity_detail_permitted_development_right_path(planning_application)
    else
      planning_application_assessment_assess_immunity_detail_permitted_development_right_path(planning_application)
    end

    Item.new(
      id: "immunity-pdr",
      label: t("task_list_items.assessment.assess_immunity_detail_permitted_development_right_component.immune_permitted_development_rights"),
      path: path,
      available: true,
      state: status
    )
  end

  def policy_class_label(planning_application_policy_class)
    policy_class = planning_application_policy_class.policy_class
    part = policy_class.policy_part
    "Part #{part.number}, Class #{policy_class.section}"
  end

  def add_new_assessment_area_item
    if planning_application.section_55_development?
      Item.new(
        id: "add-assessment-area",
        label: "Add new assessment area",
        path: planning_application_assessment_policy_areas_parts_path(planning_application),
        available: true
      )
    else
      Item.new(
        id: "add-assessment-area",
        label: "Add new assessment area",
        path: nil,
        available: false,
        hint: planning_application.section_55_development.nil? ? "Cannot start yet" : "Not required"
      )
    end
  end

  def recommended_application_type_item
    has_recommendation = planning_application.recommended_application_type.present?
    path = if has_recommendation
      planning_application_assessment_recommended_application_type_path(planning_application)
    else
      edit_planning_application_assessment_recommended_application_type_path(planning_application)
    end

    Item.new(
      id: "recommended-application-type",
      label: "Choose application type",
      path: path,
      available: true
    )
  end

  def conditions_item(condition_set)
    return if condition_set.blank?

    label = condition_set.pre_commencement? ? "Add pre-commencement conditions" : "Add conditions"
    path = if condition_set.pre_commencement?
      planning_application_assessment_pre_commencement_conditions_path(planning_application.reference)
    else
      planning_application_assessment_conditions_path(planning_application.reference)
    end

    Item.new(
      id: condition_set.pre_commencement? ? "pre-commencement-conditions" : "conditions",
      label: label,
      path: path,
      available: true
    )
  end

  def requirements_item
    can_access = planning_application.recommended_application_type.present?
    Item.new(
      id: "requirements",
      label: "Check and add requirements",
      path: can_access ? planning_application_assessment_requirements_path(planning_application) : nil,
      available: can_access,
      hint: can_access ? nil : "Choose an application type first"
    )
  end

  def submission_item
    if planning_application.pre_application?
      can_access = planning_application.recommended_application_type.present? && planning_application.assessment_details.present?
      Item.new(
        id: "submit-pre-application",
        label: "Review and submit pre-application",
        path: can_access ? bops_reports.planning_application_path(planning_application) : nil,
        available: can_access,
        hint: can_access ? nil : "Complete the assessment summaries first"
      )
    else
      can_access = planning_application.can_submit_recommendation?
      Item.new(
        id: "submit-recommendation",
        label: "Review and submit recommendation",
        path: can_access ? submit_recommendation_planning_application_path(planning_application) : nil,
        available: can_access,
        hint: can_access ? nil : "Complete the previous tasks first"
      )
    end
  end
end
