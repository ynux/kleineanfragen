class BundestagPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ORIGINATORS = /der Abgeordneten (.+?)(?:,\s+weiterer\s+Abgeordneter)?\s+und\s+der\s+Fraktion\s+(?:der\s+)?(.{0,30}?)\.?\n/m
  ORIGINATORS_GROUPS = /der Fraktionen\s+(?:der\s+)?([^\n]+)\n/m

  DIVIDER = /V\s*o\s*r\s*b\s*e\s*m\s*e\s*r\s*k\s*u\s*n\s*g/

  def extract_originators
    return nil if @contents.nil?
    people = []
    parties = []
    blacklist = ['weiterer Abgeordneter', 'weitrerer Abgeordneter']

    contents = @contents.split(DIVIDER, 2).try(:first)
    contents = @contents if contents.nil?
    contents.scan(ORIGINATORS).each do |m|
      m[0].split(',').each do |person|
        person = person.gsub(/\p{Z}/, ' ')
                 .gsub("\n", ' ')
                 .gsub(/\s+/, ' ')
                 .strip
                 .gsub(/\p{Other}/, '') # invisible chars & private use unicode
                 .sub(/^der\s/, '')
                 .sub(/\s\(.+\)$/, '') # remove city
                 .sub(/^Kleine\s+Anfrage\s+der\s+Abgeordneten\s+/, '') # duplicate prefix
                 .sub(/^Abgeordneten\s+/, '') # duplicate prefix
                 .sub(/\s*weiterer?\s+Abgeordneter\s*$/, '') # duplicate suffix
        people << person unless person.blank? || blacklist.include?(person)
      end
      party = m[1].gsub("\n", ' ')
              .strip
              .gsub(/\p{Other}/, '')
              .sub(/^der\s/, '')
              .sub(/\.$/, '')
              .sub(/\s*betreffend$/, '') # duplicate suffix
      parties << party
    end

    if people.empty? && parties.empty?
      @contents.scan(ORIGINATORS_GROUPS).each do |m|
        m[0].gsub(' und ', ',').split(',').each do |party|
          party = party.gsub(/\p{Z}/, ' ')
                  .gsub("\n", ' ')
                  .gsub(/\s+/, ' ')
                  .strip
                  .gsub(/\p{Other}/, '') # invisible chars & private use unicode
                  .sub(/^der\s/, '')
                  .sub(/\.$/, '')
          parties << party
        end
      end
    end

    { people: people, parties: parties }
  end
end