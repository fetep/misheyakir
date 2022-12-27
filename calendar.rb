#!/usr/bin/env ruby

require "./misheyakir"
require "calendar_helper"
require "erb"
require "pdfkit"

m = Misheyakir.new(40.785, -74.3, -5, -12.9)

include CalendarHelper

cal_tmpl = ERB.new(File.read("calendar.erb"))
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

kit = PDFKit.new(html, :page_size => "Letter")
kit.stylesheets << "grey.css"
kit.to_file("cal.pdf")
