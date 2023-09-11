# frozen_string_literal: true

class PlanningApplication
  class SiteNoticesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_site_notice, except: [:new, :create]

    def show
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def new
      @site_notice = SiteNotice.new()
    end

    def create
      @site_notice = SiteNotice.new(site_notice_params
                                    .except(:method)
                                    .merge(planning_application_id: @planning_application.id)
                                  )

      if @site_notice.save
        @site_notice.update(content: @site_notice.preview_content)
        if site_notice_params[:method] == ("applicant" || "internal_team")
          @planning_application.send_site_notice_copy_mail(email)

          respond_to do |format|
            format.html do
              redirect_to planning_application_path(@planning_application), notice: t(".success")
            end
          end
        else site_notice_params[:method] == "print"
          respond_to do |format|
            format.html do
              redirect_to planning_application_assessment_report_download_path(@planning_application, format: "pdf")
            end
          end
        end
      else
        render :new
      end
    end

    def update
      if @site_notice.update(site_notice_params.except(:file))
        @planning_application.documents.create!(file: site_notice_params[:file], site_notice: @site_notice)

        respond_to do |format|
          format.html do
            redirect_to planning_application_path(@planning_application), notice: "Success"
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
      params.require(:site_notice).permit(:required, :displayed_at, :method, :file)
    end
  end
end
