#!/usr/bin/env ruby

require "./misheyakir"

require "date"
require "rspec"

describe "Misheyakir" do
  it "should calculate sun position with refraction" do
    m = Misheyakir.new(40.785, -74.3, -5, -12.9)
    d = Date.new(2022, 1, 1)
    expect(m.sun_pos(d, 12).to_f).to eq(-72.05501968878028)
  end

  it "should calculate misheyakir time" do
    m = Misheyakir.new(40.785, -74.3, -5, -12.9)
    d = Date.new(2022, 1, 1)
    expect(m.time(d)).to eq([6, 10])

    d = Date.new(2022, 2, 1)
    expect(m.time(d)).to eq([6, 0])

    d = Date.new(2022, 2, 28)
    expect(m.time(d)).to eq([5, 28])

    d = Date.new(2022, 6, 5)
    expect(m.time(d)).to eq([3, 3])
  end
end
