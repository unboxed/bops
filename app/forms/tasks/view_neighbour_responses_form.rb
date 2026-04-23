# frozen_string_literal: true

module Tasks
  class ViewNeighbourResponsesForm < Form
    self.task_actions = %w[save_draft save_and_complete add_neighbour_response update_neighbour_response]

    attribute :name, :string
    attribute :email, :string
    attribute :address, :string
    attribute :new_address, :string
    attribute :received_at, :date
    attribute :summary_tag, :string
    attribute :tags, :list, default: []
    attribute :response, :string
    attribute :files, array: true

    after_initialize do
      @consultation = planning_application.consultation
      @neighbour_responses = @consultation.neighbour_responses.includes(
        %i[neighbour redacted_by documents]
      ).select(&:persisted?)
      @neighbour_response = if params[:id].present?
        @consultation.neighbour_responses.find(params[:id])
      else
        @consultation.neighbour_responses.new
      end

      if @neighbour_response.persisted?
        self.name = @neighbour_response.name
        self.email = @neighbour_response.email
        self.address = @neighbour_response.neighbour&.address
        self.received_at = @neighbour_response.received_at
        self.summary_tag = @neighbour_response.summary_tag
        self.tags = @neighbour_response.tags
        self.response = @neighbour_response.response
      end
    end

    with_options on: :add_neighbour_response do
      validates :name, presence: {message: "Enter neighbour name"}
      validate :address_or_new_address_present
      validates :response, presence: {message: "Enter neighbour response"}
      validates :summary_tag, presence: {message: "Please choose at least one relevant tag"}
      validates :received_at, presence: {message: "Enter when response was received"}
    end

    with_options on: :update_neighbour_response do
      validate :address_or_new_address_present
    end

    attr_reader :neighbour_response, :neighbour_responses, :consultation

    def new_neighbour_response_url
      route_for(:task, planning_application, slug: task.full_slug, new: true, only_path: true)
    end

    def edit_neighbour_response_url(neighbour_response)
      route_for(:edit_task_component, planning_application, slug: task.full_slug, id: neighbour_response.id, only_path: true)
    end

    def update_neighbour_response_url
      route_for(:task_component, planning_application, slug: task.full_slug, id: neighbour_response.id, only_path: true)
    end

    def failure_template
      case action
      when "update_neighbour_response"
        :edit
      else
        super
      end
    end

    private

    def address_or_new_address_present
      if address.blank? && new_address.blank?
        errors.add(:address, "Enter a neighbour address or add a new one")
      end
    end

    def add_neighbour_response
      neighbour = find_or_build_neighbour

      if neighbour&.new_record? && !neighbour.valid?
        errors.merge!(neighbour.errors)
        return false
      end

      neighbour_response = consultation.neighbour_responses.build(
        consultation_id: consultation.id,
        name: name,
        email: email,
        received_at: received_at,
        summary_tag: summary_tag,
        tags: tags,
        response: response
      )

      transaction do
        neighbour_response.neighbour = neighbour
        neighbour_response.save!
        create_files(neighbour_response) if files_present?
        create_audit_log(neighbour_response)
        task.start!
      end
    end

    def update_neighbour_response
      updated_neighbour = find_or_build_neighbour

      if updated_neighbour&.new_record? && !updated_neighbour.valid?
        errors.merge!(updated_neighbour.errors)
        return false
      end

      transaction do
        update_attrs = {
          name: name,
          email: email,
          received_at: received_at,
          summary_tag: summary_tag,
          tags: tags
        }

        if updated_neighbour.present? && updated_neighbour != neighbour_response.neighbour
          updated_neighbour.save! if updated_neighbour.new_record?
          update_attrs[:neighbour] = updated_neighbour
        end

        neighbour_response.update!(update_attrs)
        create_edit_audit_log
        task.in_progress!
      end
    end

    def find_or_build_neighbour
      if new_address.present?
        consultation.neighbours.find_or_initialize_by(address: new_address) do |n|
          n.selected = false
          n.source = "sent_comment"
        end
      elsif address.present?
        consultation.neighbours.find_by(address: address)
      end
    end

    def create_files(neighbour_response)
      files.compact_blank.each do |file|
        planning_application.documents.create!(file:, owner: neighbour_response)
      end
    end

    def files_present?
      files&.compact_blank&.any?
    end

    def create_edit_audit_log
      Audit.create!(
        planning_application_id: planning_application.id,
        user: Current.user,
        activity_type: "neighbour_response_edited",
        audit_comment: "Neighbour response from #{neighbour_response.neighbour.address} was edited"
      )
    end

    def create_audit_log(neighbour_response)
      Audit.create!(
        planning_application_id: planning_application.id,
        user: Current.user,
        activity_type: "neighbour_response_uploaded",
        audit_comment: "Neighbour response from #{neighbour_response.neighbour.address} was uploaded"
      )
    end

    def form_params(params)
      params.fetch(param_key, {}).permit(:name, :email, :address, :new_address, :received_at, :summary_tag, :response, tags: [], files: [])
    end
  end
end
