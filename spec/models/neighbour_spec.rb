# frozen_string_literal: true

require "rails_helper"

RSpec.describe Neighbour do
  describe "#valid?" do
    let(:neighbour) { build(:neighbour) }

    it "is true for factory" do
      expect(neighbour.valid?).to be(true)
    end
  end

  describe "#update_lonlat" do
    it "is called on creation" do
      neighbour = build(:neighbour, address: "123 street, wherever")

      mock = double(NeighbourCoordinatesUpdateService)
      expect(mock).to receive(:call).at_least(:once)
      stub_const("NeighbourCoordinatesUpdateService", mock)

      expect {
        neighbour.save!
      }.to have_enqueued_job(NeighbourCoordinatesUpdateJob)

      perform_enqueued_jobs
    end

    it "is called on change" do
      neighbour = create(:neighbour, address: "123 street, wherever")

      mock = double(NeighbourCoordinatesUpdateService)
      expect(mock).to receive(:call).at_least(:once)
      stub_const("NeighbourCoordinatesUpdateService", mock)

      expect {
        neighbour.address = "234 street, wherever"
        neighbour.save!
      }.to have_enqueued_job(NeighbourCoordinatesUpdateJob)

      perform_enqueued_jobs
    end
  end
end
