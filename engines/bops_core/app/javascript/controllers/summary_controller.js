import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "navigation"]

  static values = {
    initialState: { type: String, default: "condensed" },
    className: { type: String, default: "bops-summary--expanded" },
    condensedText: { type: String, default: "Show more" },
    expandedText: { type: String, default: "Show less" },
  }

  connect() {
    if (!this.hasButtonTarget) {
      this.buttonTarget = this.createButtonElement()

      this.navigationTarget.insertBefore(
        this.buttonTarget,
        this.navigationTarget.firstElementChild,
      )

      this.buttonTarget.addEventListener("click", () => {
        this.toggle(!this.isExpanded)
      })
    } else {
      this.buttonTarget = this.navigationTarget.firstElementChild
    }

    this.contentTarget.classList.toggle(
      this.classNameValue,
      this.isInitiallyExpanded,
    )
  }

  toggle(expanded) {
    this.buttonTarget.textContent = this.buttonText(expanded)
    this.contentTarget.classList.toggle(this.classNameValue, expanded)
  }

  buttonText(expanded) {
    return expanded ? this.expandedTextValue : this.condensedTextValue
  }

  createButtonElement() {
    const element = document.createElement("button")

    element.classList.add("button-as-link")
    element.type = "button"
    element.textContent = this.buttonText(this.isInitiallyExpanded)

    return element
  }

  get isInitiallyExpanded() {
    return "expanded" === this.initialStateValue
  }

  get isExpanded() {
    return this.contentTarget.classList.contains(this.classNameValue)
  }

  get hasButtonTarget() {
    const element = this.navigationTarget.firstElementChild

    return (
      element.tagName === "BUTTON" &&
      (element.textContent === this.expandedTextValue ||
        element.textContent === this.condensedTextValue)
    )
  }
}
