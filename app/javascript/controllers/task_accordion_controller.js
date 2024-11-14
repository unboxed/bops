import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    expandAllText: { type: String, default: "Expand all" },
    collapseAllText: { type: String, default: "Collapse all" },
    className: {
      type: String,
      default: "bops-task-accordion__section--expanded",
    },
  }

  toggleAll(event) {
    if (this.isExpanded) {
      this.sections.forEach((section) => {
        section.classList.remove(this.classNameValue)
      })

      this.buttonText.textContent = this.expandAllTextValue
    } else {
      this.sections.forEach((section) => {
        section.classList.add(this.classNameValue)
      })

      this.buttonText.textContent = this.collapseAllTextValue
    }
  }

  sectionToggled(event) {
    if (this.isExpanded) {
      this.buttonText.textContent = this.collapseAllTextValue
    } else {
      this.buttonText.textContent = this.expandAllTextValue
    }
  }

  get sections() {
    return Array.from(
      this.element.querySelectorAll("div.bops-task-accordion__section"),
    )
  }

  get isExpanded() {
    return this.sections.every((section) => {
      return section.classList.contains(this.classNameValue)
    })
  }

  get buttonText() {
    return this.element.querySelector(
      "div.bops-task-accordion-controls button span",
    )
  }
}
