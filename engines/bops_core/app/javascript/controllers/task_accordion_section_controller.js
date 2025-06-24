import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    className: {
      type: String,
      default: "bops-task-accordion__section--expanded",
    },
  }

  connect() {
    this.toggleIfNotExpanded()

    window.addEventListener("hashchange", () => {
      this.toggleIfNotExpanded()
    })
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

  toggleIfNotExpanded() {
    if (this.isTarget && !this.isExpanded) {
      this.toggle()
    }
  }

  get isExpanded() {
    return this.element.classList.contains(this.classNameValue)
  }

  get isTarget() {
    return `#${this.element.id}` === window.location.hash
  }

  get button() {
    return this.element.querySelector("button")
  }
}
