import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    className: {
      type: String,
      default: "bops-task-accordion__section--expanded",
    },
    successClassName: {
      type: String,
      default: "bops-task-accordion__section--success",
    },
  }

  connect() {
    if (this.openNextSibling) {
      this.element.classList.add(this.successClassNameValue)

      setTimeout(() => {
        this.toggleNextSiblingIfNotExpanded()
      }, 50)
    } else if (this.isTarget) {
      setTimeout(() => {
        this.toggleIfNotExpanded()
      }, 50)
    }
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
    if (!this.isExpanded) {
      this.toggle()
    }
  }

  toggleNextSiblingIfNotExpanded() {
    const nextSibling = this.element.nextElementSibling

    if (nextSibling) {
      const controller = this.application.getControllerForElementAndIdentifier(nextSibling, this.identifier)

      if (controller) {
        controller.toggleIfNotExpanded()
      }
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

  get queryParams() {
    return new URLSearchParams(window.location.search)
  }

  get openNextParam() {
    return this.queryParams.get("next")
  }

  get openNextSibling() {
    return this.isTarget && this.openNextParam === "true"
  }
}
