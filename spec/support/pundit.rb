# frozen_string_literal: true

RSpec::Matchers.define :permit_action do |action, *args|
  match do |policy|
    if args.any?
      policy.public_send("#{action}?", *args)
    else
      policy.public_send("#{action}?")
    end
  end

  failure_message do |policy|
    "#{policy.class} does not permit #{action} for #{policy.user.inspect}."
  end

  failure_message_when_negated do |policy|
    "#{policy.class} does not forbid #{action} for #{policy.user.inspect}."
  end
end

RSpec::Matchers.define :forbid_action do |action, *args|
  match do |policy|
    if args.any?
      !policy.public_send("#{action}?", *args)
    else
      !policy.public_send("#{action}?")
    end
  end

  failure_message do |policy|
    "#{policy.class} does not forbid #{action} for #{policy.user.inspect}."
  end

  failure_message_when_negated do |policy|
    "#{policy.class} does forbid #{action} for #{policy.user.inspect}."
  end
end
