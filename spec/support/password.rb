# frozen_string_literal: true

def secure_password
  SecureRandom.random_bytes(256).chars.select { |b| b.ord > 32 && b.ord < 0x7f }.join[0, 128]
end
