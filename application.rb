require 'rubygems'

require 'awesome_print'
require 'pry-byebug'
require 'mechanize'

def read_file(filename)
  File.readlines(filename).map(&:split)
end

def process_array(array)
  hash = {}
  array.each do |entry|
    hash[entry.first] = (fetch_prices(entry.last).first - entry[1].to_f).round(1)
  end
  hash
end

def fetch_prices(url)
  agent = Mechanize.new
  page = agent.get(url)
  price_string = page.search('dd.priceinfo__value').children.map(&:text).reject{|e| e =~ /^\s+|^$/}.first
  prices = price_string.scan(/\d+,*\d*/)
  prices.map{|e| e.gsub(/,/, '.')}.map(&:to_f)
end

def process_file(filename)
  results = process_array(read_file(filename))
  results[:total] = results.values.sum
  results
end

def do_all(filename, file_to_process)
  db = nil
  
  if File.exists?(filename)
    db = Marshal.load(File.read(filename))
  else
    db = {}
  end

  if db[Date.today.to_s]
    puts "Data already exists for today, exiting."
    return
  else
    puts "Fetching data for today."
    db[Date.today.to_s] = process_file(file_to_process)
  end

  File.open(filename, 'wb') do |file|
    file.write(Marshal.dump(db))
    puts "Stored todays data in db."
  end
end

def print_data_from_db(db_filename)
  db = Marshal.load(File.read(db_filename))
  ap db
end

if __FILE__==$0
  do_all('db', ARGV[0])
end
