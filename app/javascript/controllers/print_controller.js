import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  print(event) {
    event.preventDefault()
    window.print()
  }
}
