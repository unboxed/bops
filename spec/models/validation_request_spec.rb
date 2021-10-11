# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequest, type: :model do
  let(:request) { create(:additional_document_validation_request, state: "pending") }

  describe "states" do
    it "is initially in pending state" do
      expect(request).to be_pending
    end

    describe "mark_as_sent!" do
      it "updates the notified timestamp" do
        freeze_time do
          expect { request.mark_as_sent! }.to change(request, :notified_at).from(nil).to(Time.zone.now.to_date)
        end
      end
    end
  end
end
