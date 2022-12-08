# frozen_string_literal: true

module AccordionSections
  class NotesComponent < AccordionSections::BaseComponent
    private

    def link_text
      first_note.present? ? t(".add_and_view") : t(".add_a_note")
    end

    def first_note_entry
      truncate(first_note.entry, length: 200)
    end

    def first_note
      @first_note ||= planning_application.notes.first
    end
  end
end
