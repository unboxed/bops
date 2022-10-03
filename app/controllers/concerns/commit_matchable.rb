# frozen_string_literal: true

module CommitMatchable
  extend ActiveSupport::Concern

  def commit_matches?(regex)
    params[:commit]&.downcase&.match(regex).present?
  end
end
