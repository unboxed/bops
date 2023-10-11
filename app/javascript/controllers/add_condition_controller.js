import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleClick(event) {
    event.preventDefault()
    const form = event.currentTarget
  }
}
