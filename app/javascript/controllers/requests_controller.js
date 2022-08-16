import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"

export default class extends Controller {
  static targets = ["form"]

  submitForm(event) {
    const form = this.formTarget

    Rails.ajax({
      type: form.method,
      url: form.action,
      data: new FormData(form),
      success: (data) => { this.element.outerHTML = data.html }
    })
  }
}
