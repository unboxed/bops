import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["iframe"]

  handleClick(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.hasIframeTarget) {
      this.iframeTarget.contentWindow.print()
    }
  }
}
