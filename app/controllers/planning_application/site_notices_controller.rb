# frozen_string_literal: true

class PlanningApplication
  class SiteNoticesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_site_notice, except: %i[new create]

    def show
      respond_to do |format|
        format.html
      end
    end

    def new
      @site_notice = SiteNotice.new
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def create
      @site_notice = SiteNotice.new(site_notice_params
                                    .except(:method, :internal_team_email)
                                    .merge(planning_application_id: @planning_application.id))

      if @site_notice.save
        @site_notice.update(content: @site_notice.preview_content)
        if params[:commit] == "Create PDF and mark as complete"
          respond_to do |format|
            format.html do
              redirect_to site_notice_api_v1_planning_application_path(@planning_application, format: "pdf")
            end
          end
        else
          if params[:commit] == "Email site notice and mark as complete"
            email = (site_notice_params[:internal_team_email].presence || @planning_application.applicant_email)
            @planning_application.send_site_notice_copy_mail(email)
          end

          respond_to do |format|
            format.html do
              redirect_to planning_application_consultations_path(@planning_application), notice: t(".success")
            end
          end
        end

        create_audit_log(params[:commit])
      else
        render :new
      end
    end

    def update
      if @site_notice.update(site_notice_params.except(:file))
        if site_notice_params[:file]
          @planning_application.documents.create!(file: site_notice_params[:file], site_notice: @site_notice)
        end

        calculate_consultation_end_date

        respond_to do |format|
          format.html do
            redirect_to planning_application_consultations_path(@planning_application), notice: t(".success")
          end
        end
      else
        render :edit
      end
    end

    private

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def set_site_notice
      @site_notice = @planning_application.site_notices.find(params[:id])
    end

    def site_notice_params
      params.require(:site_notice).permit(:required, :displayed_at, :method, :file, :internal_team_email)
    end

    def calculate_consultation_end_date
      new_end_date = @site_notice.displayed_at + 21.days

      @planning_application.consultation.update(end_date: new_end_date)
    end

    def create_audit_log(action)
      action = if action.include?("PDF")
                 "Site notice PDF was created"
               elsif site_notice_params[:internal_team_email].present?
                 "Site notice was emailed to internal team to print"
               else
                 "Site notice was emailed to the applicant"
               end

      Audit.create!(
        planning_application_id:,
        user: Current.user,
        activity_type: "site_notice_created",
        audit_comment: action.to_s
      )
    end
  end
end