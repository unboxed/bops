# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentWizard, type: :model do
  subject { FactoryBot.create :document, :with_file }

  it "is valid when created" do
    form = DocumentWizard::ArchiveForm.new({ id: subject.id, archive_reason: "scale", updated_at: Time.zone.now })
    expect(form).to be_valid
  end

  it "is invalid when archive reason is blank" do
    form = DocumentWizard::ArchiveForm.new({ id: subject.id, updated_at: Time.zone.now })
    expect(form).to be_invalid
  end
end
