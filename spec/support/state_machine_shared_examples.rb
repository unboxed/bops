# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "ValidationRequestStateMachineTransitions" do |request_type, state, valid_states|
  states = %i[pending open cancelled closed]
  invalid_states = states - valid_states

  let(:validation_request) { create("#{request_type}_validation_request", :"#{state}") }

  describe "transitions" do
    valid_states.each do |valid_state|
      it "#{request_type} allows transition from '#{state}' to '#{valid_state}'" do
        expect(validation_request).to allow_transition_to(valid_state)
      end
    end

    invalid_states.each do |invalid_state|
      it "#{request_type} does not allow transition from '#{state}' to '#{invalid_state}'" do
        expect(validation_request).not_to allow_transition_to(invalid_state)
      end
    end
  end
end

RSpec.shared_examples "PlanningApplicationStateMachineTransitions" do |state, valid_states|
  states = PlanningApplication.aasm.states.map(&:name)
  invalid_states = states - valid_states

  let(:planning_application) { create(:planning_application, :"#{state}") }

  describe "transitions" do
    valid_states.each do |valid_state|
      it "planning_application allows transitions from '#{state}' to '#{valid_state}'" do
        expect(validation_request).to allow_transition_to(valid_state)
      end
    end

    invalid_states.each do |invalid_state|
      it "planning_application does not allow transition from '#{state}' to '#{invalid_state}'" do
        expect(validation_request).not_to allow_transition_to(invalid_state)
      end
    end
  end
end

RSpec.shared_examples "ValidationRequestStateMachineEvents" do |request_type, state, valid_events|
  events = %i[mark_as_sent cancel auto_close]
  invalid_events = events - valid_events

  let(:validation_request) { create("#{request_type}_validation_request", :"#{state}") }

  describe "events" do
    valid_events.each do |valid_event|
      it "#{request_type} with state '#{state}' allows the event '#{valid_event}'" do
        expect(validation_request).to allow_event(valid_event)
      end
    end

    invalid_events.each do |invalid_event|
      it "#{request_type} with state '#{state}' does not allow event '#{invalid_event}'" do
        expect(validation_request).not_to allow_event(invalid_event)
      end
    end
  end
end

RSpec.shared_examples "PlanningApplicationStateMachineEvents" do |state, valid_events|
  events = PlanningApplication.aasm.events.map(&:name)
  invalid_events = events - valid_events

  let(:planning_application) { create(:planning_application, :"#{state}") }

  describe "events" do
    valid_events.each do |valid_event|
      it "planning_application with state '#{state}' allows the '#{valid_event}' event" do
        expect(planning_application).to allow_event(valid_event)
      end
    end

    invalid_events.each do |invalid_event|
      it "planning_application with state '#{state}' does not allow the '#{invalid_event}' event" do
        expect(planning_application).not_to allow_event(invalid_event)
      end
    end
  end
end
