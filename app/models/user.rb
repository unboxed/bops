# frozen_string_literal: true

class User < ApplicationRecord
  enum role: { assessor: 0, reviewer: 1, administrator: 2 }

  enum otp_delivery_method: { sms: 0, email: 1 }

  devise :recoverable, :two_factor_authenticatable, :recoverable, :timeoutable,
         :validatable, otp_secret_encryption_key: ENV["OTP_SECRET_ENCRYPTION_KEY"], request_keys: [:subdomains]

  has_many :planning_applications, dependent: :nullify
  has_many :audits, dependent: :nullify
  has_many :comments, dependent: :nullify
  belongs_to :local_authority, optional: false

  before_create :generate_otp_secret

  validates :mobile_number, phone_number: true
  validates :password, password_strength: { use_dictionary: true }, unless: ->(user) { user.password.blank? }
  validate :password_complexity

  scope :non_administrator, -> { where.not(role: "administrator") }

  class << self
    def menu(scope = User.all)
      users = scope.order(name: :asc).pluck(:name, :id)

      [["Unassigned", nil]].concat(users)
    end
  end

  def self.find_for_authentication(tainted_conditions)
    if tainted_conditions[:subdomains].present?
      local_authority = LocalAuthority.find_by(subdomain: tainted_conditions[:subdomains].first)
      tainted_conditions.delete(:subdomains)
      find_first_by_auth_conditions(tainted_conditions.merge(local_authority_id: local_authority.id))
    else
      find_first_by_auth_conditions(tainted_conditions)
    end
  end

  def assign_mobile_number!(number)
    update!(mobile_number: number)
  end

  def valid_otp_attempt?(otp_attempt)
    validate_and_consume_otp!(otp_attempt)
  end

  def send_otp(session_mobile_number)
    if send_otp_by_sms?
      number = mobile_number.presence || session_mobile_number
      TwoFactor::SmsNotification.new(number, current_otp).deliver!
    else
      UserMailer.otp_mail(self).deliver_now
    end
  end

  def send_otp_by_sms?
    otp_delivery_method == "sms"
  end

  private

  def generate_otp_secret
    self.otp_secret = self.class.generate_otp_secret
  end

  def password_complexity
    # Regexp extracted from https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a
    return if password.blank? || password =~ /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-])/

    errors.add :password, "complexity requirement not met. Your password must have: " \
                          "at least 8 characters; at least one symbol (for example, ?!£%); at least one capital letter."
  end

  ##
  # Decrypt and return the `encrypted_otp_secret` attribute which was used in
  # prior versions of devise-two-factor (4.0.2)
  # @return [String] The decrypted OTP secret
  # rubocop:disable Metrics/AbcSize
  def legacy_otp_secret
    return nil unless self[:encrypted_otp_secret]
    return nil unless self.class.otp_secret_encryption_key

    hmac_iterations = 2000 # a default set by the Encryptor gem
    key = self.class.otp_secret_encryption_key
    salt = Base64.decode64(encrypted_otp_secret_salt)
    iv = Base64.decode64(encrypted_otp_secret_iv)

    raw_cipher_text = Base64.decode64(encrypted_otp_secret)
    # The last 16 bytes of the ciphertext are the authentication tag - we use
    # Galois Counter Mode which is an authenticated encryption mode
    cipher_text = raw_cipher_text[0..-17]
    auth_tag =  raw_cipher_text[-16..]

    # this alrorithm lifted from
    # https://github.com/attr-encrypted/encryptor/blob/master/lib/encryptor.rb#L54

    # create an OpenSSL object which will decrypt the AES cipher with 256 bit
    # keys in Galois Counter Mode (GCM). See
    # https://ruby.github.io/openssl/OpenSSL/Cipher.html
    cipher = OpenSSL::Cipher.new("aes-256-gcm")

    # tell the cipher we want to decrypt. Symmetric algorithms use a very
    # similar process for encryption and decryption, hence the same object can
    # do both.
    cipher.decrypt

    # Use a Password-Based Key Derivation Function to generate the key actually
    # used for encryptoin from the key we got as input.
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, salt, hmac_iterations, cipher.key_len)

    # set the Initialization Vector (IV)
    cipher.iv = iv

    # The tag must be set after calling Cipher#decrypt, Cipher#key= and
    # Cipher#iv=, but before calling Cipher#final. After all decryption is
    # performed, the tag is verified automatically in the call to Cipher#final.
    #
    # If the auth_tag does not verify, then #final will raise OpenSSL::Cipher::CipherError
    cipher.auth_tag = auth_tag

    # auth_data must be set after auth_tag has been set when decrypting See
    # http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#method-i-auth_data-3D
    # we are not adding any authenticated data but OpenSSL docs say this should
    # still be called.
    cipher.auth_data = ""

    # #update is (somewhat confusingly named) the method which actually
    # performs the decryption on the given chunk of data. Our OTP secret is
    # short so we only need to call it once.
    #
    # It is very important that we call #final because:
    #
    # 1. The authentication tag is checked during the call to #final
    # 2. Block based cipher modes (e.g. CBC) work on fixed size chunks. We need
    #    to call #final to get it to process the last chunk properly. The output
    #    of #final should be appended to the decrypted value. This isn't
    #    required for streaming cipher modes but including it is a best practice
    #    so that your code will continue to function correctly even if you later
    #    change to a block cipher mode.
    cipher.update(cipher_text) + cipher.final
  end
  # rubocop:enable Metrics/AbcSize
end
