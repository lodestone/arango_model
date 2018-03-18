class IdGenerator
  def self.generate
    UUID.random(Random::Secure).to_s
  end
end
