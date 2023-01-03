#!/usr/bin/env ruby

require "./misheyakir"
require "active_support"
require "active_support/core_ext/time/zones"
require "calendar_helper"
require "erb"
require "pdfkit"
require "sinatra"
require "sinatra/reloader"

include CalendarHelper

also_reload "misheyakir.rb"

set :show_exceptions, false

configure do
  set :tz_list, [
    "US/Eastern",
    "US/Central",
    "US/Pacific",
  ]
end

def render_index(params, error=nil)
  erb :index, :locals => {
    :error => error,
    :lat => params[:lat] ? params[:lat] : nil,
    :lng => params[:lng] ? params[:lng] : nil,
    :name => params[:name] ? params[:name] : nil,
    :tz => params[:tz] ? params[:tz] : nil,
    :tz_list => settings.tz_list,
    :year => params[:year] ? params[:year] : Time.now.year,
  }
end

get "/" do
  render_index({})
end

get "/calendar" do
  begin
    lat = Float(params[:lat])
  rescue ArgumentError
    raise "invalid lat #{params[:lat].inspect}"
  end

  begin
    lng = Float(params[:lng])
  rescue ArgumentError
    raise "invalid lng #{params[:lng].inspect}"
  end

  begin
    year = Integer(params[:year])
  rescue ArgumentError
    raise "invalid year #{params[:year].inspect}"
  end

  begin
    tz = TZInfo::Timezone.get(params[:tz])
  rescue Exception => e
    raise "invalid timezone #{params[:tz].inspect}: #{e.message}"
  end
  m = Misheyakir.new(lat, lng, tz, -12.9)

  cal_tmpl = ERB.new(File.read("views/calendar.erb"))
  html = cal_tmpl.result(binding)

  PDFKit.configure do |config|
    config.default_options = {
      :page_size => "Letter",
      :margin_top => "0.75in",
      :margin_bottom => "0.25in",
      :margin_left => "0.25in",
      :margin_right => "0.25in",
    }
  end

  content_type "application/pdf"
  kit = PDFKit.new(html, :page_size => "Letter")
  kit.stylesheets << "views/grey.css"
  kit.to_pdf
end

error Exception do
  render_index(params, env["sinatra.error"].message)
end
