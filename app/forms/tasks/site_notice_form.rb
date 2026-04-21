# frozen_string_literal: true

module Tasks
  class SiteNoticeForm < Form
    self.task_actions = %w[save_and_complete create_site_notice email_site_notice mark_not_required confirm_display]

    attribute :required, :boolean
    attribute :quantity, :integer, default: 1
    attribute :location_instructions, :string
    attribute :internal_team_email, :string
    attribute :displayed_at, :date
    attribute :delivery_method, :string
    attribute :documents, array: true

    after_initialize do
      @site_notices = planning_application.site_notices
      @site_notice = if params[:id].present?
        planning_application.site_notices.find(params[:id]).tap do |sn|
          self.displayed_at ||= sn.displayed_at
        end
      else
        planning_application.site_notices.new
      end
    end

    def new_site_notice_url
      route_for(:task, planning_application, slug: task.full_slug, new: true, only_path: true)
    end

    def back_url
      route_for(:task, planning_application, slug: task.full_slug, only_path: true)
    end

    def edit_site_notice_url(site_notice)
      route_for(:edit_task_component, planning_application, slug: task.full_slug, id: site_notice.id, only_path: true)
    end

    def confirm_display_url
      route_for(:task_component, planning_application, slug: task.full_slug, id: site_notice.id, only_path: true)
    end

    attr_reader :site_notice, :site_notices

    with_options on: :create_site_notice do
      validates :quantity, presence: {message: "Enter number of site notices"}
      validates :delivery_method, presence: {message: "Select method of delivery"}
      with_options format: {with: URI::MailTo::EMAIL_REGEXP} do
        validates :internal_team_email, allow_blank: true
      end
      validate :public_portal_must_be_active
      validate :application_must_be_assigned
    end

    with_options on: :confirm_display do
      validate :documents_present
      validates :displayed_at, presence: true
      validate :displayed_at_not_in_past
    end

    def documents_present
      errors.add(:documents, "Upload evidence of display") unless documents.compact_blank.any?
    end

    def displayed_at_not_in_past
      return if displayed_at.blank?
      errors.add(:displayed_at, "Display date must be on or after today") if displayed_at < Date.current
    end

    private

    def form_params(params)
      params.fetch(param_key, {}).permit(:displayed_at, :required, :quantity, :location_instructions, :internal_team_email, :delivery_method, documents: [])
    end

    def public_portal_must_be_active
      return if planning_application.make_public?
      return if required == false

      errors.add :base, :invalid, message: "The public portal must be made active before sending a site notice"
    end

    def application_must_be_assigned
      return if planning_application.user.present?

      errors.add :base, :invalid, message: "The application must be assigned to a case officer before sending a site notice"
    end

    def mark_not_required
      transaction do
        site_notice.update!(required: false)
        task.completed!
      end
    end

    def create_site_notice
      transaction do
        if delivery_method == "internal_team"
          build_site_notice
          planning_application.send_internal_team_site_notice_mail(internal_team_email)
          comment = "Site notice was emailed to internal team to print"
        elsif delivery_method == "applicant"
          build_site_notice
          planning_application.send_site_notice_mail(planning_application.agent_email.presence || planning_application.applicant_email)
          comment = "Site notice was emailed to the agent/ applicant"
        elsif delivery_method == "print"
          build_site_notice
          comment = "Site notice PDF was created"
        end
        create_audit(comment)
        task.in_progress!
      end
    end

    def create_audit(comment)
      site_notice.audit!(activity_type: "site_notice_created", audit_comment: comment)
    end

    def build_site_notice
      site_notice.assign_attributes(
        required: true,
        quantity: quantity,
        location_instructions: location_instructions,
        internal_team_email: internal_team_email,
        displayed_at: displayed_at
      )
      site_notice.content = site_notice.preview_content
      site_notice.save!
    end

    def confirm_display
      site_notice.update!(
        displayed_at: displayed_at,
        documents: documents
      )
    end
  end
end
