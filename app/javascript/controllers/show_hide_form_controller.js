import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleEvent(event) {
    if (event.target.value === "true") {
      if (
        !document
          .getElementById("site-notice-form-actions")
          .classList.contains("display-none")
      ) {
        document
          .getElementById("site-notice-form-actions")
          .classList.add("display-none")
      }

      document
        .getElementById("site-notice-options")
        .classList.remove("display-none")
    } else if (event.target.value === "false") {
      if (
        !document
          .getElementById("site-notice-options")
          .classList.contains("display-none")
      ) {
        document
          .getElementById("site-notice-options")
          .classList.add("display-none")
      }

      document
        .getElementById("site-notice-form-actions")
        .classList.remove("display-none")
    }
  }
}
