# frozen_string_literal: true

module Tasks
  class CheckEnvironmentImpactAssessmentForm < Form
    self.task_actions = %w[save_and_complete edit_form]

    attribute :required, :boolean
    attribute :email_address, :string
    attribute :address, :string
    attribute :fee, :integer

    after_initialize do
      if (eia = planning_application.environment_impact_assessment)
        self.required = eia.required
        self.email_address = eia.email_address
        self.address = eia.address
        self.fee = eia.fee
      end
    end

    with_options on: :save_and_complete do
      validates :required, inclusion: {in: [true, false], message: "Select whether an Environment Impact Assessment is required."}
      validates :fee, presence: {message: "Enter the fee to obtain a copy of the EIA", unless: -> { address.blank? }}, if: :required
      validates :address, presence: {message: "Enter the address to view or request a copy of the EIA", unless: -> { fee.blank? }}, if: :required
    end

    private

    def save_and_complete
      eia = planning_application.environment_impact_assessment ||
        planning_application.build_environment_impact_assessment

      transaction do
        eia.update!(eia_attributes)
        task.completed!
      end
    end

    def eia_attributes
      if required
        {required: true, email_address: email_address, address: address, fee: fee}
      else
        {required: false, email_address: nil, address: nil, fee: nil}
      end
    end
  end
end
