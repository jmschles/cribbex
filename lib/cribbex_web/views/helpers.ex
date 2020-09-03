defmodule CribbexWeb.Helpers do
  def card_image_path(%{image_name: filename}) do
    CribbexWeb.Endpoint.static_path("/images/" <> filename)
  end

  @back_color "blue"
  def card_back_path do
    CribbexWeb.Endpoint.static_path("/images/#{@back_color}_back.png")
  end
end
