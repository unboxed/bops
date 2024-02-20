import { Controller } from "@hotwired/stimulus"
import accessibleAutocomplete from 'accessible-autocomplete'

export default class extends Controller {
    static targets = ['lpcontainer', 'select', 'output']

    addArea(event) {
        event.preventDefault()
        this.setPolicyInput()
        document.querySelectorAll('form')[1].submit()
    }

    setPolicyInput() {
        const chosenPolicy = document.getElementById('local-policies').value;
        const hiddenField = document.getElementById('hidden-field');
        hiddenField.value = chosenPolicy;
    }

    connect() {
        let dataArrayElement = this.element.querySelector('[data-local-policies-array-value]')
        let dataArrayJson = dataArrayElement.getAttribute('data-local-policies-array-value')

        let policiesArray = JSON.parse(dataArrayJson)

        accessibleAutocomplete({
            element: document.querySelector('#lpcontainer'),
            id: 'local-policies',
            source: policiesArray,
            onConfirm: (query) => {
                this.onConfirm(query)
            },
            autoselect: false,
            confirmOnBlur: false,
        })
    }
    onConfirm(selected) {
        this.selected = selected
        const hiddenField = document.getElementById('hidden-field');
        hiddenField.value = this.selected;
    }
}
