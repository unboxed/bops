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

    event.target.parentElement.getElementsByClassName("truncated-comment")[0].innerHTML += 
      event.target.parentElement.getElementsByClassName("hidden-comment")[0].innerHTML

    event.target.classList.add("govuk-!-display-none")
  }
}
