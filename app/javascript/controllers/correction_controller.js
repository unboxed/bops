import {Controller} from "stimulus"

export default class extends Controller {
    static targets = ["textArea", "correctionDiv"]

    toggleCorrection(event) {
        if (event.target.id === "reviewer-disagrees-conditional") {
            this.correctionDivTarget.style.display = "block";
        } else {
            this.correctionDivTarget.style.display = "none";
        }
    }
}
