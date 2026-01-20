# frozen_string_literal: true

module BopsPreapps
  class CancelRequestsController < AuthenticationController
    before_action :set_planning_application
    before_action :set_task
    before_action :build_form
    before_action :show_sidebar
    before_action :show_header

    def show
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        format.html do
          if @form.update(params)
            redirect_to @form.redirect_url, notice: @form.flash(:notice, self)
          else
            flash.now[:alert] = @form.flash(:alert, self)
            render :show, status: :unprocessable_content
          end
        end
      end
    end

    private

    def build_form
      @form = BopsPreapps::Tasks::CancelValidationRequestForm.new(@task)
      @form.validation_request_id = params[:validation_request_id]
    end
  end
end
