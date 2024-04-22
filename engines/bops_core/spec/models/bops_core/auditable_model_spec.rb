# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::AuditableModel, type: :model do
  let(:model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Dirty

      include BopsCore::AuditableModel

      attribute :id, :integer
      attribute :name, :string
      attribute :secret, :string
      attribute :created_at, :datetime, default: -> { Time.current }
      attribute :updated_at, :datetime, default: -> { Time.current }

      self.audit_attributes = %w[id name]
      self.audit_changes += %w[secret]

      def initialize(attributes)
        super
        changes_applied
      end

      def update(attributes)
        assign_attributes(attributes)
        changes_applied
      end
    end
  end

  subject do
    model.new(id: 1, name: "Alice", secret: "iwNNgZ1bP11j")
  end

  describe "#audit_attributes" do
    it "only returns the specified attributes" do
      expect(subject.audit_attributes).to match("id" => 1, "name" => "Alice")
    end
  end

  describe "#audit_changes" do
    before do
      subject.update(name: "Bob", secret: "8T5a4KafcSzr")
    end

    it "filters saved changes for irrelevant and sensitive attributes" do
      expect(subject.audit_changes).to match("name" => ["Alice", "Bob"])
    end
  end
end
