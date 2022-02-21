# frozen_string_literal: true

require "rails_helper"

RSpec.describe UploadDocumentsService, type: :service do
  let!(:planning_application) { create :planning_application }
  let(:document) do
    create :document, :with_file, :with_tags,
           planning_application: planning_application
  end

  describe "#call" do
    let!(:service) { double }

    it "calls UploadDocumentsService" do
      allow(service).to receive(:call).and_return(service)

      allow(described_class).to receive(:new)
        .with(
          files: document,
          planning_application: planning_application
        ).and_return(service)
    end
  end
end
