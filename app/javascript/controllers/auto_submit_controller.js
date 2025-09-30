import { Controller } from "@hotwired/stimulus"

// Submits the parent form whenever a controlled element changes.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
