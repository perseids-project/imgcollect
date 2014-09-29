class ImgSize
  include Sidekiq::Worker
  sidekiq_options queue: "high"
    
  def self.thumb( src )
    dim = Rails.configuration.thumb_max_width.to_s + 'x' + Rails.configuration.thumb_max_height.to_s
    dir = UploadUtils.monthDir( Rails.configuration.img_dir, Rails.configuration.thumb_dir )
    self.create( src, dim, dir )
  end
  
  def self.basic( src )
    dim = Rails.configuration.basic_max_width.to_s + 'x' + Rails.configuration.basic_max_height.to_s
    dir = UploadUtils.monthDir( Rails.configuration.img_dir, Rails.configuration.basic_dir )
    self.create( src, dim, dir )
  end
  
  def self.advanced( src )
    dim = Rails.configuration.advanced_max_width.to_s + 'x' + Rails.configuration.advanced_max_height.to_s
    dir = UploadUtils.monthDir( Rails.configuration.img_dir, Rails.configuration.advanced_dir )
    self.create( src, dim, dir )
  end
  
  # ImgSize.subregion( "/usr/local/imgcollect/images/2014/SEP/original/travel-to-hungary.jpg", 0.5, 0, 0.5, 0.5 )
  def self.subregion( src, x, y, width, height )
    dir = UploadUtils.monthDir( Rails.configuration.img_dir, Rails.configuration.subregion_dir )
    res = self.uniq_path( src, dir )
    CropWorker.perform_async( src, res, x, y, width, height )
    res['path']
  end
  
  
  def self.create( src, size, dir )
    res = self.uniq_path( src, dir )
    SizeWorker.perform_async( src, size, res )
    res['path']
  end
  
  def self.uniq_path( src, dir )
    file = File.basename( src )
    path = File.join( dir, file )
    UploadUtils.filename( path )
  end
  
end