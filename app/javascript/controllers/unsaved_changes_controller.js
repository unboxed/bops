import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.originalValues = this.currentValues()
  }

  handleBeforeUnload(event) {
    if (this.submitEvent || this.valuesUnchanged()) return
    event.returnValue = "false"
    return event.returnValue
  }

  currentValues() {
    const formData = new FormData(this.formTarget)
    formData.delete("authenticity_token")
    return Array.from(formData.values())
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
