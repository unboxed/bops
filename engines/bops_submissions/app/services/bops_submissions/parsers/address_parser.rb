# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class AddressParser < BaseParser
      FIELD_MAP = {
        "Planning Portal" => {
          uprn: ->(p) { p["bs7666UniquePropertyReferenceNumber"].to_s },
          address_1: ->(p) { [p["bs7666Number"], p["bs7666StreetDescription"]].compact_blank.join(", ") },
          address_2: ->(p) { p["bs7666Description"] },
          town: ->(p) { p["bs7666Town"] },
          postcode: ->(p) { p["bs7666PostCode"] },
          coordinates: ->(p) { {map_east: p["bs7666X"], map_north: p["bs7666Y"]} }
        },
        "PlanX" => {
          uprn: ->(p) { p[:uprn] },
          address_1: ->(p) {
            sao = p.values_at(:sao, :saoEnd).compact_blank.join("–")
            pao = p.values_at(:pao, :paoEnd).compact_blank.join("–")
            [sao, pao, p[:street]].compact_blank.join("–")
          },
          address_2: ->(p) { p[:organisation] },
          town: ->(p) { p[:town] },
          postcode: ->(p) { p[:postcode] },
          coordinates: ->(p) do
            factory = RGeo::Geographic.spherical_factory(srid: 4326)
            {lonlat: factory.point(p[:longitude].to_f, p[:latitude].to_f)}
          end
        }
      }.freeze

      def parse
        mapper = FIELD_MAP.fetch(source) { raise "Unknown source: #{source.inspect}" }
        {
          uprn: mapper[:uprn].call(params),
          address_1: mapper[:address_1].call(params),
          address_2: mapper[:address_2].call(params),
          town: mapper[:town].call(params),
          postcode: mapper[:postcode].call(params),
          **mapper[:coordinates].call(params)
        }
      end
    end
  end
end
