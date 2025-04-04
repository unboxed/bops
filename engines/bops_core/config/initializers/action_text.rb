# frozen_string_literal: true

ActiveSupport.on_load :action_text_content do
  ActionText::ContentHelper.allowed_tags = %w[
    div h1 blockquote p ol ul li strong em sub sup b i u a figure figcaption img
  ]
end
