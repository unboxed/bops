import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  handleClick(event) {
    event.preventDefault()

    this.containerTarget.classList.remove("flex-between")
    this.containerTarget
      .querySelector("p")
      .classList.add("govuk-!-display-none")
    this.containerTarget
      .querySelector("form")
      .classList.remove("govuk-!-display-none")
    event.currentTarget.parentElement.classList.add("govuk-!-display-none")
  }
}
