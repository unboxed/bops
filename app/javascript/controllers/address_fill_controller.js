import { Controller } from "@hotwired/stimulus"
import accessibleAutocomplete from 'accessible-autocomplete'
import { ajax } from "@rails/ujs"

export default class extends Controller {
  connect() {
    accessibleAutocomplete({
      element: document.querySelector('#address-autocomplete-container'),
      id: 'address-autocomplete', // To match it to the existing <label>.
      source: (query, populateResults)=> {
        let results = []
        ajax({
          type: 'get',
          url: `https://api.os.uk/search/places/v1/find?maxresults=20&query=${query}&key=${process.env.OS_VECTOR_TILES_API_KEY}`,
          success: (data) => {
            for (var i of data.results) { 
              results.push(i.DPA.ADDRESS) 
            }
            populateResults(results)
          },
        })
      },
      minLength: 3
    })
  }
}
