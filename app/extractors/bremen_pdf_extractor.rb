class BremenPDFExtractor
  def initialize(paper)
    @contents = paper.contents
    @doctype = paper.doctype
    @title = paper.title
  end

  ORIGINATORS = /\d+.+[\?\.\\](?:\n\n(.+?)\s+und\s+Fraktion\s+[^\n]+)(?:\n\n(.+?)\s+und\s+Fraktion\s+[^\n]+)*.+(?:Antwort\s+des\s+Senats|Der\s+Senat\s+beantwortet)/m
  FACTIONS_WITH_DATE = /Antwort\s+des\s+Senats\s+auf\s+die\s+\S+\s+Anfrage\s+der([^\n]+)\s+vom\s+\d+/m
  FACTIONS = /Antwort\s+des\s+Senats\s+auf\s+die\s+\S+\s+Anfrage\s+der(.+)/m

  def extract_originators
    return nil if @contents.nil? || @doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
    people = []
    parties = extract_originator_parties

    m = @contents.match(ORIGINATORS)
    if !m.nil?
      originators = m[1].split(',')
      originators.concat m[2].split(',') unless m[2].nil?
      originators.each do |person|
        person = person.gsub(/\p{Z}/, ' ').gsub("\n", ' ').gsub(/\s+/, ' ').gsub(/\p{Other}/, '').strip
        people << person unless person.blank?
      end
    end
    { people: people, parties: parties }
  end

  def extract_originator_parties
    if @contents.include?('Anfrage der Fraktion')
      faction_match = @contents.match(FACTIONS_WITH_DATE)
      if !faction_match.nil?
        factions = NamePartyExtractor.new(faction_match[1], NamePartyExtractor::FRACTION).extract
        return factions[:parties]
      end

      faction_match = @contents.match(FACTIONS)
      if faction_match.nil?
        return []
      end

      factions = faction_match[1]
      shortened_title = @title[0..30]
      if faction_match[1].include?(shortened_title)
        factions = factions[0..(factions.index(shortened_title) - 1)].gsub("\n", ' ')
      end
      factions = NamePartyExtractor.new(factions, NamePartyExtractor::FRACTION).extract
      factions[:parties]
    end
  end
end
