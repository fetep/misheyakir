#!/usr/bin/env ruby

require "./misheyakir"
require "calendar_helper"
require "erb"
require "pdfkit"
require "sinatra"
require "sinatra/reloader"

include CalendarHelper

set :show_exceptions, false

get "/" do
  erb :index, :locals => {
    :error => nil,
    :lat => nil,
    :lng => nil,
    :name => nil,
    :year => Time.now.year,
  }
end

get "/calendar" do
  lat = params[:lat].to_f
  lng = params[:lng].to_f
  year = params[:year].to_i

  if lat == 0
    raise "invalid lat #{params[:lat].inspect}"
  elsif lng == 0
    raise "invalid lng #{params[:lng].inspect}"
  elsif year == 0
    raise "invalid year #{params[:year].inspect}"
  end

  m = Misheyakir.new(lat, lng, -5, -12.9)

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
  kit.stylesheets << "grey.css"
  kit.to_pdf
end

error Exception do
  erb :index, :locals => {
    :error => env["sinatra.error"].message,
    :lat => params[:lat],
    :lng => params[:lng],
    :name => params[:name],
    :year => params[:year],
  }
end
