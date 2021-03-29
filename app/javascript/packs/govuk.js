var govukall = require("govuk-frontend/govuk/all")

govukall.Accordion.prototype.originalsetExpanded = govukall.Accordion.prototype.setExpanded
govukall.Accordion.prototype.setExpanded = function (expanded, $section) {
  this.originalsetExpanded(expanded, $section)
  if (typeof accordion_expanded == 'function') { 
    accordion_expanded(); 
  }  
}

govukall.initAll()

require.context('govuk-frontend/govuk/assets/images', true)
