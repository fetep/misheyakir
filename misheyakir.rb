#!/usr/bin/env ruby

require "bigdecimal"
require "date"

class Misheyakir
  def initialize(lat=0, lng=0, tz=0, sun_angle=-12.9)
    @lat, @lng, @tz = lat, lng, tz
    @sun_angle = sun_angle - BigDecimal(0.266666, 10) # top of sun
  end


  # calculate the angle of the sun for a given lat/lng
  # correct for refraction
  # @param day Date object
  # @param minute how many minutes into day
  # @return angle of sun
  def sun_pos(day, minute)
    rad = Math::PI / BigDecimal(180)
    hour = minute / 60

    # ajd == astronomical julian day
    adjust = (minute / (60.0*24.0))
    adjust_tz = (@tz / 24.0)
    f = BigDecimal(day.ajd, 15) + (BigDecimal(minute) / (60.0*24.0)) - (@tz / 24.0)
    g = (f - 2451545) / BigDecimal(36525)
    i = (BigDecimal(280.46646, 10) + \
         g * (BigDecimal(36000.76983, 10) + \
              g * BigDecimal(0.0003032, 10))) % 360
    j = BigDecimal(357.52911, 10) + g * (BigDecimal(35999.05029, 10) - BigDecimal(0.0001537, 10) * g)
    k = BigDecimal(0.016708634, 12) - g * (BigDecimal(0.000042037, 12) + BigDecimal(0.0000001267, 12) * g)
    l = Math.sin(rad * j) * (BigDecimal(1.914602, 10) - g * (BigDecimal(0.004817, 10) + BigDecimal(0.000014, 10) * g)) + \
      Math.sin(rad*(2 * j)) * (BigDecimal(0.019993, 10) - BigDecimal(0.000101, 10) * g) + \
      Math.sin(rad*(3 * j)) * BigDecimal(0.000289, 10)
    m = i + l
    n = j + l
    o = (BigDecimal(1.000001018, 12) * (1 - k * k)) / (1 +k * Math.cos(rad * n))
    p = m - BigDecimal(0.00569, 10) - BigDecimal(0.00478, 10) * Math.sin(rad * (BigDecimal(125.04, 10) - BigDecimal(1934.136, 10) * g))
    q = 23+(26+((21.448-g*(46.815+g*(0.00059-g*0.001813))))/60)/60
    r = q+0.00256*Math.cos(rad*(125.04-1934.136*g))
    t = (Math.asin(Math.sin(rad*(r))*Math.sin(rad*(p))))/rad
    u = Math.tan(rad*(r/2))*Math.tan(rad*(r/2))
    v = 4*(u*Math.sin(2*rad*(i))-2*k*Math.sin(rad*(j))+4*k*u*Math.sin(rad*(j))*Math.cos(2*rad*(i))-0.5*u*u*Math.sin(4*rad*(i))-1.25*k*k*Math.sin(2*rad*(j)))/rad
    ab = (minute+v+4*@lng-60*@tz) % 1440

    if ab/4.0 < 0
      ac = ab / 4.0 + 180
    else
      ac = ab / 4.0 - 180
    end

    #puts "day=#{day.ajd.to_f} hour=#{hour} minute=#{minute} ac=#{ac.to_f}"

    ad = (Math.acos(Math.sin(rad*(@lat))*Math.sin(rad*(t))+Math.cos(rad*(@lat))*Math.cos(rad*(t))*Math.cos(rad*(ac))))/rad #degreees after noon
    # degrees after sunrise
    # when this was tzais, it seems that ad is degrees from noon (later than noon),
    # so degrees before sun_angle is 90-ad. Degrees before sunrise is thus -(ad+90)
    ae = 90 - ad

    # refraction adjustment
    if ae > 85
      af = 0
    elsif ae > 5
      af = 58.1 / Math.tan(rad*ae) - \
        0.07 / (Math.tan(rad * ae) ** 3) + \
        0.000086 / (Math.tan(rad*ae) ** 5)
    elsif ae > -0.575
      af = 1735+ae*(-518.2+ae*(103.4+ae*(-12.79+ae*0.711)))
    else
      af = -20.772/Math.tan(rad*ae)
    end
    af /= 3600
    ag = ae + af

    #puts "day=#{day.ajd.to_f} hour=#{hour} minute=#{minute} ae=#{ae.to_f} ag=#{ag.to_f}"

    return ag
  end

  # calculate misheyakir time for a given date
  # @param day Date object
  # @return hour, minute misheyakir time for given day
  def time(day)
    # find the first minute in the day that we are past @sun_angle
    minute = nil
    0.upto(60 * 12).each do |m|
      angle = sun_pos(day, m)
      if angle > @sun_angle
        #puts "** minute=#{minute} angle=#{angle} sun_angle=#{@sun_angle}"
        minute = m
        break
      end
    end

    # did we make it 12 hours without finding an appropriate minute?
    if minute.nil?
      raise "#{day}: no time found where angle is over #{@sun_angle}"
    end

    return [minute / 60, minute % 60]
  end
end