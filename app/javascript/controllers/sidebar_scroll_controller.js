import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    key: { type: String, default: "sidebar-scroll-position" },
  }

  connect() {
    this.boundSaveBeforeNavigation = this.saveScrollPosition.bind(this)
    document.addEventListener(
      "turbo:before-visit",
      this.boundSaveBeforeNavigation,
    )
    this.restoreScrollPosition()
  }

  disconnect() {
    document.removeEventListener(
      "turbo:before-visit",
      this.boundSaveBeforeNavigation,
    )
    this.saveScrollPosition()
  }

  saveScrollPosition() {
    sessionStorage.setItem(this.keyValue, this.element.scrollTop)
  }

  restoreScrollPosition() {
    const savedPosition = sessionStorage.getItem(this.keyValue)
    if (savedPosition) {
      this.element.scrollTop = Number.parseInt(savedPosition, 10)
    }
  }

  handleScroll() {
    this.saveScrollPosition()
  }
}
