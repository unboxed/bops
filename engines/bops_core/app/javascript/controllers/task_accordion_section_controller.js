import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    className: {
      type: String,
      default: "bops-task-accordion__section--expanded",
    },
  }

  toggle(_event) {
    this.element.classList.toggle(this.classNameValue)

    if (this.isExpanded) {
      this.button.ariaExpanded = "true"
    } else {
      this.button.ariaExpanded = "false"
    }

    this.dispatch("toggled")
  }

  get isExpanded() {
    return this.element.classList.contains(this.classNameValue)
  }

  get button() {
    return this.element.querySelector("button")
  }
}
