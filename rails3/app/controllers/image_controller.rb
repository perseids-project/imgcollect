class ImageController < ImageBase
  
  # Display an image
  # TODO: Secure this sunnamabitch.
  def show
    # If the file doesn't exist return the image error file
    if params[:dir] == nil || params[:format] == nil
      returnFile( errorImg )
    end
    file = File.join( Rails.configuration.img_dir, params[:dir]+'.'+params[:format] )
    
    # Send the image file
    # If the file isn't found then it's processing.
    begin
      returnFile( file )
    rescue
      imgProcessing
    end
  end
  
  # Display an image by passing a URN
  #
  # All of these should work
  # http://127.0.0.1:3000/urn/cite/perseus/forests/1/basic
  # http://127.0.0.1:3000/urn/8/basic
  # http://127.0.0.1:3000/urn/sparql_model/image/8/basic
  # http://127.0.0.1:3000/urn/sparql_model/image/8
  #
  # If size is null then return "path" which is the original size
  def byUrn
    img = CiteHelper.toImgPath( params[:urn], params[:size] )
    returnFile( img )
  rescue
    returnFile( errorImg )
  end
  
  # Get a full image report
  def full
    img = Image.new
    img.byId( params[:id] )
    @img = img.all
    render 'image/full'
  end
  
  # Add image metadata
  def add
    img = Image.new
    img.byId( params[:id] )
    ControllerHelper.cleanParams( params ).each do |key,val|
      img.add( key, val )
    end

    # What will the output look like?
    render :json => { 
      :message => "Success", 
      :img => img.all 
    }
  end
  
  # Update image metadata
  def update
    img = Image.new
    img.byId( params[:id] )
    vals = ControllerHelper.cleanParams( params )
    img.change( vals )
    render :json => { 
      :message => "Success", 
      :img => img.all 
    }
  end
  
  # Upload an image
  def upload
    
    # If no form has been submitted
    if request.post? == false
      render :file => 'app/views/image/upload.haml'
      return
    end
    
    # Save the file
    file = ImgUpload.new
    file.save( params )
    
    # Check the file type because zip files need to be unzipped
    # and certain image files need to be converted too.
    report = Array.new
    case file.ext
    when '.ZIP'
      zipper = ImgUnzip.new
      report = zipper.unzip( file.uploadPath )
    when '.JPG', '.JPEG', '.GIF', '.PNG', '.TIFF', '.TIF'
      
      # Save file to images directory
      report.push( file.toImgDir )

    # Not supported
    else
      render :text => "Filetype is not supported"
      return
    end
    
    # What will become the JSON return
    json = []
    
    # Resize the image & save it in the triplestore
    report.each do |item|
      if item['path'] != nil && item['error'] == nil
        
        # Build the images
        item['thumb'] = ImgSize.thumb( item['path'] )
        item['basic'] = ImgSize.basic( item['path'] )
        item['advanced'] = ImgSize.advanced( item['path'] )
        
        # Create an image record in the triplestore
        image = Image.new
        begin
          image.create({ 
            :user => params[:user].tagify,
            :original => item['original'],
            :path => item['path'], 
            :thumb => item['thumb'], 
            :basic => item['basic'], 
            :advanced => item['advanced'] 
          })
        rescue
          render :json => { :error => 'Error creating image triple.' }
        end
        
        # Get the original dimensions
        size = FastImage.size( item['path'] )
        image.change({
          :width => size[0],
          :height => size[1]
        })
        
        # Update the image record exif metadata
        begin
          exif = ImgMeta.exif( item['path'] )
          image.change( exif );
        rescue
          # No exif data is no big deal... Just move on.
        end
        json.push({ 
          :message => "Success", 
          :urn => image.urn 
        })
      end
    end
    render :json => json
  end
  
end
