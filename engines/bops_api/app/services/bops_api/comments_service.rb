# # frozen_string_literal: true

# module BopsApi
#   module Application
#     class SearchService
#       def initialize(scope, params)
#         @scope = scope
#         @params = params
#         @query = params[:q]
#       end

#       attr_reader :scope, :params, :query

#       def call
#         Pagination.new(scope: search, params:).paginate
#       end

#       private

#       def search
#         return scope if query.blank?

#         search_reference.presence || search_address.presence || search_description
#       end

#       def search_reference
#         scope.where(
#           "LOWER(reference) LIKE ?",
#           "%#{query.downcase}%"
#         )
#       end

#       def search_description
#         scope.select(sanitized_select_sql)
#           .where(where_sql, query_terms)
#           .order(rank: :desc)
#       end

#       def search_postcode
#         scope.where(
#           "LOWER(replace(postcode, ' ', '')) = ?",
#           query.gsub(/\s+/, "").downcase
#         )
#       end

#       def search_address
#         return search_address_results unless postcode_query?

#         postcode_results = search_postcode
#         postcode_results.presence || search_address_results
#       end

#       def search_address_results
#         scope.where("address_search @@ to_tsquery('simple', ?)", query.split.join(" & "))
#       end

#       def sanitized_select_sql
#         ActiveRecord::Base.sanitize_sql_array([select_sql, query_terms])
#       end

#       def select_sql
#         "planning_applications.*,
#           ts_rank(
#             to_tsvector('english', description),
#             to_tsquery('english', ?)
#           ) AS rank"
#       end

#       def where_sql
#         "to_tsvector('english', description) @@ to_tsquery('english', ?)"
#       end

#       def query_terms
#         @query_terms ||= query.split.join(" | ")
#       end

#       def postcode_query?
#         query.match?(/^(GIR\s?0AA|[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2})$/i)
#       end
#     end
#   end
# end

# frozen_string_literal: true

module BopsApi
  module Application
    class CommentsService
      def initialize(planning_application)
        @planning_application = planning_application
        puts @planning_application "trelelele"
      end

      # def consultation(planning_application_id)
      #   consultations do con 
      # end

      # def call!
      #   files.each do |file|
      #     url = file["name"]
      #     tags = file["type"].flat_map { |type| Array(type["value"]) }
      #     description = file["description"]

      #     upload(planning_application, user, url, tags, description)
      #   end
      # end

      # private

      # attr_reader :planning_application, :user, :files

      # def upload(planning_application, user, url, tags, description)
      #   if user.file_downloader.blank?
      #     raise Errors::FileDownloaderNotConfiguredError, "Please configure the file downloader for API user '#{user.id}'"
      #   end

        # file = user.file_downloader.get(url: url, from_production: planning_application.from_production?)
        # name = URI.decode_uri_component(File.basename(URI.parse(url).path))

        # planning_application.documents.create! do |document|
        #   document.tags = tags
        #   document.applicant_description = description
        #   document.file.attach(io: file.open, filename: name)

        #   document_checklist = planning_application.document_checklist

        #   tags.each do |tag|
        #     next if tag.blank?
        #     next unless (item = document_checklist.document_checklist_items.find_by(tags: tag))

        #     document.document_checklist_items_id = item.id
        #   end
        # end
      # end
    end
  end
end
