# frozen_string_literal: true

require "pagy/extras/overflow"

# Match GOV.UK Design System
# https://govuk-components.netlify.app/components/pagination/#when-there-are-lots-of-pages
Pagy::DEFAULT[:size] = [1, 1, 1, 1]

# default behaviour: exception to be caught and redirected
Pagy::DEFAULT[:overflow] = :exception
