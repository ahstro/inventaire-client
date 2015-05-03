# dependencies: behaviorsPlugin, paginationPlugin

# to keep in sync with _items_list.scss $itemContainerBaseWidth variable
itemWidth = 230

module.exports = (containerSelector, itemSelector, minWidth=500)->
  # MUST be called with the View it extends as context
  unless _.isView(@)
    throw new Error('should be called with a view as context')

  initMasonry = ->
    itemsPerLine = $('.itemsList').width() / itemWidth
    tooFewItems = @collection.length < itemsPerLine

    unless _.smallScreen(minWidth) or tooFewItems
      _.log 'masonry:reinit'
      container = document.querySelector containerSelector
      new Masonry container,
        itemSelector: itemSelector
        isFitWidth: true
        isResizable: true
        isAnimated: true
        gutter: 5

  refresh = ->
    # wait for images to be loaded
    $(containerSelector).imagesLoaded initMasonry.bind(@)

  @lazyMasonryRefresh = _.debounce refresh.bind(@), 200

  return
