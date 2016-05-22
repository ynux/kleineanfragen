require 'timeout'

class ContainsTableJob < PaperJob
  queue_as :meta

  def perform(paper)
    logger.info "Looking for Tables in Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    result = self.class.recognize(paper.contents)

    reason = result[:groups].map(&:to_s).join(',')

    logger.info "Probability of Table(s) in Paper [#{paper.body.state} #{paper.full_reference}]: #{result[:probability]} (#{reason})"

    paper.contains_table = result[:probability] >= 1
    paper.save
  end

  def self.recognize(contents)
    probability = 0.0
    groups = []

    # Hint 1: "<synonym für nachfolgende> Tabelle"
    if contents.match(/(?:[bB]eiliegende|beigefügte|anliegende|[Ff]olgende|vorstehende|nachstehende|unten stehende)[nr]? Tabelle/)
      probability += 1
      groups << :synonym
    end

    # Hint 2: "Tabelle \d zeigt", "siehe Tabelle \d", "siehe Tabelle in Anlage"
    if contents.match(/Tabelle \d zeigt/) || contents.match(/siehe Tabelle (?:\d|in Anlage)/)
      probability += 1
      groups << :table_shows
    end

    # Hint 3: (Tabelle 1) ... (Tabelle 2)
    if contents.match(/\(Tabelle \d\)/)
      probability += 1
      groups << :table_parenthesized
    end

    # Hint 4: "die Tabellen 1 bis 4"
    if contents.match(/[Dd]ie Tabellen \d bis \d/)
      probability += 1
      groups << :tables_num
    end

    # Hint 5: "\nTabelle 2:\n"
    if contents.match(/\nTabelle \d:\n/)
      probability += 1
      groups << :table_num
    end

    begin
      Timeout::timeout(5) do
        # Hint 6: \d\n\d\n\d\n...
        #m = contents.scan(/\p{Zs}(\d[\p{Zs}\d]+\n\d[\p{Zs}\d]+)+/m)
        m = contents.scan(/(\d[\p{Zs}\d]+\n[\d][\p{Zs}\d]+)+/m)
        if m
          probability += 0.5 * m.size
          groups << :looks_like_table_newlines
        end
      end
    rescue => e
      # ignore failure
    end

    # Hint 7: Anlage 3 Tabelle 1, Anlage / Tabelle 1
    if contents.match(/Anlage\s+[\d\/]+\s+Tabelle\s+\d+/m)
      probability += 1
      groups << :attachment_table
    end

    begin
      Timeout::timeout(5) do
        # Hint 8: "\nAAA 10,1 10,2 10,3\nBBB 20 21,1 -1.022,2"
        m = contents.scan(/\n([\p{Zs}\S]+?\p{Zs}+(\-?(?>(?:\d{1,3}(?>(?:\.\d{3}))*(?>(?:,\d+)?|\d*\.?\d+))\p{Zs}*)+))\n/m)
        if m
          m.each do |match|
            unless match.first.strip == match.second.strip || match.first.strip.start_with?('vom') || match.first.match('\d{2}\.\d{2}\.\d{4}')
              probability += 0.5
              groups << :looks_like_table_values
            end
          end
        end
      end
    rescue => e
      # ignore failure
    end

    {
      probability: probability,
      groups: groups.uniq
    }
  end
end