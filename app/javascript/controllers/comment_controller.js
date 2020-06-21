import {Controller} from "stimulus"

export default class extends Controller {
    static targets = ["textArea", "commentDiv"]

    addComment(event) {
        this.commentDivTarget.style.display = "block";
        if (event.target.id === "status-granted-conditional") {
            this.textAreaTarget.id = "comment_met";
            this.textAreaTarget.name = "decision[comment_met]";
        } else {
            this.textAreaTarget.id = 'comment_unmet';
            this.textAreaTarget.name = "decision[comment_unmet]";
        }
    }
}
