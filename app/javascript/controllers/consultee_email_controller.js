import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subject", "body"]

  reset() {
    console.log("Reset consultee email")
    this.subjectTarget.value = this.defaultSubject
    this.bodyTarget.value = this.defaultBody
  }

  get defaultSubject() {
    return this.data.get("default-subject")
  }

  get defaultBody() {
    return this.data.get("default-body")
  }
}
