# frozen_string_literal: true

module BopsAdmin
  class ConsulteesController < ApplicationController
    self.page_key = "applications"

    before_action :set_consultees, only: %i[index]
    before_action :build_consultee, only: %i[new create]
    before_action :set_constraints, only: %i[new edit create update]
    before_action :set_consultee, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to consultees_path
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
        if @consultee.save
          format.html do
            redirect_to consultees_path, notice: t(".consultee_successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @consultee.update(consultee_params)
          format.html do
            redirect_to consultees_path, notice: t(".consultee_successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @consultee.destroy
          format.html do
            redirect_to consultees_path, notice: t(".consultee_successfully_destroyed")
          end
        else
          format.html do
            redirect_to consultees_path, alert: t(".consultee_unsuccessfully_destroyed")
          end
        end
      end
    end

    private

    def set_consultees
      @pagy, @consultees = pagy(contacts.consultees(search_param), limit: 10)
    end

    def search_param
      params.fetch(:q, "")
    end

    def build_consultee
      @consultee = contacts.build_consultee(consultee_params)
    end

    def set_consultee
      @consultee = contacts.consultee
        .includes(:constraints)
        .find(params[:id])
    end

    def consultee_params
      if action_name == "new"
        {}
      else
        params.require(:consultee).permit(*consultee_attributes)
      end
    end

    def consultee_attributes
      [
        :origin,
        :name,
        :role,
        :organisation,
        :email_address,
        {constraint_ids: []}
      ]
    end

    def set_constraints
      @constraints = Constraint
        .options_for_local_authority(current_local_authority.id)
        .order(:category, :type)
    end

    def contacts
      current_local_authority.contacts
    end
  end
end
