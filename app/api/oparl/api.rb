#
# Implementation of OParl 1.0 for kleineAnfragen
# Spec: https://oparl.org/spezifikation/
#
module OParl
  class API < Grape::API
    version 'v1', using: :path, cascade: false
    prefix :oparl
    content_type :json, 'application/json; charset=utf-8'
    format :json
    default_format :json

    include OParl::Current
    include OParl::Pagination

    # combine namespace and route_param to shorten indentation
    def self.namespace_route(key)
      namespace key do
        route_param key do
          yield
        end
      end
    end

    namespace_route :person do
      before do
        # called @xperson, because @person confuses grape
        @xperson = Person.friendly.find(params[:person])
      end

      get do
        present @xperson, with: OParl::Entities::Person
      end
    end

    namespace_route :body do
      before do
        # called @xbody, because @body confuses grape
        @xbody = Body.where('lower(state) = ?', params[:body]).try(:first)
        error! :not_found, 404 if @xbody.nil?
      end

      namespace_route :organization do
        before do
          @org = @xbody.organizations.where(slug: params[:organization]).try(:first)
          error! :not_found, 404 if @org.nil?
        end

        get do
          present @org, with: OParl::Entities::Organization, body: @xbody
        end
      end

      paginate
      get :organizations do
        orgs = @xbody.organizations.order(id: :asc)
        present paginate(orgs), root: 'data', with: OParl::Entities::Organization, body: @xbody
      end

      paginate
      get :people do
        people = @xbody.people.order(id: :asc)
        present paginate(people), root: 'data', with: OParl::Entities::Person
      end

      paginate
      get :papers do
        papers = @xbody.papers.order(id: :asc)
        present paginate(papers), root: 'data', with: OParl::Entities::Paper
      end

      namespace_route :term do
        before do
          @legislative_term = @xbody.legislative_terms.where(term: params[:term]).try(:first)
          error! :not_found, 404 if @legislative_term.nil?
        end

        namespace_route :paper do
          before do
            # called @xpaper, because @paper confuses grape
            @xpaper = @xbody.papers.where(legislative_term: params[:term], reference: params[:paper]).try(:first)
            error! :not_found, 404 if @xpaper.nil?
          end

          namespace_route :file do
            # file is currently a paper too, until we support multiple files per paper.
            get do
              error! :not_found, 404 if params[:file] != '1'
              present @xpaper, with: OParl::Entities::File, type: :file_full
            end
          end

          get do
            present @xpaper, with: OParl::Entities::Paper
          end
        end

        get do
          present @legislative_term, with: OParl::Entities::LegislativeTerm, type: :lt_full
        end
      end

      paginate
      get :terms do
        terms = @xbody.legislative_terms
        present paginate(terms), root: 'data', with: OParl::Entities::LegislativeTerm, type: :lt_full
      end

      get do
        present @xbody, with: OParl::Entities::Body
      end
    end

    paginate
    get :bodies do
      bodies = Body.order(state: :asc)
      present paginate(bodies), root: 'data', with: OParl::Entities::Body
    end

    get '/', as: :oparl_v1_system do
      sys = {
        contact: Rails.application.config.x.email_support
      }
      present sys, with: OParl::Entities::System
    end

    # 404 handler
    route :any, '*path', as: :oparl_v1_catchall do
      error! 'Not Found', 404
    end
  end
end