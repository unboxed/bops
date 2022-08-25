import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleClick(_event) {
    this.element.querySelectorAll("input").forEach((input) => {
      input.value = null
    })
  }
}
