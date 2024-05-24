import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleClick(event) {
    event.preventDefault()

    const truncatedComment =
      this.element.getElementsByClassName("truncated-comment")[0]
    const hiddenComment =
      this.element.getElementsByClassName("hidden-comment")[0]

    // Remove the ellipses from the comment
    const replaceText = truncatedComment.innerText.slice(0, -3)

    truncatedComment.innerText = replaceText

    truncatedComment.innerHTML += hiddenComment.innerHTML

    event.target.classList.add("govuk-!-display-none")
  }
}
