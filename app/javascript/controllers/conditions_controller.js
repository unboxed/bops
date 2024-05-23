import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  confirmDeletion(event) {
    const response = confirm("Confirm deletion?")
    if (!response) {
      event.preventDefault()
    }

    return response
  }
}
