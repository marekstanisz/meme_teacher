# encoding: UTF-8
# frozen_string_literal: true

# Generated (meme) image model.
class GendImage < ActiveRecord::Base
  include HasImageConcern
  include IdHashConcern

  belongs_to :src_image, counter_cache: true
  has_one :gend_thumb
  has_many :captions, -> { order :id }
  belongs_to :user

  accepts_nested_attributes_for :captions, reject_if:
      proc { |attrs| attrs['text'.freeze].blank? }

  # This email field is a negative captcha. If form bots fill it in,
  # validation will fail.
  attr_accessor :email

  before_validation :set_derived_image_fields
  validates :email, length: { maximum: 0 }

  after_commit :create_jobs, on: :create

  def create_jobs
    GendImageProcessJob.new(id).delay(queue: queue).perform
  end

  def meme_text
    captions.position_order.map(&:text).join(' '.freeze)
  end

  def meme_text_header
    Rails.cache.fetch("#{cache_key}/meme_text_header") do
      trim_header(
        captions.map { |c| Rack::Utils.escape(c.text) }.join('&'.freeze))
    end
  end

  def headers
    {
      'Content-Length'.freeze => size,
      'Content-Type'.freeze => content_type,
      'Meme-Text'.freeze => meme_text_header
    }
  end

  def self.for_user(user, query, page)
    if user.try(:is_admin)
      without_image.includes(:gend_thumb).caption_matches(query)
                   .most_recent.page(page)
    else
      without_image.includes(:gend_thumb).caption_matches(query)
                   .publick.active.finished.most_recent.page(page)
    end
  end

  scope :active, -> { where is_deleted: false }

  scope :owned_by, ->(user) { where user_id: user.try(:id) }

  scope :most_recent, lambda { |limit = 1|
    order(:updated_at).reverse_order.limit(limit)
  }

  scope :finished, -> { where work_in_progress: false }

  scope :publick, -> { where private: false }

  scope :caption_matches, lambda { |query|
    prepared_query = query.try(:strip).try(:downcase)
    joins(:captions).where(
      'LOWER(captions.text) LIKE ?'.freeze, "%#{prepared_query}%").uniq if \
      prepared_query
  }

  private

  def trim_header(header)
    return header if header.size <= 8181
    # varnish checks total header size (key + value) <= 8k,
    # 8181 = 8192 - 'Meme-Text: '.size
    result = header.slice(0, 8181)
    result.slice!(8179..-1) if result[-2] == '%'.freeze
    result
  end

  def queue
    case src_image.size
    when 0.kilobytes...100.kilobytes
      :gend_image_process_small
    when 100.kilobytes...1.megabyte
      :gend_image_process_medium
    when 1.megabyte...10.megabytes
      :gend_image_process_large
    else
      :gend_image_process_shitload
    end
  end
end
