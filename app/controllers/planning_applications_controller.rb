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
                                                    view_recommendation
                                                    edit_constraints_form
                                                    edit_constraints
                                                    cancel_confirmation
                                                    cancel
                                                    decision_notice]

  before_action :ensure_user_is_reviewer, only: %i[review review_form]
  before_action :ensure_constraint_edits_unlocked, only: %i[edit_constraints_form edit_constraints]

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
      receipt_notice_mail if @planning_application.applicant_email.present?
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
    @planning_application.documents_validated_at ||= if @planning_application.closed_validation_requests.present?
                                                       @planning_application.last_validation_request_date
                                                     else
                                                       @planning_application.created_at
                                                     end
  end

  def validate_documents
    status = params[:planning_application][:status]
    case status
    when "in_assessment"
      if documents_validated_at_missing?
        @planning_application.status = "in_assessment"
        render "validate_documents_form"
      elsif @planning_application.description_change_validation_requests.open.present?
        @planning_application.errors.add(:status, "Planning application cannot be validated if open validation requests exist.")
        render "validate_documents_form"
      else
        @planning_application.documents_validated_at = date_from_params
        @planning_application.start!
        audit("started")
        validation_notice_mail
        flash[:notice] = "Application is ready for assessment and applicant has been notified"
        redirect_to @planning_application
      end
    when "invalidated"
      @planning_application.invalidate!
      audit("invalidated")
      flash[:notice] = "Application has been invalidated"
      render "validate_documents_form"
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

  def view_recommendation
    @assessor_name = @planning_application.recommendations.last.assessor.name
    @recommended_date = @planning_application.recommendations.last.created_at.strftime("%d %b %Y")
  end

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

    case params[:recommendation][:agree]
    when "No"
      audit("challenged", @recommendation.reviewer_comment)
      @recommendation.assign_attributes(challenged: true)
      if @recommendation.save
        @planning_application.request_correction!
        redirect_to @planning_application
      else
        render :review_form
      end
    when "Yes"
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

  def edit_constraints_form; end

  def edit_constraints
    @planning_application.constraints = params[:planning_application][:constraints].reject(&:blank?)
    if @planning_application.save!
      if @planning_application.saved_changes?
        prev_arr = @planning_application.saved_changes[:constraints][0]
        new_arr = @planning_application.saved_changes[:constraints][1]

        attr_removed = prev_arr - new_arr
        attr_added = new_arr - prev_arr

        attr_added.each { |attr| audit("constraint_added", attr) }
        attr_removed.each { |attr| audit("constraint_removed", attr) }
      end
      flash[:notice] = "Constraints have been updated"
      redirect_to planning_application_url
    else
      render :edit_constraints_form
    end
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
                        constraints
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

  def receipt_notice_mail
    PlanningApplicationMailer.receipt_notice_mail(
      @planning_application,
      request.host,
    ).deliver_now
  end

  def ensure_user_is_reviewer
    render plain: "forbidden", status: :forbidden and return unless current_user.reviewer?
  end

  def ensure_constraint_edits_unlocked
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_validate?
  end

  def documents_validated_at_missing?
    if params["planning_application"]["documents_validated_at(3i)"].blank? ||
        params["planning_application"]["documents_validated_at(2i)"].blank? ||
        params["planning_application"]["documents_validated_at(1i)"].blank?
      @planning_application.errors.add(:status, "Please enter a valid date")
    end
  end
end
