# frozen_string_literal: true

module CommitMatchable
  extend ActiveSupport::Concern

  def commit_matches?(regex)
    params[:commit]&.downcase&.match(regex).present?
  end

  def mark_as_complete?
    params[:commit] == I18n.t("form_actions.save_and_mark_as_complete")
  end

  def save_progress?
    params[:commit] == I18n.t("form_actions.save_and_come_back_later")
  end
end
