defmodule Portfolio.CodeStyle do
  @moduledoc false

  @styles %{
    :text => "#e7e9db",
    :error => "#ef6155",
    :keyword => "bold #c678dd",
    :keyword_namespace => "#5bc4bf",
    :keyword_type => "bold #e06c75",
    :name => "#e7e9db",
    :name_attribute => "#06b6ef",
    :name_class => "bold #e06c75",
    :name_constant => "#ef6155",
    :name_decorator => "#5bc4bf",
    :name_exception => "#ef6155",
    :name_function => "#06b6ef",
    :name_namespace => "bold #e06c75",
    :name_other => "#06b6ef",
    :name_tag => "#5bc4bf",
    :name_variable => "#ef6155",
    :literal => "#f99b15",
    :string => "#48b685",
    :string_char => "#e7e9db",
    :string_doc => "#776e71",
    :string_escape => "#f99b15",
    :string_interpol => "#f99b15",
    :number => "#f99b15",
    :operator => "#5bc4bf",
    :punctuation => "#e7e9db",
    :comment => "#776e71",
    :generic_deleted => "#ef6155",
    :generic_emph => "italic",
    :generic_heading => "bold #e7e9db",
    :generic_inserted => "#48b685",
    :generic_prompt => "bold #776e71",
    :generic_strong => "bold",
    :generic_subheading => "bold #5bc4bf"
  }

  alias Makeup.Styles.HTML.Style

  @style_struct Style.make_style(
                  short_name: "code_style_dark",
                  long_name: "Code Style",
                  background_color: "transparent",
                  highlight_color: "#4f424c",
                  styles: @styles
                )

  def style() do
    @style_struct
  end
end
