defmodule CribbexWeb.Helpers do
  @extension ".png"
  def card_image_path(%{code: code}) do
    CribbexWeb.Endpoint.static_path("/images/#{code}#{@extension}")
  end

  @back_color "blue"
  def card_back_path do
    CribbexWeb.Endpoint.static_path("/images/#{@back_color}_back#{@extension}")
  end
end
