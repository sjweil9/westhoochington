Aws.config.update({
  region: 'us-east-2',
  credentials: Aws::Credentials.new(Rails.application.credentials.dig(:aws, :access_key_id), Rails.application.credentials.dig(:aws, :secret_access_key)),
                  })

if ENV['S3_BUCKET_NAME']
  S3_BUCKET = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_NAME'])
end

