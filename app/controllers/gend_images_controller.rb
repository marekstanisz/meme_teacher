class GendImagesController < ApplicationController

  def new
    @gend_image = GendImage.new
    @gend_image.src_image = SrcImage.find_by_id_hash!(params[:src])
  end

  def index
    # Sort in database?
    @gend_images = current_user.gend_images.sort {
        |a, b| b.updated_at <=> a.updated_at }
  end

  def create
    src_image = SrcImage.find_by_id_hash!(params[:gend_image][:src_image_id])

    @gend_image = GendImage.new
    @gend_image.src_image = src_image

    @gend_image.captions << Caption.new(:text => params[:text1], :font => MemeCaptainWeb::Config::Font)
    @gend_image.captions << Caption.new(:text => params[:text2], :font => MemeCaptainWeb::Config::Font)

    if @gend_image.save
      redirect_to :action => :index
    else
      render :new
    end
  end

  def show
    gend_image = GendImage.find_by_id_hash!(params[:id])

    render :text => gend_image.image, :content_type => gend_image.content_type
  end

end
