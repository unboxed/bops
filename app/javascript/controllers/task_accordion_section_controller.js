import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    expandText: { type: String, default: "Expand" },
    collapseText: { type: String, default: "Collapse" },
    className: {
      type: String,
      default: "bops-task-accordion__section--expanded",
    },
  }

  toggle(event) {
    this.element.classList.toggle(this.classNameValue)

    if (this.isExpanded) {
      this.buttonText.textContent = this.collapseTextValue
    } else {
      this.buttonText.textContent = this.expandTextValue
    }

    this.dispatch("toggled")
  }

  get isExpanded() {
    return this.element.classList.contains(this.classNameValue)
  }

  get buttonText() {
    return this.element.querySelector("button span")
  }
}