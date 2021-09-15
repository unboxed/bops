class PolicyAssessmentsController < PlanningApplicationsController
  before_action :set_planning_application
  before_action :set_policy_class, only: %i[show_class update_class]

  def part; end

  def new
    @part = params[:part]

    redirect_to part_new_policy_assessment_path(@planning_application), alert: "Please choose one of the policy parts" if @part.blank?
  end

  def create
    class_ids = policy_class_params[:policy_classes].reject(&:blank?)

    classes = PlanningApplication
                .classes_for_part(params[:part])
                .select { |c| class_ids.include? c[:id] }

    @planning_application.policy_classes = classes

    if @planning_application.save
      redirect_to @planning_application, notice: "classes successfully added"
    else
      render :new
    end
  end

  def show_class; end

  def update_class
    new_policies = policies_params[:policies]

    @klass["policies"].each do |policy|
      value = new_policies[policy.keys.first]

      policy["status"] = value if value.present?
    end

    if @planning_application.save
      redirect_to @planning_application, notice: "Successfully updated policy classes"
    end
  end

  private

  def policy_class_params
    params.permit(:part, policy_classes: [])
  end

  def policies_params
    params.permit(:part, :policy_class, policies: {})
  end

  def set_policy_class
    @klass = @planning_application.find_policy_class(policies_params[:part], policies_params[:policy_class])
  end
end
