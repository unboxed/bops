import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleEvent(event) {
    if (event.target.value === "true") {
      if (
        !document
          .getElementById("site-notice-form-actions")
          .classList.contains("govuk-!-display-none")
      ) {
        document
          .getElementById("site-notice-form-actions")
          .classList.add("govuk-!-display-none")
      }

      document
        .getElementById("site-notice-options")
        .classList.remove("govuk-!-display-none")
    } else if (event.target.value === "false") {
      if (
        !document
          .getElementById("site-notice-options")
          .classList.contains("govuk-!-display-none")
      ) {
        document
          .getElementById("site-notice-options")
          .classList.add("govuk-!-display-none")
      }

      document
        .getElementById("site-notice-form-actions")
        .classList.remove("govuk-!-display-none")
    }
  }
}
