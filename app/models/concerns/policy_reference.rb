module PolicyReference
  extend ActiveSupport::Concern

  class_methods do
    def first_schedule
      I18n.t("schedules").first
    end

    def all_parts
      first_schedule[:parts]
    end

    def classes_for_part(number)
      all_parts[number.to_i][:classes].map do |klass|
        klass[:part] = number

        klass
      end
    end
  end

  included do
    def clear_all_policy_classes!
      self[:policy_classes] = []

      save!
    end

    def policy_classes=(classes)
      current = policy_classes.map { |h| HashWithIndifferentAccess.new(h) }

      classes.map { |h| HashWithIndifferentAccess.new(h) }.each do |c|
        next if current.detect { |k| k["id"] == c["id"] && k["part"] == c["part"] }

        c["policies"].each do |policy|
          policy.merge!({ "status" => "undetermined" })
        end

        current << c
      end

      super(current)
    end
  end
end
