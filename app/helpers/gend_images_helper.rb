# encoding: UTF-8
# frozen_string_literal: true

# Build urls for generated images.
module GendImagesHelper
  def gend_image_url_for(gend_image)
    url_for(
      controller: '/gend_images'.freeze,
      action: :show,
      id: gend_image.id_hash,
      format: gend_image.format,
      host: MemeCaptainWeb::Config::GEND_IMAGE_HOST || request.host
    )
  end
end
