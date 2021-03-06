class UploadUtils
  
  # Create a YEAR/MONTH subdirectory
  #   ex. 2014/JAN, 2014/FEB
  # _dir { String } Parent directory
  # _subdir { String } Optional subdirectory
  # @return { String } Created Directory
  def self.monthDir( _dir, _subdir='' )
    time = Time.now
    dir = File.join( _dir, time.year.to_s, time.strftime( '%^b' ), _subdir )
    FileUtils.mkdir_p( dir )
    return dir
  end
  
  # Get a unique filename
  # _file { String }
  # _num { Int }
  # @return { Hash } 
  def self.filename( _file, _num=1 )
    #-------------------------------------------------------------
    #  Determine the suffix of the uploaded filename
    #-------------------------------------------------------------
    count = ''
    if _num > 1
      count = ' ' + _num.to_s
    end
    #-------------------------------------------------------------
    #  Build the new path
    #-------------------------------------------------------------
    dir = File.dirname( _file )
    ext = File.extname( _file )
    base = File.basename( _file, ext )
    file = base + count + ext
    path = File.join( dir, file )
    #-------------------------------------------------------------
    #  Check to see if the file exists already
    #-------------------------------------------------------------
    if File.file?( path )
      _num += 1
      return filename( _file, _num )
    end
    return { "original" => _file, "path" => path, "ext" => ext, "filename" => file }
  end
  
  # Send a file over HTTP POST
  # _file { String } Path to file
  # _url { String } URL to POST file
  def self.upload( _file, _url )
    results = RestClient.post( _url, :file => File.new( _file ) )
    #-------------------------------------------------------------
    #  Return some kind of HTTP response info
    #-------------------------------------------------------------
    puts results
  end
  
end