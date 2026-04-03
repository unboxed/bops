# frozen_string_literal: true

module Tasks
  class SendSiteNoticeForm < Form
    self.task_actions = %w[save_and_complete create_site_notice email_site_notice]

    attribute :required, :boolean
    attribute :quantity, :integer, default: 1
    attribute :location_instructions, :string
    attribute :internal_team_email, :string
    attribute :displayed_at, :date
    attribute :delivery_method, :string

    after_initialize do
      @site_notices = planning_application.site_notices.to_a
      @site_notice = planning_application.site_notices.new
    end

    with_options on: %i[create_site_notice email_site_notice] do
      validates :required, inclusion: {in: [true, false], message: "Select whether a site notice is required"}
      validates :quantity, presence: {message: "Select number of site notices"}
      with_options format: {with: URI::MailTo::EMAIL_REGEXP} do
        validates :internal_team_email, allow_blank: true
      end
      validate :public_portal_must_be_active
      validate :application_must_be_assigned
    end

    attr_reader :site_notice, :site_notices

    def site_notice_audits
      planning_application.audits.where(activity_type: "site_notice_created").order(:created_at)
    end

    def edit_site_notice_url(site_notice)
      route_for(:edit_task_component, planning_application, slug: task.full_slug, id: site_notice.id, only_path: true)
    end

    private

    def create_site_notice
      build_site_notice
      create_audit_log
      task.in_progress! if task.not_started!
    end

    def email_site_notice
      build_site_notice
      if internal_team_email.present?
        planning_application.send_internal_team_site_notice_mail(internal_team_email)
      else
        planning_application.send_site_notice_mail(
          planning_application.agent_email.presence || planning_application.applicant_email
        )
      end
      create_audit_log
      task.in_progress! if task.not_started!
    end

    def save_and_complete
      super do
        if required == false
          create_audit_log
        end
      end
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

    def build_site_notice
      site_notice.assign_attributes(
        required: required,
        quantity: quantity,
        location_instructions: location_instructions,
        internal_team_email: internal_team_email,
        displayed_at: displayed_at
      )
      site_notice.content = site_notice.preview_content
      site_notice.save!
    end

    def create_audit_log
      comment = if internal_team_email.present?
        "Site notice was emailed to internal team to print"
      elsif delivery_method == "applicant"
        "Site notice was emailed to the applicant"
      elsif required == false
        "Site notice was marked as not required"
      else
        "Site notice PDF was created"
      end

      Audit.create!(
        planning_application_id: planning_application.id,
        user: Current.user,
        activity_type: (required == false) ? "site_notice_not_required" : "site_notice_created",
        audit_comment: comment
      )
    end
  end
end
