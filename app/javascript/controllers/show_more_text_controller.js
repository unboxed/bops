import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  replaceText(event) {
    event.preventDefault()

    const truncatedComment = this.element.querySelector(".truncated-content")
    const hiddenComment = this.element.querySelector(".hidden-content")

    truncatedComment.classList.add("govuk-!-display-none")
    hiddenComment.classList.remove("govuk-!-display-none")

    event.target.classList.add("govuk-!-display-none")
  }
}
