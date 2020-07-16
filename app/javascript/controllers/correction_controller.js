import {Controller} from "stimulus"

export default class extends Controller {
    static targets = ["textArea", "correctionDiv"]

    addCorrection(event) {
        this.correctionDivTarget.style.display = "block";
        if (event.target.id === "status-granted-conditional") {
            this.textAreaTarget.id = "correction";
            this.textAreaTarget.name = "decision[correction]";
        }
    }
}
