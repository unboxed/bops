import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content"]

  static values = {
    className: { type: String, default: "govuk-!-display-none" },
    condensedText: { type: String, default: "Show more" },
    expandedText: { type: String, default: "Show less" },
  }

  click(_event) {
    this.toggle(!this.isVisible)
  }

  show() {
    this.toggle(true)
  }

  hide() {
    this.toggle(false)
  }

  toggle(visibility) {
    this.contentTarget.classList.toggle(this.classNameValue, !visibility)
    this.buttonTarget.textContent = visibility
      ? this.expandedTextValue
      : this.condensedTextValue
  }

  get isVisible() {
    return !this.contentTarget.classList.contains(this.classNameValue)
  }
}
