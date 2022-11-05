#!/usr/bin/env ruby

require "./misheyakir"

require "date"
require "rspec"

describe "Misheyakir" do
  before :each do
    @m = Misheyakir.new(40.785, -74.3, -5, -12.9)
  end

  it "should calculate sun position with refraction" do
    d = Date.new(2022, 1, 1)
    expect(@m.sun_pos(d, 12).to_f).to eq(-72.05501968878006)
  end

  it "should calculate misheyakir time" do
    m = Misheyakir.new(40.785, -74.3, -5, -12.9)
    day = Date.new(2022, 1, 1)
    expect(@m.time(day)).to eq([6, 10])

    day = Date.new(2022, 2, 1)
    expect(@m.time(day)).to eq([6, 0])

    day = Date.new(2022, 2, 28)
    expect(@m.time(day)).to eq([5, 28])

    day = Date.new(2022, 6, 5)
    expect(@m.time(day)).to eq([3, 3])
  end

  it "should calculate misheyakir time for every day in 2022", :slow => true do
    data_path = File.join(__dir__, "test2022.data")

    day = Date.new(2022, 1, 1)
    i = 1
    aggregate_failures "every day check" do
      File.read(data_path).split.each do |time|
        i += 1
        exp_hour, exp_minute = time.split(":", 2)
        hour, minute = @m.time(day)
        expect([hour, minute]).to eq([exp_hour.to_i, exp_minute.to_i]),
          "for #{day}, expected #{exp_hour}:#{exp_minute} but got #{hour}:#{minute}"
        day += 1
      end
    end
  end
end
