# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "StateMachineTransitions" do |request_type, state, valid_states|
  let(:states) { %i[pending open cancelled closed] }
  let(:invalid_states) { states - valid_states }
  let(:validation_request) { create("#{request_type}_validation_request", :"#{state}") }

  describe "transitions" do
    it "transitions to state" do
      valid_states.each do |valid_state|
        expect(validation_request).to allow_transition_to(valid_state)
      end
    end

    it "does not transition to state" do
      invalid_states.each do |invalid_state|
        expect(validation_request).not_to allow_transition_to(invalid_state)
      end
    end
  end
end

RSpec.shared_examples "StateMachineEvents" do |request_type, state, valid_events|
  let(:events) { %i[mark_as_sent! cancel] }
  let(:invalid_events) { events - valid_events }
  let(:validation_request) { create("#{request_type}_validation_request", :"#{state}") }

  describe "events" do
    it "allows event" do
      valid_events.each do |valid_event|
        expect(validation_request).to allow_event(valid_event)
      end
    end

    it "does not allow event" do
      invalid_events.each do |invalid_event|
        expect(validation_request).not_to allow_event(invalid_event)
      end
    end
  end
end
