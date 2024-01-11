const govukall = require("govuk-frontend")

govukall.Accordion.prototype.originalsetExpanded =
  govukall.Accordion.prototype.setExpanded
govukall.Accordion.prototype.setExpanded = function (expanded, $section) {
  this.originalsetExpanded(expanded, $section)
  if (typeof accordion_expanded === "function") {
    accordion_expanded()
  }
}

govukall.Accordion.prototype.storeState = function ($section) {}
govukall.Accordion.prototype.setInitialState = function ($section) {}

govukall.initAll()
