# frozen_string_literal: true

module PlanningApplications
  class SiteNoticesController < AuthenticationController
    include PublicityPermittable

    before_action :set_planning_application
    before_action :ensure_publicity_is_permitted
    before_action :build_site_notice, only: %i[new create]
    before_action :set_site_notice, except: %i[new create]
    before_action :ensure_public_portal_is_active, only: :create
    before_action :ensure_application_is_assigned, only: :create
    before_action :redirect_to_reference_url, only: %i[new show edit]

    def show
      respond_to do |format|
        format.html
      end
    end

    def new
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def create
      @site_notice.assign_attributes(site_notice_params.except(:method))
      @site_notice.assign_attributes(content: @site_notice.preview_content)

      if @site_notice.save
        send_mail if params[:commit] == "Email site notice and mark as complete"

        respond_to do |format|
          action = (params[:commit] == "Email site notice and mark as complete") ? "emailed" : "created"
          format.html do
            if @site_notice.displayed_at.present?
              redirect_to new_planning_application_site_notice_path(@planning_application),
                notice: t(".success", action:)
            else
              redirect_to planning_application_consultation_path(@planning_application), notice: t(".success", action:)
            end
          end
        end

        create_audit_log
      else
        render :new
      end
    end

    def update
      if @site_notice.update(site_notice_params, :confirmation)
        @site_notice.document.update!(publishable: true)
        respond_to do |format|
          format.html do
            redirect_to planning_application_consultation_path(@planning_application), notice: t(".success")
          end
        end
      else
        render :edit
      end
    end

    private

    def build_site_notice
      @site_notice = @planning_application.site_notices.new
    end

    def set_site_notice
      @site_notice = @planning_application.site_notices.find(params[:id])
      @site_notice.displayed_at ||= Time.zone.today
    end

    def site_notice_params
      params.require(:site_notice).permit(:required, :displayed_at, :method, :internal_team_email, documents: [])
    end

    def send_mail
      if site_notice_params[:internal_team_email].presence
        @planning_application.send_internal_team_site_notice_mail(site_notice_params[:internal_team_email])
      else
        @planning_application.send_site_notice_mail(
          @planning_application.agent_email.presence || @planning_application.applicant_email
        )
      end
    end

    def ensure_public_portal_is_active
      return if @planning_application.make_public?
      return if site_notice_not_required?

      flash.now[:alert] = t(".make_public_html", href: make_public_planning_application_path(@planning_application))
      render :new and return
    end

    def ensure_application_is_assigned
      return if @planning_application.user.present?

      flash.now[:alert] = t(".assign_user_html", href: planning_application_assign_users_path(@planning_application))
      render :new and return
    end

    def create_audit_log
      comment = if site_notice_params[:internal_team_email].present?
        "Site notice was emailed to internal team to print"
      elsif params[:commit] == "Email site notice and mark as complete"
        "Site notice was emailed to the applicant"
      else
        "Site notice PDF was created"
      end

      Audit.create!(
        planning_application_id: @planning_application.id,
        user: Current.user,
        activity_type: "site_notice_created",
        audit_comment: comment
      )
    end

    def site_notice_not_required?
      site_notice_params[:required] == "No"
    end
  end
end
