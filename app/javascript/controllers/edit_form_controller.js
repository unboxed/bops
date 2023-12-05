import { Controller } from "@hotwired/stimulus"
import { ajax } from "@rails/ujs"

export default class extends Controller {
  handleClick(event) {
    event.preventDefault()

    event.currentTarget.parentElement.parentElement.classList.remove(
      "proposal-details-sub-heading",
    )
    event.currentTarget.parentElement.parentElement
      .querySelector(".govuk-body")
      .classList.add("govuk-!-display-none")
    event.currentTarget.parentElement.parentElement
      .querySelector("form")
      .classList.remove("govuk-!-display-none")
    event.currentTarget.parentElement.classList.add("govuk-!-display-none")
  }
}
