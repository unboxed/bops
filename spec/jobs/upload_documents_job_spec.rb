# frozen_string_literal: true

require "rails_helper"

RSpec.describe UploadDocumentsJob do
  let!(:planning_application) { create(:planning_application) }
  let(:document) do
    create(:document, :with_file, :with_tags,
           planning_application:)
  end

  describe "#perform" do
    let!(:service) { double }

    it "calls UploadDocumentsService" do
      expect(service).to receive(:call)

      allow(UploadDocumentsService).to receive(:new)
        .with(
          files: document,
          planning_application:
        ).and_return(service)

      perform_enqueued_jobs do
        described_class.perform_later(
          files: document,
          planning_application:
        )
      end
    end
  end
end
