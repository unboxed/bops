import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "form", "buttons"]

  handleClick(event) {
    event.preventDefault()

    this.containerTarget.classList.remove("flex-between")
    this.containerTarget
      .querySelector("p")
      .classList.add("govuk-!-display-none")
    this.formTarget.classList.remove("govuk-!-display-none")
    this.buttonsTarget.classList.add("govuk-!-display-none")
  }
}
