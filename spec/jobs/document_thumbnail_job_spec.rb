# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentThumbnailJob, type: :job do
  it "is triggered on creation" do
    expect {
      create(:document)
    }.to have_enqueued_job described_class
  end

  it "is not triggered on initialisation" do
    expect {
      build(:document)
    }.not_to have_enqueued_job described_class
  end

  it "is not triggered on subsequent saves" do
    document = create(:document)
    expect {
      document.update!(numbers: "changed test test test")
    }.not_to have_enqueued_job described_class
  end
end
