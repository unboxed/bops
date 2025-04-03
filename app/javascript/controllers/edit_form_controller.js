import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleClick(event) {
    event.preventDefault()

    event.currentTarget.parentElement.parentElement.classList.remove(
      "flex-between",
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
