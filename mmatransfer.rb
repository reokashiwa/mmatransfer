#!/opt/local/bin/ruby -Ku

require 'optparse'
require 'pstore'
require 'yaml'

opt = OptionParser.new
OPTS = Hash.new
OPTS[:target] = Array.new
OPTS[:indexfile] = "index.db"
opt.on('-f VAL', '--filename VAL') {|v| OPTS[:filename] = v}
opt.on('-t VAL', '--target VAL') {|v| OPTS[:target] << v }
opt.on('-i VAL', '--indexfile VAL') {|v| OPTS[:indexfile] = v}
opt.on('-c VAL', '--configfile VAL') {|v| OPTS[:configfile] = v}
opt.parse!(ARGV)

target_directories = Array.new
OPTS[:target].each{|directory_name|
  target_directories << directory_name.to_s + "/*"
}

CONF = YAML.load_file(OPTS[:configfile])

def recursive_glob(directory_name)
  filenames = Dir.glob(directory_name)
  filenames.each{|filename|
    recursive_glob(filename + "/*") if File.ftype(filename) == "directory"
    if /\.mpg/ =~ filename || /\.ts/ =~ filename
      md5 = get_md5(filename) 
      mmatransfer(md5, filename)
    end
  }
end

def get_md5(filename)
  db = PStore.new(OPTS[:indexfile])

  basename  = File.basename(filename)
  filesize  = FileTest.size(filename)
  md5 = String.new
  record_exist = false

  db.transaction do
    db.roots.each{|name|
      if basename == db[name]["basename"] && filesize == db[name]["filesize"]
        record_exist = true
        printf("%s\t record exists.\n", name)
        md5 = name
        break
      end
    }
  end

  if ! record_exist
    printf("%s\t record does not exists.\n", basename)
    md5 = `#{CONF["MD5_PATH"]} -q "#{filename}" 2>&1`
    if $?.exitstatus == 0
      md5.chomp!
      addDB(md5, filename)
    else
      printf("MD5 error: %s\n%s\n%s\n", filename, md5.chomp!, $?)
    end
  end

  return md5
end

def mmatransfer(md5, filename)

  dstFileExist = false
  filesize  = FileTest.size(filename)
  basename  = File.basename(filename)

  exec_command = CONF["GSISSH_PATH"] + " -p " + CONF["GSISSH_PORT"].to_s + 
    " " + CONF["GSISSH_HOST"] + " ls -l " + CONF["DST_DIR"] + "/" + md5
  result = `#{exec_command}`
  dstFileExist = true if result.split(" ")[ 4 ] == filesize.to_s

  if ! dstFileExist
    start_time = Time.now.to_i
    exec_command = CONF["GSISCP_PATH"] + " -P " + CONF["GSISSH_PORT"].to_s +
      ' "' + filename + '" ' + 
      CONF["GSISSH_HOST"] + ":" + CONF["DST_DIR"] + "/" + md5
    result = `#{exec_command}`
    end_time = Time.now.to_i
    printf("%s\t%s\t%d [sec]\n", basename, filesize, (end_time - start_time))
  else
    printf("Filename:%s is Exist (%s).\n", filename, md5)
  end
end

def addDB(md5, filename)

  basename  = File.basename(filename)
  filesize  = FileTest.size(filename)
  db = PStore.new(OPTS[:indexfile])

  db.transaction do
    if db[md5] == nil
      ctime = File.ctime(filename) if File.ctime(filename) != nil
      result = `#{CONF["FFMPEG_PATH"]} -i "#{filename}" 2>&1`
      resultArray = result.split(/\n[\s]*/)
      duration = String.new
      start = String.new
      bitrate = String.new
      width = String.new
      height = String.new
      resultArray.each{|res|
        if /Duration.*start.*bitrate/ =~ res
          duration = res.split(/,/)[ 0 ].scan(/[\d:\.]+/)[ 1 ]
          start    = res.split(/,/)[ 1 ].scan(/[\d\.]+/)[ 0 ]
          bitrate  = res.split(/,/)[ 2 ].scan(/\d+/)[ 0 ]
        elsif /Stream.*Video/ =~ res
          width  = res.scan(/[0-9]+x[0-9]+/)[ 1 ].split('x')[ 0 ]
          height = res.scan(/[0-9]+x[0-9]+/)[ 1 ].split('x')[ 1 ]
        end
      }
      printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
             basename,
             filesize,
             ctime,
             duration,
             start, 
             bitrate,
             width,
             height)
      db[md5] = Hash.new
      db[md5]["basename"] = basename
      db[md5]["filesize"] = filesize
      db[md5]["ctime"] = ctime
      db[md5]["duration"] = duration if duration != nil
      db[md5]["start"] = start       if start != nil
      db[md5]["bitrate"] = bitrate   if bitrate != nil
      db[md5]["width"] = width       if width != nil
      db[md5]["height"] = height     if height != nil
    end
  end
end

if target_directories.empty? && OPTS[:filename] == nil
  p "target directory must be specified."
  exit(0)
elsif 
  target_directories.each{|directory_name|
    recursive_glob(directory_name)
  }
  if OPTS[:filename] != nil
    filename = OPTS[:filename]
    md5 = get_md5(filename) 
    mmatransfer(md5, filename)
  end
end

#getRes("~/Movies/sample.mpg")
