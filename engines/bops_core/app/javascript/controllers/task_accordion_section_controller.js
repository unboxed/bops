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
      this.button.ariaExpanded = "true"
      this.buttonText.textContent = this.collapseTextValue
    } else {
      this.button.ariaExpanded = "false"
      this.buttonText.textContent = this.expandTextValue
    }

    this.dispatch("toggled")
  }

  get isExpanded() {
    return this.element.classList.contains(this.classNameValue)
  }

  get button() {
    return this.element.querySelector("button")
  }

  get buttonText() {
    return this.button.querySelector("span")
  }
}
