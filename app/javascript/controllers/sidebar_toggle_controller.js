import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content"]

  static values = {
    buttonClassName: { type: String, default: "bops-sidebar__toggle--open" },
    contentClassName: { type: String, default: "bops-sidebar__list--open" },
  }

  toggle(_event) {
    this.buttonTarget.classList.toggle(
      this.buttonClassNameValue,
      !this.isVisible,
    )
    this.contentTarget.classList.toggle(
      this.contentClassNameValue,
      !this.isVisible,
    )
    if (this.buttonTarget.hasAttribute("aria-expanded")) {
      this.buttonTarget.setAttribute("aria-expanded", this.isVisible)
    }
  }

  get isVisible() {
    return this.contentTarget.classList.contains(this.contentClassNameValue)
  }
}
