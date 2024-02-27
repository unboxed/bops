import {Controller} from "@hotwired/stimulus"
import accessibleAutocomplete from 'accessible-autocomplete'

export default class extends Controller {
    static targets = ['considerations-container', 'select', 'output']

    addArea(event) {
        event.preventDefault()
        this.setPolicyInput()
        document.querySelector('form').submit()
    }

    setPolicyInput() {
        const chosenPolicy = document.getElementById('local-policies').value
        const manualInput = document.getElementById('manual-policy-input').value
        const hiddenField = document.getElementById('hidden-field')

        if (chosenPolicy !== '') {
            hiddenField.value = chosenPolicy
        } else {
            hiddenField.value = manualInput
        }
    }

    connect() {
        const dataArrayElement = this.element.querySelector('[data-local-policies-array-value]')
        const dataArrayJson = dataArrayElement.getAttribute('data-local-policies-array-value')

        const policiesArray = JSON.parse(dataArrayJson)

        accessibleAutocomplete({
            element: document.querySelector('#considerations-container'),
            id: 'local-policies',
            source: policiesArray,
            onConfirm: (query) => {
                this.onConfirm(query)
            },
            autoselect: false,
            confirmOnBlur: false,
            showAllValues: true,
        })
    }

    onConfirm(selected) {
        this.selected = selected
        const hiddenField = document.getElementById('hidden-field');
        hiddenField.value = this.selected;
    }
}
