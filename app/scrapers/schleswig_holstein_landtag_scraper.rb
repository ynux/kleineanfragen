module SchleswigHolsteinLandtagScraper
  BASE_URL = 'http://lissh.lvn.parlanet.de'

  def self.extract_table(page)
    page.search('//center')[0].next.next.next
  end

  def self.extract_blocks(table)
    table.search('//tr[contains(@class, "tabcol")][not(@class="tabcol2")]')
  end

  def self.extract_title(block)
    block.child.next.child.next.content
  end

  def self.answer?(block)
    block.content.scan(/in Vorbereitung/)[0].nil? && !block.content.scan(/Kleine Anfrage.+und Antwort/)[0].nil?
  end

  def self.get_date_from_detail_line(line)
    matches = get_matches_for_date_pattern(line)
    return nil if matches.nil?
    Date.parse(matches[0])
  end

  def self.get_matches_for_date_pattern(line)
    /\d{2}\.\d{2}\.\d{4}/.match line
  end

  def self.extract_meta(block)
    line = block.child.next.child.next.next.next.content
    match = line.match(/Kleine\s+Anfrage\s+(.*)\s*und\s+Antwort\s+(.+)\s+([\d\.]+)\s+Drucksache/)
    return nil if match.nil?
    published_at = Date.parse(match[3])
    originators = match[1].strip
    ministry = match[2].strip
    # special case for broken records
    if originators.blank? && !ministry.blank?
      originators = ministry
      ministry = nil
    end
    originators = NamePartyExtractor.new(originators).extract
    {
      ministries: [ministry].reject(&:nil?),
      originators: originators,
      published_at: published_at
    }
  end

  def self.extract_detail_line(block)
    table_row = block
    second_cell = table_row.children[1]
    second_cell.child.next.next.next.content
  end

  def self.extract_major_paper(block)
    full_reference = extract_full_reference block
    legislative_term, reference = full_reference.split '/'
    line = extract_detail_line block
    published_at = get_date_from_detail_line line
    return nil if published_at.nil?
    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
      title: extract_title(block),
      url: extract_url(block),
      published_at: published_at,
      is_answer: true,
      answerers: { ministries: ['Landesregierung'] }
    }
  end

  def self.extract_minor_paper(block)
    return nil if !answer?(block)
    full_reference = extract_full_reference(block)
    meta = extract_meta(block)
    fail "SH [#{full_reference}]: missing meta data" if meta.nil?
    url = extract_url(block)
    legislative_term, reference = full_reference.split('/')
    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      published_at: meta[:published_at],
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      title: extract_title(block),
      url: url,
      originators: meta[:originators],
      is_answer: true,
      answerers: { ministries: meta[:ministries] }
    }
  end

  def self.extract_full_reference(block)
    block.child.next.child.next.next.next.next.content
  end

  def self.extract_url(block)
    block.child.next.child.next.next.next.next.attributes['href'].value
  end

  def self.major?(block)
    line = extract_detail_line block
    line.gsub(/\p{Z}+/, ' ').strip.start_with?('Antwort')
  end

  def self.update_major_details(paper, page)
    block = extract_detail_block page
    line = extract_originator_line block
    originators = NamePartyExtractor.new(line).extract
    paper[:originators] = originators
    paper
  end

  def self.extract_originator_line(detail_table)
    detail_table.children.each do |child|
      child.content.split("\n").each do |line|
        line = line.gsub(/\p{Z}+/, ' ').strip
        if line.start_with?('Große Anfrage')
          return line.sub('Große Anfrage', '').strip
        end
      end
    end
  end

  def self.update_minor_details(paper, _page)
    # return as is because the page does not grant new information
    paper
  end

  def self.extract_detail_block(page)
    page.search('//table[@summary="Report"]/tr[1]/td[2]/table')
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/cgi-bin/starfinder/0?path=lisshfl.txt&id=fastlink&pass=&search='

    def supports_streaming?
      true
    end

    def scrape
      papers = []
      # minor interpellations
      search_url = SEARCH_URL + CGI.escape('WP=' + @legislative_term.to_s + ' AND dtyp=kleine')
      streaming = block_given?
      m = mechanize
      mp = m.get search_url

      table = SchleswigHolsteinLandtagScraper.extract_table(mp)
      SchleswigHolsteinLandtagScraper.extract_blocks(table).each do |block|
        begin
          paper = SchleswigHolsteinLandtagScraper.extract_minor_paper(block)
        rescue => e
          logger.warn e
          next
        end
        next if paper.nil?
        if streaming
          yield paper
        else
          papers << paper
        end
      end
      # major /cgi-bin/starfinder/0?path=lisshfl.txt&id=FASTLINK&pass=&search=(WP=17%20AND%20DTYPF,DTYP2F=(antwort))
      search_url = SEARCH_URL + CGI.escape('WP=' + @legislative_term.to_s + ' AND DTYPF,DTYP2F=(antwort)')
      mp = m.get search_url

      table = SchleswigHolsteinLandtagScraper.extract_table(mp)
      SchleswigHolsteinLandtagScraper.extract_blocks(table).each do |block|
        begin
          paper = SchleswigHolsteinLandtagScraper.extract_major_paper(block)
        rescue => e
          logger.warn e
          next
        end
        if streaming
          yield paper
        else
          papers << paper
        end
      end
      papers unless streaming
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/cgi-bin/starfinder/0?path=lisshfl.txt&id=FASTLINK&pass=&search='

    def scrape
      search_url = SEARCH_URL + '(' + CGI.escape('WP=' + @legislative_term.to_s + ' AND DART=D AND DNR=' + @reference.to_s) + ')'
      m = mechanize
      mp = m.get search_url
      table = SchleswigHolsteinLandtagScraper.extract_table(mp)
      block = SchleswigHolsteinLandtagScraper.extract_blocks(table).first
      extract_paper(block, mp)
    end

    def extract_paper(block, mp)
      if SchleswigHolsteinLandtagScraper.major?(block)
        paper = SchleswigHolsteinLandtagScraper.extract_major_paper(block)
        mp = mp.link_with(:text => /Vorgang/).click
        return SchleswigHolsteinLandtagScraper.update_major_details(paper, mp)
      end
      paper = SchleswigHolsteinLandtagScraper.extract_minor_paper(block)
      SchleswigHolsteinLandtagScraper.update_minor_details(paper, mp)
    end
  end
end