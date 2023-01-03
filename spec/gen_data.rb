#!/usr/bin/env ruby
# generate a test data file for a given year using our test coords

$: << File.expand_path(File.join(__dir__, ".."))

require "misheyakir"

require "concurrent"
require "date"
require "rspec"

# coords/timezone/angle used in spec code
m = Misheyakir.new(40.785, -74.3, TZInfo::Timezone.get('US/Eastern'), -12.9)
year = 2022

threads = []
dates = Queue.new
times = Concurrent::Map.new

# generate a date for every day in the target year
1.upto(12) do |month|
  days = Date.new(year, month, -1).day
  1.upto(days) do |day|
    dates << Date.new(year, month, day)
  end
end

# fire up misheyakir worker threads that exit when dates is empty
thread_count = ENV.fetch("THREADS", Etc.nprocessors).to_i
$stderr.puts "thread_count=#{thread_count}"
1.upto(thread_count) do
  threads << Thread.new do
    begin
      while date = dates.pop(true) do
        times[date] = m.time(date)
      end
    rescue ThreadError
      # dates queue is empty
    end
  end
end

threads.each { |t| t.join }

# collate into test data. one time per line for each day in 2022 (in order)
times.keys.sort.each do |date|
  puts "%d:%02d" % times[date]
end

data_path = File.join(__dir__, "test#{year}.data")
