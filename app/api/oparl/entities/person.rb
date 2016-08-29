module OParl
  module Entities
    class Person < Grape::Entity
      expose(:id) { |person| OParl::Routes.oparl_v1_person_url(person: person.slug) }
      expose(:type) { |_| 'https://schema.oparl.org/1.0/Person' }

      expose(:body) { |person| OParl::Routes.oparl_v1_body_url(body: person.latest_body.key) }

      expose :name

      # expose(:web) { |person| Rails.application.routes.url_helpers.person_url(person) } # equivalent in html

      expose(:created) { |obj| obj.created_at }
      expose(:modified) { |obj| obj.updated_at }
    end
  end
end