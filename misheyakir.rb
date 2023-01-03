#!/usr/bin/env ruby

require "active_support/core_ext/time/zones"
require "bigdecimal"

class Misheyakir
  MAX_MINUTE_DIFF = 0.5

  def initialize(lat=0, lng=0, tz=TZInfo::Timezone.get('UTC'), sun_angle=-12.9)
    @lat, @lng, @tz = lat, lng, tz
    @sun_angle = sun_angle - BigDecimal(0.266666, 10) # top of sun
  end

  # calculate the angle of the sun for a given lat/lng; corrected for refraction
  # formula borrowed from https://gml.noaa.gov/grad/solcalc/calcdetails.html
  # variables named after spreadsheet columns (for now)
  # @param day Date object
  # @param minute how many minutes into day
  # @return angle of sun (degrees)
  def sun_pos(day, minute)
    rad = Math::PI / BigDecimal(180)
    hour = minute / 60
    minute_offset = minute - (hour * 60)

    # calculate tz offset for #{day}
    tz_offset = @tz.utc_offset / (60 * 60)

    # ajd == astronomical julian day
    f = BigDecimal(day.ajd, 15) + (BigDecimal(minute) / (60.0 * 24.0)) - (tz_offset / 24.0)
    g = (f - 2451545) / BigDecimal(36525)
    i = (BigDecimal(280.46646, 10) + \
        g * (BigDecimal(36000.76983, 10) + \
        g * BigDecimal(0.0003032, 10))) % 360
    j = BigDecimal(357.52911, 10) + g * (BigDecimal(35999.05029, 10) - \
        BigDecimal(0.0001537, 10) * g)
    k = BigDecimal(0.016708634, 12) - g * (BigDecimal(0.000042037, 12) + \
        BigDecimal(0.0000001267, 12) * g)
    l = Math.sin(rad * j) * (BigDecimal(1.914602, 10) - g * (BigDecimal(0.004817, 10) + \
        BigDecimal(0.000014, 10) * g)) + Math.sin(rad*(2 * j)) * (BigDecimal(0.019993, 10) - \
        BigDecimal(0.000101, 10) * g) + Math.sin(rad*(3 * j)) * BigDecimal(0.000289, 10)
    m = i + l
    n = j + l
    o = (BigDecimal(1.000001018, 12) * (1 - k * k)) / (1 +k * Math.cos(rad * n))
    p = m - BigDecimal(0.00569, 10) - \
        BigDecimal(0.00478, 10) * \
        Math.sin(rad * (BigDecimal(125.04, 10) - BigDecimal(1934.136, 10) * g))
    q = 23 + (26 + ((21.448 - g * (46.815 + g * (0.00059 - g * 0.001813)))) / 60) / 60
    r = q + 0.00256 * Math.cos(rad * (125.04 - 1934.136 * g))
    t = Math.asin(Math.sin(rad * r) * Math.sin(rad * p)) / rad
    u = Math.tan(rad * (r / 2)) * Math.tan(rad * (r / 2))
    v = 4 * (u * Math.sin(2 * rad * i) - 2 * k * Math.sin(rad * j) + \
             4 * k * u * Math.sin(rad * j) * Math.cos(2 * rad * i) - \
             0.5 * u * u * Math.sin(4 * rad * i) - \
             1.25 * k * k * Math.sin(2 * rad * j)
            ) / rad
    ab = (minute + v + 4 * @lng -60 * tz_offset) % 1440

    if ab / 4.0 < 0
      ac = ab / 4.0 + 180
    else
      ac = ab / 4.0 - 180
    end

    ad = (Math.acos(Math.sin(rad * @lat) * Math.sin(rad * t) + \
          Math.cos(rad * @lat) * Math.cos(rad * t) * Math.cos(rad * ac))
         ) / rad
    ae = 90 - ad

    # refraction adjustment
    if ae > 85
      af = 0
    elsif ae > 5
      af = 58.1 / Math.tan(rad * ae) - \
        0.07 / (Math.tan(rad * ae) ** 3) + \
        0.000086 / (Math.tan(rad * ae) ** 5)
    elsif ae > -0.575
      af = 1735 + ae * (-518.2 + ae * (103.4 + ae * (-12.79 + ae * 0.711)))
    else
      af = -20.772 / Math.tan(rad * ae)
    end
    af /= 3600

    return ae + af # ag
  end

  # calculate misheyakir time for a given date by looking for the first minute in the
  # day that we are past @sun_angle. (so if it happens at 8:01:01, we return 2. it should
  # always be the minute past misheyakir, not the minute of).
  # @param day Date object
  # @return hour, minute misheyakir time for given day
  def time(day)
    # sun_pos starts negative and is increasing as minutes go higher (sun is rising).
    # we assume that our lat/lng/tz gives us a minute=0 where the sun is rising.
    max_minute = 60 * 12

    # read through cache for minute->sun_pos
    angles = Hash.new { |h, k| h[k] = sun_pos(day, k) }

    lower = 0
    upper = max_minute

    if @sun_angle < angles[lower] or @sun_angle > angles[upper]
      raise "#{day}: misheyakir does not happen in the first #{max_minute} minutes (check TZ?)"
    end

    count = 0
    loop do
      mid = lower + ((upper - lower) / 2).floor

      # we assume that the angle difference between consecutive minutes is never greater
      # than MAX_MINUTE_DIFF. So if angles[mid] is more than MAX_MINUTE_DIFF away from
      # @sun_angle, we know this isn't the right minute.
      diff = angles[mid] - @sun_angle
      if diff > 0 && diff >= MAX_MINUTE_DIFF
        upper = mid
        next
      elsif diff < 0 && diff <= -1 * MAX_MINUTE_DIFF
        lower = mid
        next
      end

      # check if we are exactly the minute the angle becomes greater than @sun_angle
      if angles[mid] > @sun_angle && angles[mid - 1] <= @sun_angle
        m_hour =mid / 60
        m_min = mid % 60

        # Check if we need a DST offset. We think there is a bug in the dst? method that uses
        # the date to check DST, not the actual time. DST starts/ends at 2am, so if the mish time
        # is after 2am, we check dst? on the next day.
        if m_hour < 2
          dst_day = day
        else
          dst_day = day + 1
        end
        today_t = Time.new(dst_day.year, dst_day.month, dst_day.day, m_hour, m_min, 0, @tz)
        if today_t.dst?
          m_hour += 1
        end

        return [m_hour, m_min]
      end

      # pick another half to keep looking in
      if angles[mid] > @sun_angle
        # we overshot; lower the upper threshold to the current middle
        upper = mid
      else
        # we undershot; raise the lower threshold to the current middle
        lower = mid
      end

      count += 1
      raise "#{day}: infinite loop detecting mid (#{lower}/#{upper})" if count > 100
    end
  end
end
