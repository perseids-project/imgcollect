class CollectionController < ActionController::Base

  #  Create a new collection
  def create
    
    #  If no form has been submitted
    if request.post? == false
      render :json => { :message => "Error" }
      return
    end
    
    #  Clean up the parameters
    vals = ControllerHelper.cleanParams( params )

    #  Build a new collection
    collection = Collection.new
    collection.create({
      :name => vals[ :name ],
      :label => vals[ :label ],
      :user => vals[ :user ].tagify
    });

    #  Output
    render :json => { 
      :message => "Success", 
      :collection => collection.all 
    }
  end
  
  #  Add an image to a collection
  def add_image
    if request.post? == false
      render :json => { :message => "Error" }
      return
    end

    #  Add an image to a collection
    collection = Collection.new
    collection.byId( params[ :collection_id ] )
    image = Image.new
    image.byId( params[ :image_id ] )
    collection.add( :images, image.urn )
    render :json => { 
      :message => "Success", 
      :collection => collection.all 
    }
  end
  
  #  Turn a sparql_model collection into a cite collection
  def citeify
    if request.post? == false
      render :json => { :message => "Error" }
      return
    end

    #  Turn a collection into a CITE collection
    collection = Collection.new
    collection.byId( params[ :collection_id ] )
    collection.cite_urn = params[ :cite_urn ]
    CiteHelper.create( collection )
    render :json => { 
      :message => "Success", 
      :collection => collection.all 
    }
  end
  
  #  Add a subcollection
  def add_subcollection
    if request.post? == false
      render :json => { :message => "Error" }
      return
    end

    #  Add a subcollection to a collection
    collection = Collection.new
    collection.byId( params[ :collection_id ] )
    subcollection = Collection.new
    subcollection.byId( params[ :subcollection_id ] )
    collection.add( :subcollections, subcollection.urn )
    render :json => { 
      :message => "Success", 
      :collection => collection.all 
    }
  end
  
  #  Delete an image from a collection
  def delete_image
    if request.post? == false
      render :json => { :message => "Error" }
      return
    end
    image = Image.new
    image.byId( params[ :image_id ] )
    collection = Collection.new
    collection.byId( params[ :collection_id ] )
    collection.delete( :images, image.urn )
    render :json => { 
      :message => "Success", 
      :collection => collection.all 
    }
  end
  
  # Full collection report
  def report
    cite = params[ :urn ]
    urn = CiteHelper.toSparqlUrn( cite )
    collection = Collection.new
    collection.byId( urn.just_i )
    @col = collection.all
    @map = CiteHelper.citeImageMap( cite );
    render 'collection/report'
  end
  
  # Delete a subcollection
  def delete_subcollection
    if request.post? == false
      render :json => { :message => "Error" }
      return
    end
    collection = Collection.new
    collection.byId( params[ :collection_id ] )
    subcollection = Collection.new
    subcollection.byId( params[ :subcollection_id] )
    collection.delete( :subcollections, subcollection.urn )
    render :json => { 
      :message => "Success", 
      :collection => collection.all 
    }
  end
  
  # Get a full collection
  def full
    col = Collection.new
    col.byId( params[:id] )
    @col = col.all
    render 'collection/full'
  end

  # Get a collection dock  
  def dock
    col = Collection.new
    col.byId( params[:id] )
    @col = col.all
    render 'collection/dock'
  end
  
  #  Recursively retrieve subcollection images
  def image_dig( _collection, _images, _check )

    #  No sequence just exit...
    images = _collection.images
    if images
      images.each do | image |
        _images.push( image )
      end
    end

    #  Recurse subcollection to get associated images.
    #  If they exist of course.
    subs = _collection.subcollections
    if subs
      subs.each do | sub |
        collection = Collection.new
        collection.byId( sub.tagify )

        #  Avoid circular subcollection referencing.
        if _check.include?( collection.urn ) == false
          _check.push( collection.urn )
          _images = image_dig( collection, _images, _check )
        end
      end
    end

    #  Return those images.
    _images
  end

end