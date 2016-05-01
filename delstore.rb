#!/opt/local/bin/ruby -Ku

require 'optparse'
require 'pstore'
require 'rubygems'
require 'highline/import'

opt = OptionParser.new
OPTS = Hash.new
OPTS[:indexfile] = "index.db"
OPTS[:targetname] = "targetname"
opt.on('-i VAL', '--indexfile VAL') {|v| OPTS[:indexfile] = v}
opt.on('-t VAL', '--target-file VAL') {|v| OPTS[:targetname] = v}
opt.parse!(ARGV)

p OPTS[:indexfile]

db = PStore.new(OPTS[:indexfile])
db.transaction do

  targetname = OPTS[:targetname]
  db.roots.each{|name|
    targetname = name if name =~ /#{OPTS[:targetname]}/
  }

  if db.root?(targetname)
    printf("%s\n%s\n", targetname, db[targetname])
    #p 'yes' if HighLine.agree('Do it? [Y/n]')
    db.delete(targetname) if HighLine.agree('Do it? [Y/n]')
  else
    printf("name %s does not exist.\n", targetname)
  end
      
#   if File.pipe?(STDIN) then
#     STDIN.each{|line|
#       name = line.chomp
#       case OPTS[:output]
#       when "csv" then
#         format = "%s,%s,%s,%s,%s,%s,%s,%s,%s\n"
#       when "tsv" then
#         format = "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
#       end
#       printf(format, 
#              name, db[name]["basename"], db[name]["filesize"],
#              db[name]["ctime"], db[name]["duration"], db[name]["start"], 
#              db[name]["bitrate"], db[name]["width"], db[name]["height"])
#     }
#   else
# 
#     db.roots.each{|name|
#       case OPTS[:output]
#       when "csv" then
#         format = "%s,%s,%s,%s,%s,%s,%s,%s,%s\n"
#       when "tsv" then
#         format = "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
#       end
#       printf(format, 
#              name, db[name]["basename"], db[name]["filesize"],
#              db[name]["ctime"], db[name]["duration"], db[name]["start"], 
#              db[name]["bitrate"], db[name]["width"], db[name]["height"])
#     }
#   end
end
