class SrcImageController < ApplicationController

  def new
    @src_image = SrcImage.new
  end

  def index
  end

  def create
    @src_image = SrcImage.new(params[:src_image])

    if params[:src_image][:image]
      @src_image.image = params[:src_image][:image].read
    end

    if @src_image.save
      redirect_to({ :action => :index }, {
        :notice => 'Source image created.' })
    else
      render :new
    end
  end

  def show
    src_image = SrcImage.find(params[:id])

    render :text => src_image.image, :content_type => src_image.content_type
  end

end