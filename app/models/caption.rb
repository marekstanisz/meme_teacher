class Caption < ActiveRecord::Base
  belongs_to :gend_image

  validates :text, presence: true

  before_save :default_values

  def default_values
    if font.blank?
      self.font = default_font
    end
  end

  def font_path
    "#{Rails.root}/fonts/#{font}"
  end

  def text_pos
    MemeCaptain::TextPos.new(text, top_left_x_pct, top_left_y_pct, width_pct, height_pct, :font => font_path)
  end

  private

  def default_font
    extended_ascii_only? ? MemeCaptainWeb::Config::DefaultFont : MemeCaptainWeb::Config::DefaultUnicodeFont
  end

  def extended_ascii_only?
    text.force_encoding('UTF-8').chars.find { |c| c.ord > 255 }.nil?
  end

  scope :position_order, -> { reorder('top_left_y_pct, top_left_x_pct') }

end
