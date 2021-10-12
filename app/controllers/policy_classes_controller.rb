class PolicyClassesController < PlanningApplicationsController
  before_action :set_planning_application
  before_action :set_policy_class, only: %i[show update destroy]

  def part; end

  def new
    @part = params[:part]

    redirect_to part_new_planning_application_policy_class_path(@planning_application), alert: "Please choose one of the policy parts" if @part.blank?
  end

  def create
    class_ids = policy_class_params[:policy_classes].reject(&:blank?)

    if class_ids.empty?
      redirect_to new_planning_application_policy_class_path(@planning_application, part: params[:part]), alert: "Please select at least one class"
      return
    end

    classes = PolicyClass
                .classes_for_part(params[:part])
                .select { |c| class_ids.include? c.id }
                .each(&:stamp_status!)

    @planning_application.policy_classes += classes

    if @planning_application.save
      redirect_to @planning_application, notice: "Policy classes have been successfully added"
    else
      redirect_to new_planning_application_policy_class_path(@planning_application, part: params[:part]), alert: @planning_application.errors.full_messages
    end
  end

  def show; end

  def update
    new_policies = policies_params[:policies]

    @policy_class.policies.each do |policy|
      value = new_policies[policy["id"]]

      policy["status"] = value if value.present?
    end

    if @planning_application.save
      redirect_to @planning_application, notice: "Successfully updated policy class"
    end
  end

  def destroy
    @planning_application.policy_classes.delete(@policy_class)

    if @planning_application.save
      redirect_to @planning_application, notice: "Policy class has been removed."
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
    part, id = params[:id].split("-")

    @policy_class = @planning_application.policy_classes.find { |c| c.part == part.to_i && c.id == id }
  end

  def set_planning_application
    @planning_application = current_local_authority.planning_applications.find(params[:planning_application_id])
  end
end
