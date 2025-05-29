# frozen_string_literal: true

module NationalGrid
  extend self

  # All the values and formula are from the Ordnance Survey publication:
  # A guide to coordinate systems in Great Britain
  # https://www.ordnancesurvey.co.uk/docs/support/guide-coordinate-systems-great-britain.pdf

  # Scale factor on the central meridian for the Transverse Mercator projection
  # https://en.wikipedia.org/wiki/Transverse_Mercator_projection
  F0 = 0.9996012717

  # True origin of the National Grid projection (from section A.2)
  LAT0 = 0.8552113334772214
  LNG0 = -0.03490658503988659

  # Map coordinates of the true origin (from section A.2)
  E0 = 400_000.0
  N0 = -100_000.0

  # Precision for iterative calculations
  PRECISION = 1e-8

  # Helmert transformation parameters (from section 6.6)
  WGS84_TO_OSGB36 = {
    tx: -446.4480, ty:  125.1570, tz: -542.0600,
    rx: -0.1502, ry:   -0.2470, rz:   -0.8421,
    s: 20.4894
  }.freeze

  OSGB36_TO_WGS84 = {
    tx: 446.4480, ty: -125.1570, tz:  542.0600,
    rx: 0.1502, ry:    0.2470, rz:    0.8421,
    s: -20.4894
  }.freeze

  # Ellipsoid dimensions
  WGS84 = [6_378_137.0, 6_356_752.3142].freeze
  OSGB36 = [6_377_563.396, 6_356_256.909].freeze

  include Math

  # Based on the formula in C.2
  def os_ng_to_wgs84(easting, northing)
    a, b = OSGB36
    e2 = ((a**2) - (b**2)) / (a**2)
    n = (a - b) / (a + b)

    lat = ((northing - N0) / a * F0) + LAT0
    m = mercator(lat, n, b)

    10.times do
      lat = ((northing - N0 - m) / a * F0) + lat
      m = mercator(lat, n, b)

      break if (northing - N0 - m) < PRECISION
    end

    sin_lat = sin(lat)
    sec_lat = 1.0 / cos(lat)
    tan_lat = tan(lat)

    v = a * F0 * ((1 - (e2 * (sin_lat**2)))**-0.5)
    rho = a * F0 * (1 - e2) * ((1 - (e2 * (sin_lat**2)))**-1.5)
    n2 = (v / rho) - 1.0

    c7 = tan_lat / (2.0 * rho * v)
    c8 = tan_lat / (24.0 * rho * (v**3.0)) * (5 + (3.0 * (tan_lat**2.0)) + n2 - (9.0 * (tan_lat**2.0) * n2))
    c9 = tan_lat / (720.0 * rho * (v**5.0)) * (61 + (90.0 * (tan_lat**2.0)) + (45.0 * (tan_lat**4.0)))
    c10 = sec_lat / v
    c11 = (sec_lat / (6.0 * (v**3.0))) * ((v / rho) + (2.0 * (tan_lat**2.0)))
    c12 = (sec_lat / (120.0 * (v**5.0))) * (5.0 + (28.0 * (tan_lat**2.0)) + (24.0 * (tan_lat**4.0)))
    c12a = (sec_lat / (5040.0 * (v**7.0))) * (61.0 + (662.0 * (tan_lat**2.0)) + (1320.0 * (tan_lat**4.0)) + (720.0 * (tan_lat**6.0)))
    delta = easting - E0

    lat = lat - (c7 * (delta**2.0)) + (c8 * (delta**4.0)) - (c9 * (delta**6.0))
    lng = LNG0 + (c10 * delta) - (c11 * (delta**3.0)) + (c12 * (delta**5.0)) - (c12a * (delta**7.0))

    lng, lat = osgb36_to_wgs84(lng, lat)
    [rad_to_deg(lng).round(6), rad_to_deg(lat).round(6)]
  end

  # Based on the formula in C.1
  def wgs84_to_os_ng(lng, lat)
    lng, lat = wgs84_to_osgb36(deg_to_rad(lng), deg_to_rad(lat))

    a, b = OSGB36
    e2 = ((a**2) - (b**2)) / (a**2)
    n = (a - b) / (a + b)

    v = a * F0 * ((1 - (e2 * (sin(lat)**2)))**-0.5)
    rho = a * F0 * (1 - e2) * ((1 - (e2 * (sin(lat)**2)))**-1.5)
    n2 = (v / rho) - 1.0
    m = mercator(lat, n, b)

    tan_lat = tan(lat)
    sin_lat = sin(lat)
    cos_lat = cos(lat)

    c1 = m + N0
    c2 = v / 2.0 * sin_lat * cos_lat
    c3 = v / 24.0 * sin_lat * (cos_lat**3.0) * (5.0 - (tan_lat**2.0) + (9 * n2))
    c3a = v / 720.0 * sin_lat * (cos_lat**5.0) * (61.0 - (58.0 * (tan_lat**2.0)) + (tan_lat**4.0))
    c4 = v * cos_lat
    c5 = v / 6.0 * (cos_lat**3.0) * ((v / rho) - (tan_lat**2.0))
    c6 = v / 120.0 * (cos_lat**5.0) * (5 - (18.0 * (tan_lat**2.0)) + (tan_lat**4.0) + (14.0 * n2) - (58.0 * (tan_lat**2.0) * n2))
    delta = lng - LNG0

    northing = c1 + (c2 * (delta**2.0)) + (c3 * (delta**4.0)) + (c3a * (delta**6.0))
    easting = E0 + (c4 * delta) + (c5 * (delta**3.0)) + (c6 * (delta**5.0))

    [easting.round(3), northing.round(3)]
  end

  private

  def wgs84_to_osgb36(lng, lat, height = 0)
    coords = spherical_to_cartesian(lng, lat, height, WGS84)
    coords = transform(coords, WGS84_TO_OSGB36)

    cartesian_to_spherical(*coords, OSGB36)[0..1]
  end

  def osgb36_to_wgs84(lng, lat, height = 0)
    coords = spherical_to_cartesian(lng, lat, height, OSGB36)
    coords = transform(coords, OSGB36_TO_WGS84)

    cartesian_to_spherical(*coords, WGS84)[0..1]
  end

  # From 'A guide to coordinate systems in Great Britain - B.1'
  def spherical_to_cartesian(lng, lat, height, ellipsoid)
    a, b = ellipsoid
    e2 = ((a**2) - (b**2)) / (a**2)

    v = a / sqrt(1 - (e2 * (sin(lat)**2.0)))
    x = (v + height) * cos(lat) * cos(lng)
    y = (v + height) * cos(lat) * sin(lng)
    z = (((1 - e2) * v) + height) * sin(lat)

    [x, y, z]
  end

  # From 'A guide to coordinate systems in Great Britain - B.2'
  def cartesian_to_spherical(x, y, z, ellipsoid)
    a, b = ellipsoid
    e2 = ((a**2) - (b**2)) / (a**2)

    p = sqrt((x**2.0) + (y**2.0))
    lat = atan(z / p * (1 - e2))
    v = a / sqrt(1 - (e2 * (sin(lat)**2.0)))

    # Although the algorithm says to loop until the delta is within the
    # desired precision we put a hard limit of 10 iterations to prevent
    # the application process from going into an infinite loop.
    10.times do
      lat1 = atan((z + (e2 * v * sin(lat))) / p)
      v = a / sqrt(1 - (e2 * (sin(lat1)**2.0)))

      break if (lat1 - lat).abs < PRECISION

      lat = lat1
    end

    lng = atan(y / x)
    height = (p / cos(lat)) - v

    [lng, lat, height]
  end

  def transform(coords, matrix)
    x1, y1, z1 = coords
    tx, ty, tz = matrix.values_at(:tx, :ty, :tz)

    # Helmert values are in arc seconds so convert to radians
    rx, ry, rz = matrix.values_at(:rx, :ry, :rz).map(&method(:sec_to_rad))

    # Normalize from ppm
    s1 = (matrix[:s] / 1e6) + 1

    # Transformation matrix from section 6.2 (3)
    x2 = tx + (x1 * s1) - (y1 * rz) + (z1 * ry)
    y2 = ty + (x1 * rz) + (y1 * s1) - (z1 * rx)
    z2 = tz - (x1 * ry) + (y1 * rx) + (z1 * s1)

    [x2, y2, z2]
  end

  def sec_to_rad(seconds)
    seconds / 3600.0 * PI / 180.0
  end

  def deg_to_rad(degrees)
    degrees * PI / 180.0
  end

  def rad_to_deg(radians)
    radians * 180.0 / PI
  end

  def mercator(lat, n, b)
    b * F0 * (merc_1(lat, n) - merc_2(lat, n) + merc_3(lat, n) - merc_4(lat, n))
  end

  def merc_1(lat, n)
    (1 + n + (1.2 * (n**2)) + (1.2 * (n**3))) * (lat - LAT0)
  end

  def merc_2(lat, n)
    ((3 * n) + (3 * (n**2)) + (2.625 * (n**3))) * sin(lat - LAT0) * cos(lat + LAT0)
  end

  def merc_3(lat, n)
    ((1.875 * (n**2)) + (1.875 * (n**3))) * sin(2 * (lat - LAT0)) * cos(2 * (lat + LAT0))
  end

  def merc_4(lat, n)
    (35.0 * (n**3) / 24.0) * sin(3 * (lat - LAT0)) * cos(3 * (lat + LAT0))
  end
end
