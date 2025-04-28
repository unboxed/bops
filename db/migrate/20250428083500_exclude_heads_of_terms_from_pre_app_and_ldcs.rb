# frozen_string_literal: true

class ExcludeHeadsOfTermsFromPreAppAndLdcs < ActiveRecord::Migration[7.2]
  class ApplicationTypeConfig < ActiveRecord::Base; end

  def change
    reversible do |dir|
      dir.up do
        ApplicationTypeConfig.find_each do |config|
          case config.code
          when /\ApreApp\z/, /\Aldc\./
            config.update!(features: config.features.merge("heads_of_terms" => false))
          else
            config.update!(features: config.features.merge("heads_of_terms" => true))
          end
        end
      end

      dir.down do
        ApplicationTypeConfig.find_each do |config|
          features = config.features.except("heads_of_terms")
          config.update!(features: features)
        end
      end
    end
  end
end
