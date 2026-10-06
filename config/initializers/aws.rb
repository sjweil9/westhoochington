begin
  Aws.config.update({
    region: 'us-east-2',
    credentials: Aws::Credentials.new(Rails.application.credentials.dig(:aws, :access_key_id), Rails.application.credentials.dig(:aws, :secret_access_key)),
                    })
rescue ActiveSupport::EncryptedFile::MissingKeyError, OpenSSL::Cipher::CipherError,
       ActiveSupport::MessageEncryptor::InvalidMessage => e
  # Credentials aren't decryptable on this machine (missing/mismatched master
  # key). Skip AWS config rather than failing boot — S3 features won't work
  # until the key is fixed.
  Rails.logger&.warn("[aws initializer] Skipping AWS config: #{e.class}")
end

if ENV['S3_BUCKET_NAME']
  S3_BUCKET = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_NAME'])
end

