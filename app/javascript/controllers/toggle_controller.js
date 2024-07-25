import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content"]

  initialize() {
    this.className = "govuk-!-display-none"
  }

  click(event) {
    if (this.isVisible) {
      this.hide()
    } else {
      this.show()
    }
  }

  show() {
    this.contentTarget.classList.remove(this.className)
    this.buttonTarget.textContent = "Show less"
  }

  hide() {
    this.contentTarget.classList.add(this.className)
    this.buttonTarget.textContent = "Show more"
  }

  get isVisible() {
    return !this.contentTarget.classList.contains(this.className)
  }
}
