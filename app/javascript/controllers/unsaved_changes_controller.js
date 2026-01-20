import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  static values = {
    message: {
      type: String,
      default:
        "You have unsaved changes. Are you sure you want to leave this page?",
    },
  }

  connect() {
    this.originalValues = this.currentValues()
    this.boundHandleLinkClick = this.handleLinkClick.bind(this)
    document.addEventListener("click", this.boundHandleLinkClick, true)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleLinkClick, true)
  }

  handleBeforeUnload(event) {
    if (this.submitEvent || this.valuesUnchanged()) return
    event.returnValue = "false"
    return event.returnValue
  }

  handleLinkClick(event) {
    if (this.submitEvent || this.valuesUnchanged()) return

    const link = event.target.closest("a[href]")
    if (!link) return

    const _href = link.getAttribute("href")

    if (link.dataset.confirm || link.dataset.turboConfirm) return

    if (this.formTarget.contains(link)) return

    event.preventDefault()
    event.stopPropagation()

    if (window.confirm(this.messageValue)) {
      this.submitEvent = true
      if (link.dataset.method || link.dataset.turboMethod) {
        link.click()
      } else {
        window.location.href = link.href
      }
    }
  }

  currentValues() {
    const formData = new FormData(this.formTarget)
    formData.delete("authenticity_token")
    return Array.from(formData.values()).map((value) =>
      this.normalizeValue(value),
    )
  }

  normalizeValue(value) {
    if (value instanceof File) {
      return `file:${value.name}:${value.size}`
    }
    return value
  }

  handleSubmit(_event) {
    this.submitEvent = true
  }

  valuesUnchanged() {
    return this.currentValues().every((value, index) => {
      return value === this.originalValues[index]
    })
  }
}
