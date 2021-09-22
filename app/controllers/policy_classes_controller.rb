class PolicyClassesController < PlanningApplicationsController
  before_action :set_planning_application
  before_action :set_policy_class_and_part, only: %i[show update]

  def part; end

  def new
    @part = params[:part]

    redirect_to part_new_policy_assessment_path(@planning_application), alert: "Please choose one of the policy parts" if @part.blank?
  end

  def create
    class_ids = policy_class_params[:policy_classes].reject(&:blank?)

    classes = PolicyClass
                .classes_for_part(params[:part])
                .select { |c| class_ids.include? c.id }
                .each(&:stamp_status!)

    @planning_application.policy_classes += classes

    if @planning_application.save
      redirect_to @planning_application, notice: "classes successfully added"
    else
      render :new
    end
  end

  def show; end

  def update
    new_policies = policies_params[:policies]

    @klass.policies.each do |policy|
      value = new_policies[policy["id"]]

      policy["status"] = value if value.present?
    end

    @planning_application.policy_classes_will_change!

    if @planning_application.save
      redirect_to @planning_application, notice: "Successfully updated policy class"
    end
  end

private

  def policy_class_params
    params.permit(:part, policy_classes: [])
  end

  def policies_params
    params.permit(:part, :policy_class, policies: {})
  end

  def set_policy_class_and_part
    part, id = params[:id].split("-")

    @klass = @planning_application.policy_classes.find { |c| c.part == part && c.id == id }
  end

  def set_planning_application
    @planning_application = current_local_authority.planning_applications.find(params[:planning_application_id])
  end
end
