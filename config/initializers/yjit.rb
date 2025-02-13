# frozen_string_literal: true

if defined? RubyVM::YJIT.enable
  Rails.application.config.after_initialize do
    RubyVM::YJIT.enable unless Rails.env.local?
  end
end
