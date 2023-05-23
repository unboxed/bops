// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("@rails/activestorage").start()

import "@opensystemslab/map"

import accessibleAutocomplete from 'accessible-autocomplete'
import { ajax } from "@rails/ujs"

window.onload = (function(){ 
  accessibleAutocomplete({
    element: document.querySelector('#address-autocomplete-container'),
    id: 'address-autocomplete', // To match it to the existing <label>.
    source: (query, populateResults)=> {
      let results = []
      ajax({
        type: 'get',
        url: `https://api.os.uk/search/places/v1/find?maxresults=20&query=${query}&key=`,
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

})

import "./controllers"
