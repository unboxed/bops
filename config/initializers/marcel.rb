# frozen_string_literal: true

# config/initializers/marcel.rb

# NOTE: https://github.com/rails/marcel/issues/77
Marcel::Magic.remove("video/x-ms-wmv") if Marcel::MimeType.for("%PDF-1.6.%wmv2") == "video/x-ms-wmv"
