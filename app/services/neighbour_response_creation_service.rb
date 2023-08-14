# frozen_string_literal: true

class NeighbourResponseCreationService
  class CreateError < StandardError; end

  def initialize(planning_application:, **options)
    @planning_application = planning_application
    options.each { |k, v| instance_variable_set("@#{k}", v) unless v.nil? }
  end

  def call
    save_neighbour_response!(build_neighbour_response)
  end

  private

  attr_reader :local_authority, :params, :api_user

  def build_neighbour_response
    response = @planning_application.consultation.neighbour_responses.build(
      neighbour_response_params.except(:address).merge!(
        received_at: Time.zone.now
      )
    )

    response.neighbour = @planning_application.consultation.neighbours.build(
      address: neighbour_response_params[:address], selected: false
    )

    response
  end

  # # match user input address to address in system?
  def save_neighbour_response!(neighbour_response)
    NeighbourResponse.transaction do
      neighbour_response.save!
    end

    neighbour_response
  rescue ActiveRecord::RecordInvalid, ArgumentError, NoMethodError => e
    raise CreateError, e.message
  end

  def neighbour_response_params
    permitted_keys = %i[name
                        email
                        address
                        response
                        summary_tag]

    params.permit permitted_keys
  end
end
