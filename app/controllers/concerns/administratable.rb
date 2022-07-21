# frozen_string_literal: true

module Administratable
  extend ActiveSupport::Concern

  def enforce_user_permissions
    redirect_to root_path unless current_user&.administrator?
  end
end
