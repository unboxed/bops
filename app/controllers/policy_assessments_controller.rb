class PolicyAssessmentsController < PlanningApplicationsController
  before_action :set_planning_application

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

  private

  def policy_class_params
    params.permit(:part, policy_classes: [])
  end
end
