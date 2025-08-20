# frozen_string_literal: true

module BopsCore
  module CaseRecords
    module AssignUsersController
      extend ActiveSupport::Concern

      included do
        wrap_parameters false

        before_action :set_case_record
        before_action :set_users
        before_action :set_user, only: [:update]
      end

      def index
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @case_record.update(user: @user)
            format.html { redirect_to redirect_path, notice: t(".success") }
          else
            format.html { render :index }
          end
        end
      end

      private

      def set_case_record
        @case_record = @current_local_authority.case_records.find(params[:case_id])
      end

      def set_users
        @users = current_local_authority.users.non_administrator
      end

      def set_user
        @user = @users.find_by(id: params[:user_id])
      end
    end
  end
end
