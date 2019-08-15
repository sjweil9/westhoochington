class Podcast < ApplicationRecord
  belongs_to :user

  validates :week, numericality: { only_integer: true }
  validates :year, numericality: { only_integer: true }
  validates :title, length: { in: 1..50, message: 'Keep it between 1-50 characters you greedy fuck.' }
  validates :file_path, presence: true

  (2015..Date.today.year).each do |yr|
    define_method("#{yr}?") { year.to_i == yr.to_i }
  end

  def download_url
    object = S3_BUCKET.object(file_path.scan(/uploads*.+/).first)
    object.exists? ? object.presigned_url(:get).to_s : nil
  end
end
