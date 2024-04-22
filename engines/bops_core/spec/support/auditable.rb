# frozen_string_literal: true

RSpec::Matchers.define :have_audit do |expected|
  match(notify_expectation_failures: true) do |block|
    run_expectation(block)

    expect(@event_name).to eq(expected)

    if payload
      expect(@event_payload).to match(payload)
    end
  end

  match_when_negated(notify_expectation_failures: true) do |block|
    expect(@event_name).not_to eq(expected)
  end

  define_method :run_expectation do |block|
    unless Proc === block
      raise ArgumentError, "have_audit only supports block expectations"
    end

    @event_name = nil
    @event_payload = nil

    ActiveSupport::Notifications.subscribe(/\.bops_audit$/) do |event|
      @event_name = event.name.chomp(".bops_audit")
      @event_payload = event.payload
    end

    block.call
  end

  chain :with_payload, :payload
  supports_block_expectations
end
