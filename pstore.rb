#!/opt/local/bin/ruby -Ku

require 'optparse'
require 'pstore'

opt = OptionParser.new
OPTS = Hash.new
OPTS[:indexfile] = "index.db"
opt.on('-i VAL', '--indexfile VAL') {|v| OPTS[:indexfile] = v}
opt.on('-c', '--csv-output') {|v| OPTS[:output] = "csv" }
opt.on('-t', '--tsv-output') {|v| OPTS[:output] = "tsv" }
opt.parse!(ARGV)

db = PStore.new(OPTS[:indexfile])
db.transaction do

  if File.pipe?(STDIN) then
    STDIN.each{|line|
      name = line.chomp
      case OPTS[:output]
      when "csv" then
        format = "%s,%s,%s,%s,%s,%s,%s,%s,%s\n"
      when "tsv" then
        format = "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
      end
      printf(format, 
             name, db[name]["basename"], db[name]["filesize"],
             db[name]["ctime"], db[name]["duration"], db[name]["start"], 
             db[name]["bitrate"], db[name]["width"], db[name]["height"])
    }
  else

    db.roots.each{|name|
      case OPTS[:output]
      when "csv" then
        format = "%s,%s,%s,%s,%s,%s,%s,%s,%s\n"
      when "tsv" then
        format = "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
      end
      printf(format, 
             name, db[name]["basename"], db[name]["filesize"],
             db[name]["ctime"], db[name]["duration"], db[name]["start"], 
             db[name]["bitrate"], db[name]["width"], db[name]["height"])
    }
  end
end
