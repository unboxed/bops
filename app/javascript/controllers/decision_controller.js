import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["statusGranted", "statusRefused", "commentGranted", "commentRefused", "comment" ]

  insertComment(event) {
    if (this.statusGrantedTarget.checked) {
      this.commentTarget.value = this.commentGrantedTarget.value
    } else if (this.statusRefusedTarget.checked) {
      this.commentTarget.value = this.commentRefusedTarget.value
    }
  }
}
