# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  before_action :set_planning_application, only: %i[show
                                                    assign
                                                    edit
                                                    recommendation_form
                                                    recommend
                                                    submit_recommendation
                                                    assess
                                                    review_form
                                                    review
                                                    publish
                                                    determine
                                                    request_correction
                                                    validate_documents_form
                                                    validate_documents
                                                    cancel_confirmation
                                                    cancel]

  before_action :ensure_user_is_reviewer, only: %i[review review_form]

  rescue_from Notifications::Client::NotFoundError,
              with: :decision_notice_mail_error

  def index
    @planning_applications = if helpers.exclude_others? && current_user.assessor?
                               current_local_authority.planning_applications.where(user_id: current_user.id).or(
                                 current_local_authority.planning_applications.where(user_id: nil),
                               )
                             else
                               current_local_authority.planning_applications.all
                             end
  end

  def show; end

  def assign
    if request.patch?
      @planning_application.user = if params[:planning_application][:user_id] == "0"
                                     nil
                                   else
                                     current_local_authority.users.find(params[:planning_application][:user_id])
                                   end
      redirect_to @planning_application if @planning_application.save
    end
  end

  def edit; end

  def start
    @planning_application.start!

    redirect_to @planning_application
  end

  def return
    @planning_application.return!

    redirect_to @planning_application
  end

  def invalidate
    @planning_application.invalidate!

    redirect_to @planning_application
  end

  def recommendation_form
    @recommendation = @planning_application.pending_or_new_recommendation
  end

  def recommend
    @recommendation = @planning_application.pending_or_new_recommendation
    @planning_application.assign_attributes(params.require(:planning_application).permit(:decision, :public_comment))
    @recommendation.assign_attributes(params.require(:recommendation).permit(:assessor_comment).merge(assessor: current_user))

    if @planning_application.save && @recommendation.save
      redirect_to @planning_application
    else
      render :recommendation_form
    end
  end

  def submit_recommendation; end

  def assess
    @planning_application.assess!

    redirect_to @planning_application
  end

  def review_form
    @recommendation = @planning_application.recommendations.last
  end

  def review
    @recommendation = @planning_application.recommendations.last
    @recommendation.update!(reviewer_comment: params[:recommendation][:reviewer_comment], reviewed_at: Time.zone.now, reviewer: current_user)
    if params[:recommendation][:agree] == "No"
      @planning_application.request_correction!
    end
    redirect_to @planning_application
  end

  def publish; end

  def determine
    @planning_application.determine!

    decision_notice_mail
    flash[:notice] = "Decision Notice sent to applicant"

    redirect_to @planning_application
  end

  def request_correction
    @planning_application.request_correction!

    redirect_to @planning_application
  end

  def withdraw
    @planning_application.withdraw!

    redirect_to @planning_application
  end

  def cancel_confirmation
    render :cancel_confirmation
  end

  def cancel
    case params[:planning_application][:status]
    when "withdrawn"
      @planning_application.withdraw!(:withdrawn, params[:planning_application][:cancellation_comment])
      flash[:notice] = "Application has been withdrawn"
      redirect_to @planning_application
    when "returned"
      @planning_application.return!(:returned, params[:planning_application][:cancellation_comment])
      flash[:notice] = "Application has been returned"
      redirect_to @planning_application
    else
      @planning_application.errors.add(:status, "Please select one of the below options")
      render :cancel_confirmation
    end
  end

  def validate_documents_form
    @planning_application.documents_validated_at ||= @planning_application.created_at
  end

  def validate_documents
    status = params[:planning_application][:status]
    if status == "in_assessment"
      if date_from_params.blank?
        @planning_application.errors.add(:planning_application, "Please enter a valid date")
        render "validate_documents_form"
      else
        @planning_application.documents_validated_at = date_from_params
        @planning_application.start!
        validation_notice_mail
        flash[:notice] = "Application is ready for assessment and applicant has been notified"
        redirect_to @planning_application
      end
    elsif status == "invalidated"
      @planning_application.invalidate!
      flash[:notice] = "Application has been invalidated"
      redirect_to @planning_application
    else
      @planning_application.errors.add(:status, "Please select one of the below options")
      render "validate_documents_form"
    end
  end

private

  def date_from_params
    Time.zone.parse(
      [
        params[:planning_application]["documents_validated_at(3i)"],
        params[:planning_application]["documents_validated_at(2i)"],
        params[:planning_application]["documents_validated_at(1i)"],
      ].join("-"),
    )
  end

  def set_planning_application
    @planning_application = current_local_authority.planning_applications.find(params[:id])
  end

  def decision_notice_mail
    PlanningApplicationMailer.decision_notice_mail(
      @planning_application,
      request.host,
    ).deliver_now
  end

  def validation_notice_mail
    PlanningApplicationMailer.validation_notice_mail(
      @planning_application,
      request.host,
    ).deliver_now
  end

  def decision_notice_mail_error
    flash[:notice] =
      "The email cannot be sent. Please try again later."
    render "documents/index"
  end

  def ensure_user_is_reviewer
    render plain: "forbidden", status: 403 and return unless current_user.reviewer?
  end
end
