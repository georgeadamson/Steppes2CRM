// Measure the dimensions of all images in the current jQuery array of elements:
// Optional: Specify deep=true to also measure dimensions of all images within the array of elements.
// Required: Provide a callback to receive the measurements. (This is necessary because images are loaded asynchronously)
// The callback will be triggered for every IMG in the jQuery array that has a "src" attribute.
// The callback is passed 2 params:
// - The first param is an object of {width,height,fileSize}.
// - The second param is the temporary IMG element that was used for measuring. (It gets destroyed after callback)
// Inside the callback you can use "this" to refer to the IMG element that was in the original jQuery array. 
// Note that fileSize can only be measured in IE. This value will be 0 in browsers that doe not support IMG.fileSize.
jQuery.fn.imgSize = function(deep,callback){

  callback = callback || deep;
  var $images = this.filter("IMG[src]");
  if(deep) $images.add( this.find("IMG[src]") );

  $images.each(function(){

	  var origImg = this;
	  var url = $(origImg).attr("src");

	  $("<img>").load(function(){
		  var $dummy = $(this), size = { width:$dummy.width(), height:$dummy.height(), fileSize:0 };
		  try{ size.fileSize = parseInt($dummy.attr("fileSize")) || 0 }catch(e){};
		  window.console && console.log && console.log(size);
		  jQuery.isFunction(callback) && callback.apply( origImg, [size,this] );
		  $dummy.remove();
	  })
	  // To be on the safe side, apply inline styles to prevent any css styles affecting our measurements:
	  // (We use a try-catch workaround for IE7 because it raises errors when we try to set maxWidth/maxHeight)
	  .css({ display:"none", width:"auto", height:"auto", minWidth:"auto", minHeight:"auto" })
	  .each(function(){ try{ $(this).css({ maxWidth:"auto", maxHeight:"auto" }) }catch(e){}; })
	  .addClass("imgSize-temp-img")
	  .appendTo(document.body)    // The width/height would be zero if img is not added to DOM.
	  .attr({ src:url });

  });

  return this;
}