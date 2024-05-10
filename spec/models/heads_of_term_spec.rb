# frozen_string_literal: true

require "rails_helper"

RSpec.describe HeadsOfTerm do
  describe "instance_methods" do
    describe "#confirm_pending_requests!" do
      before do
        travel_to(Time.zone.local(2024, 4, 17, 12, 30))
        Current.user = create(:user)
      end

      let(:heads_of_term) { create(:heads_of_term) }
      let(:term1) { create(:term, heads_of_term:) }
      let(:term2) { create(:term, heads_of_term:) }
      let(:term3) { create(:term, heads_of_term:) }
      let!(:request1) { create(:heads_of_terms_validation_request, state: "open", owner: term1) }
      let!(:request2) { create(:heads_of_terms_validation_request, state: "pending", owner: term2) }
      let!(:request3) { create(:heads_of_terms_validation_request, state: "pending", owner: term3) }

      it "only pending validation requests are marked as sent and an email is sent" do
        expect {
          heads_of_term.confirm_pending_requests!
        }.to change {
          ActionMailer::Base.deliveries.count
        }.by(1)

        request1.reload
        expect(request1.state).to eq("open")
        expect(request1.notified_at).not_to eq(Time.zone.local(2024, 4, 17, 12, 30))

        request2.reload
        expect(request2.state).to eq("open")
        expect(request2.notified_at).to eq(Time.zone.local(2024, 4, 17, 12, 30))

        request3.reload
        expect(request3.state).to eq("open")
        expect(request3.notified_at).to eq(Time.zone.local(2024, 4, 17, 12, 30))
      end
    end
  end
end
