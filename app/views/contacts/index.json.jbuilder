# frozen_string_literal: true

json.array! @contacts do |contact|
  json.id contact.id
  json.name contact.name
  json.email_address contact.email_address
  json.role contact.role
  json.organisation contact.organisation
  json.origin contact.origin
end
