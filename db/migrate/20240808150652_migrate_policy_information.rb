# frozen_string_literal: true

class MigratePolicyInformation < ActiveRecord::Migration[7.1]
  class PolicySection < ActiveRecord::Base; end

  class NewPolicyClass < ActiveRecord::Base
    has_many :policy_sections
  end

  class PolicyPart < ActiveRecord::Base
    has_many :new_policy_classes
  end

  class PolicySchedule < ActiveRecord::Base
    has_many :policy_parts
  end

  def up
    # https://www.legislation.gov.uk/uksi/2015/596/contents
    schedule = PolicySchedule.find_or_create_by!(number: 2, name: "Permitted development rights")

    filepath = Rails.root.join("db/seeds/gpdo.yml")

    if File.exist?(filepath)
      data = YAML.load_file(filepath)

      data["en"]["schedules"].first["parts"].each do |part_key, part_data|
        part = schedule.policy_parts.find_or_create_by!(
          number: part_key,
          name: part_data["name"]
        )

        part_data["classes"].each do |class_data|
          new_policy_class = part.new_policy_classes.find_or_create_by!(
            section: class_data["section"],
            name: class_data["name"],
            url: class_data["url"]
          )

          class_data["policies_attributes"].each do |section_data|
            new_policy_class.policy_sections.find_or_create_by!(
              section: section_data["section"].presence || class_data["section"],
              description: section_data["description"]
            )
          end
        end
      end
    else
      Rails.logger.debug { "YAML file not found at #{filepath}. Skipping data migration." }
    end
  end

  def down
    PolicySection.delete_all
    NewPolicyClass.delete_all
    PolicyPart.delete_all
    PolicySchedule.delete_all
  end
end
