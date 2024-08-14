# frozen_string_literal: true

require "rails_helper"

RSpec.describe NeighbourCoordinatesUpdateService, type: :service do
  let(:neighbour) { create(:neighbour) }
  it "fetches a response from osplaces" do
    described_class.call(neighbour)
    expect(neighbour.lonlat).not_to be_blank
  end

  it "does nothing if osplaces fails" do
    stub_request(:get, "https://api.os.uk/search/places/v1/find")
      .with(query: hash_including({}))
      .to_return({body: nil, status: Rack::Utils.status_code(500)})
    described_class.call(neighbour)
    expect(neighbour.lonlat).to be_blank
  end
end
