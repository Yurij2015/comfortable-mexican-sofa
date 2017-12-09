class Comfy::Cms::Site < ActiveRecord::Base
  self.table_name = "comfy_cms_sites"

  # -- Relationships -----------------------------------------------------------
  with_options dependent: :destroy do |site|
    site.has_many :layouts
    site.has_many :pages
    site.has_many :snippets
    site.has_many :files
    site.has_many :categories
  end

  # -- Callbacks ---------------------------------------------------------------
  before_validation :assign_identifier,
                    :assign_hostname,
                    :assign_label,
                    :clean_path

  # -- Validations -------------------------------------------------------------
  validates :identifier,
    presence:   true,
    uniqueness: true,
    format:     {with: /\A\w[a-z0-9_-]*\z/i}
  validates :label,
    presence:   true
  validates :hostname,
    presence:   true,
    uniqueness: {scope: :path},
    format:     {with: /\A[\w\.\-]+(?:\:\d+)?\z/}

  # -- Class Methods -----------------------------------------------------------
  # returning the Comfy::Cms::Site instance based on host and path
  def self.find_site(host, path = nil)
    return Comfy::Cms::Site.first if Comfy::Cms::Site.count == 1
    cms_site = nil


    public_cms_path = ComfortableMexicanSofa.configuration.public_cms_path
    path.gsub!(/\A#{public_cms_path}/, "") unless path.nil? || public_cms_path == "/"

    Comfy::Cms::Site.where(hostname: real_host_from_aliases(host)).each do |site|
      if site.path.blank?
        cms_site = site
      elsif "#{path.to_s.split('?')[0]}/" =~ /^\/#{Regexp.escape(site.path.to_s)}\//
        cms_site = site
        break
      end
    end
    cms_site
  end

  # -- Instance Methods --------------------------------------------------------
  def url(relative: false)
    public_cms_path = ComfortableMexicanSofa.config.public_cms_path || "/"
    host = "//#{hostname}"
    path = ["/", public_cms_path, self.path].compact.join("/").squeeze("/").chomp("/")
    relative ? path.presence : [host, path].join
  end

protected

  def self.real_host_from_aliases(host)
    if aliases = ComfortableMexicanSofa.config.hostname_aliases
      aliases.each do |alias_host, aliases|
        return alias_host if aliases.include?(host)
      end
    end
    host
  end

  def assign_identifier
    self.identifier = identifier.blank?? hostname.try(:parameterize) : identifier
  end

  def assign_hostname
    self.hostname ||= identifier
  end

  def assign_label
    self.label = label.blank?? identifier.try(:titleize) : label
  end

  def clean_path
    self.path ||= ""
    self.path.squeeze!("/")
    self.path.gsub!(/\/$/, "")
    self.path = nil if self.path.blank?
  end
end
