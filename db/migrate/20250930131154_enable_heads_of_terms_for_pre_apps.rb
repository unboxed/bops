# frozen_string_literal: true

class EnableHeadsOfTermsForPreApps < ActiveRecord::Migration[8.0]
  class ApplicationTypeConfig < ActiveRecord::Base; end

  def up
    ApplicationTypeConfig.where(code: "preApp").find_each do |config|
      features = (config.features || {}).dup
      features["heads_of_terms"] = true
      config.update_columns(features: features)
    end
  end

  def down
    ApplicationTypeConfig.where(code: "preApp").find_each do |config|
      features = (config.features || {}).dup
      features["heads_of_terms"] = false
      config.update_columns(features: features)
    end
  end
end

