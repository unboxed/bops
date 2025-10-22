# frozen_string_literal: true

module BopsAdmin
  class PolicyReferencesController < PolicyController
    before_action :set_policy_references, only: %i[index]
    before_action :build_policy_reference, only: %i[new create]
    before_action :set_policy_reference, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to policy_references_path
    end

    def index
      respond_to do |format|
        format.html
      end
    end

    def new
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def create
      respond_to do |format|
        if @policy_reference.save
          format.html do
            redirect_to policy_references_path, notice: t(".successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @policy_reference.update(policy_reference_params)
          format.html do
            redirect_to policy_references_path, notice: t(".successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @policy_reference.destroy
          format.html do
            redirect_to policy_references_path, notice: t(".successfully_destroyed")
          end
        else
          format.html do
            redirect_to policy_references_path, alert: t(".not_destroyed")
          end
        end
      end
    end

    private

    def set_policy_references
      @pagy, @policy_references = pagy(current_local_authority.policy_references.search(search_param), limit: 10)
    end

    def search_param
      params.fetch(:q, "")
    end

    def build_policy_reference
      @policy_reference = current_local_authority.policy_references.build(policy_reference_params)
    end

    def set_policy_reference
      @policy_reference = current_local_authority.policy_references.find(params[:id])
    end

    def policy_reference_params
      if action_name == "new"
        {}
      else
        params.require(:policy_reference).permit(*policy_reference_attributes, policy_area_ids: [])
      end
    end

    def policy_reference_attributes
      %i[code description url]
    end
  end
end
