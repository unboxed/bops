import { Controller } from "@hotwired/stimulus"
import { ajax } from "@rails/ujs"

export default class extends Controller {
  handleClick(event) {
    event.preventDefault()

    event.currentTarget.parentElement.parentElement.querySelector(".govuk-body").classList.add('display-none')
    event.currentTarget.parentElement.parentElement.querySelector("form").classList.remove('display-none')
    event.currentTarget.parentElement.classList.add('display-none')
  }
}
