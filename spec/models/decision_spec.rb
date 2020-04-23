# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decision do
  subject { FactoryBot.create :decision }

  describe "mark_granted" do
    let!(:decided_time) { Time.current }

    before do
      travel_to decided_time do
        subject.mark_granted
      end
    end

    it "sets status to granted" do
      expect(subject).to be_granted
    end

    it "sets decided_at to the current time" do
      expect(subject.decided_at).to be_within(1.second).of decided_time
    end
  end

  describe "mark_refused" do
    let!(:decided_time) { Time.current }

    before do
      travel_to decided_time do
        subject.mark_refused
      end
    end

    it "sets status to refused" do
      expect(subject).to be_refused
    end

    it "sets decided_at to the current time" do
      expect(subject.decided_at).to be_within(1.second).of decided_time
    end
  end
end
