import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    this.classes.toggle("max-lines--clamped")
  }

  get classes() {
    return this.element.classList
  }
}
