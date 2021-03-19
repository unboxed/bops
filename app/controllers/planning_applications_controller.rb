# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  before_action :set_planning_application, only: %i[show
                                                    edit
                                                    update
                                                    assign
                                                    recommendation_form
                                                    recommend
                                                    submit_recommendation
                                                    assess
                                                    review_form
                                                    review
                                                    publish
                                                    determine
                                                    validate_documents_form
                                                    validate_documents
                                                    cancel_confirmation
                                                    cancel
                                                    decision_notice]

  before_action :ensure_user_is_reviewer, only: %i[review review_form]

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

  def new
    @planning_application = PlanningApplication.new
  end

  def edit; end

  def create
    @planning_application = PlanningApplication.new(planning_application_params)
    @planning_application.assign_attributes(local_authority: current_local_authority)

    if @planning_application.save
      audit("created", nil, current_user.name)
      flash[:notice] = "Planning application was successfully created."
      redirect_to planning_application_documents_path(@planning_application)
    else
      render :new
    end
  end

  def update
    if @planning_application.update(planning_application_params)
      planning_application_params.keys.map do |p|
        if @planning_application.saved_change_to_attribute?(p)
          audit("updated", "Changed from: #{@planning_application.saved_changes[p][0]} \r\n Changed to: #{@planning_application.saved_changes[p][1]}", p.split("_").join(" ").capitalize)
        end
      end
      flash[:notice] = "Planning application was successfully updated."
      redirect_to planning_application_url
    else
      render :edit
    end
  end

  def assign
    if request.patch?
      @planning_application.user = if params[:planning_application][:user_id] == "0"
                                     nil
                                   else
                                     current_local_authority.users.find(params[:planning_application][:user_id])
                                   end
      audit("assigned", nil, @planning_application.user&.name)
      redirect_to @planning_application if @planning_application.save
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
        audit("started")
        validation_notice_mail
        flash[:notice] = "Application is ready for assessment and applicant has been notified"
        redirect_to @planning_application
      end
    elsif status == "invalidated"
      @planning_application.invalidate!
      audit("invalidated")
      flash[:notice] = "Application has been invalidated"
      redirect_to @planning_application
    else
      @planning_application.errors.add(:status, "Please select one of the below options")
      render "validate_documents_form"
    end
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
    audit("assessed", @planning_application.recommendations.last.assessor_comment)
    redirect_to @planning_application
  end

  def review_form
    @recommendation = @planning_application.recommendations.last
  end

  def review
    @recommendation = @planning_application.recommendations.last
    @recommendation.update!(reviewer_comment: params[:recommendation][:reviewer_comment], reviewed_at: Time.zone.now, reviewer: current_user)

    if params[:recommendation][:agree] == "No"
      audit("challenged", @recommendation.reviewer_comment)
      @recommendation.assign_attributes(challenged: true)
      if @recommendation.save
        @planning_application.request_correction!
        redirect_to @planning_application
      else
        render :review_form
      end
    elsif params[:recommendation][:agree] == "Yes"
      @recommendation.update!(challenged: false)
      audit("approved", @recommendation.reviewer_comment)
      redirect_to @planning_application
    end
  end

  def publish; end

  def determine
    @planning_application.determine!
    audit("determined", "Application #{@planning_application.decision}")
    decision_notice_mail
    flash[:notice] = "Decision Notice sent to applicant"

    redirect_to @planning_application
  end

  def cancel
    case params[:planning_application][:status]
    when "withdrawn"
      @planning_application.withdraw!(:withdrawn, params[:planning_application][:cancellation_comment])
      flash[:notice] = "Application has been withdrawn"
      audit("withdrawn", @planning_application.cancellation_comment)
      redirect_to @planning_application
    when "returned"
      @planning_application.return!(:returned, params[:planning_application][:cancellation_comment])
      flash[:notice] = "Application has been returned"
      audit("returned", @planning_application.cancellation_comment)
      redirect_to @planning_application
    else
      @planning_application.errors.add(:status, "Please select one of the below options")
      render :cancel_confirmation
    end
  end

  def cancel_confirmation
    render :cancel_confirmation
  end

  def decision_notice
    render :decision_notice
  end

private

  def planning_application_params
    permitted_keys = %i[address_1
                        address_2
                        application_type
                        applicant_first_name
                        applicant_last_name
                        applicant_phone
                        applicant_email
                        agent_first_name
                        agent_last_name
                        agent_phone
                        agent_email
                        county
                        created_at(3i)
                        created_at(2i)
                        created_at(1i)
                        description
                        proposal_details
                        payment_reference
                        postcode
                        town
                        uprn
                        work_status]
    params.require(:planning_application).permit permitted_keys
  end

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

  def ensure_user_is_reviewer
    render plain: "forbidden", status: 403 and return unless current_user.reviewer?
  end
end
