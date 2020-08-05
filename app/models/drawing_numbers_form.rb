class DrawingNumbersForm
  include ActiveModel::Model
  include ActiveModel::Validations

  def initialize(drawings_to_update, drawings_numbers_hash)
    @drawings_to_update = drawings_to_update
    @drawings_numbers_hash = drawings_numbers_hash
  end

  def update_all


    if @drawings_numbers_hash.values.select(&:blank?)
      errors[:base] << "One or more numbers not supplied"

      errors[:drawing][a_drawing_id]
    else
      @drawings_to_update.update_all(drawings_numbers_hash)
    end

    errors.none?
  end
end

# controller

form = DrawingNumbersForm.new(@planning_application.drawings.has_proposed_tag, something_params)

if form.update_all
  redirect_to planning_application_show_url
else
  render :edit_numbers
end
