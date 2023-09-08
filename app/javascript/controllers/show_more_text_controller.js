import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleClick(event) {
    event.preventDefault()

    // Remove the ellipses from the comment
    const replaceText = event.target.parentElement
      .getElementsByClassName("truncated-comment")[0]
      .innerText.slice(0, -3)
    event.target.parentElement.getElementsByClassName(
      "truncated-comment",
    )[0].innerText = replaceText

    // Show the rest of the comment and hide "show more"
    event.target.parentElement
      .getElementsByClassName("hidden-comment display-none")[0]
      .classList.remove("display-none")
    event.target.classList.add("display-none")
  }
}
