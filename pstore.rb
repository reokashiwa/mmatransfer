#!/usr/bin/ruby -Ku

require 'optparse'
require 'pstore'
require 'highline/import'

opt = OptionParser.new
OPTS = Hash.new
OPTS[:indexfile] = "index.db"
OPTS[:mode] = :show
opt.on('-i VAL', '--indexfile VAL') {|v| OPTS[:indexfile] = v}
opt.on('-c', '--csv-output') {|v| OPTS[:output] = "csv" }
opt.on('-t', '--tsv-output') {|v| OPTS[:output] = "tsv" }
opt.on('-d', '--delete') {OPTS[:mode] = :delete}
opt.parse!(ARGV)

db = PStore.new(OPTS[:indexfile])
db.transaction do

  case OPTS[:mode]
  when :show
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

  when :delete
    targets = Array.new
    db.roots.each{|name|
      targets.push(name) if name =~ Regexp.new(ARGV[0])
    }

    targets.each{|target|
      if db.root?(target)
        p target
        printf("%s\n", db[target])
        #p 'yes' if HighLine.agree('Do it? [Y/n]')
        db.delete(target) if HighLine.agree('Do it? [Y/n]')
      else
        printf("name %s does not exist.\n", target)
      end
    }

  else
  end
end
