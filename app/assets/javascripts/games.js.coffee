$(document).ready ->
  
    # Some global vars
  window.squareCount = 10*10
  window.width = 39
  window.border = 1
  
  #Create the 10x10 squares and add them to the board
  for i in [0...window.squareCount]
    $('.board').append($('<div/>').addClass('square'))
  
  setupEnemyBoard()  

  ###################       User triggered events      ########################


  # When user clicks on his own board, it is for setting up the ships. Must 
  # check what window.shipFlag is set to in order to find out bow or direction
  $('.square').click ->
    # Only process code if it needs to be
    if window.shipFlag == "bow" || window.shipFlag == "direction"
      $target = $(this)
      position = $target.position()
      coords = getCoords(position.left, position.top)

      # store these coords in global vars so when ships placed, we know where
      # without having to pass this information from the server again
      if window.shipFlag == "bow"
        window.bow = coords
      if window.shipFlag == "direction"
        window.direction = coords

      # AJAX post to app, controller will figure out what to do next
      $.ajax '/setup',
        type: 'POST'
        data: { x: coords.x, y: coords.y, ship: window.shipName, task: window.shipFlag }
        dataType: "script" 


  # If user clicks on an enemy target, send a message to the application
  # to send a nuke request to the BShiP45 server to blow that shit up
  $('.target').click ->
    $target = $(this)
    
    position = $target.position()
    coords = getCoords(position.left, position.top)

    $.ajax '/attack',
      type: 'POST'
      data: { x: coords.x, y: coords.y }
      dataType: "script" 

#########################         Methods       ###############################

# Takes a ship array [name, length] as well as aflags, which indicates whether
# 1) bow is being placed 2) direction is being set or 3) ship is being set down
window.setupMyShips = (ship, shipFlag, redo) ->
  
  # Extract name and length
  name = ship[0]
  length = parseInt(ship[1])

  # Store name and bowDir globally so when user clicks, we know what inforation
  # to pass back ???
  window.shipName = name
  window.shipFlag = shipFlag

  # Instruct the user what to do
  if shipFlag == "bow"
    $('#my_messages').empty()
    $('#my_messages').html("Setup: " + name)

    if redo
      $('#my_messages').append("<p>Invalid placement!  Please " +
          "click on the square where you would like to place the bow of:  " + 
          "your " + name + "( " + length + " long)</p>")  
    else
      $('#my_messages').append("<p>Please click on the square where you would " +
                             "like to place the bow of your " + name + 
                             "( " + length + " long)</p>")

  else if shipFlag == "direction"
    #if redo
    #  $('#my_messages > p').empty().html("Sorry, but that would either place " +
    #    "the " + name + " on top of another ship or on a diagonal!  Please " +
    #    "click a square which is in the direction you would like the ship's " +
    #    "stern to lie.")
    #else
    $('#my_messages > p').empty().html("Please click a square which is in " +
                            "the direction you would like the ship's stern " +
                            "to lie.")
  
  # Or place the ship
  else  # shipFlag == 'place', meaning 'ship' needs to be created and placed
    # Create a bunch of ship-squares
    # For each one, mark with identifiable class, move it to correct position
    # then reclassify as 'ship' class so it can be displayed correctly
    for i in [0...length]
      $('#ships').append($('<div>').addClass('shipPlacing'))
      $shipSquare = $('.shipPlacing')
      placeShip($shipSquare, i)
      $shipSquare.removeClass('shipPlacing').addClass('ship')

    # This flag will let controller to move on to next ship  
    window.shipFlag = 'placed'

    # ajax call to server relaying ship has been placed, trigger then next step
    $.ajax '/setup',
        type: 'POST'
        data: { task: window.shipFlag }
        dataType: "script" 


# Place a 'target' on each square of enemy board
# This 'target' will be used to mark hits/misses
setupEnemyBoard = ->
  for i in [0...window.squareCount]
    $('#targets').append($('<div>').addClass('target'))

  #move these targets into position, one over each square
  for target, i in $('.target')
    x = i % 10
    y = Math.floor(i/10)
    targetPixPos = getPixelPosition(x, y)
    placeItem($(target), targetPixPos.left, targetPixPos.top)


window.enemyAttack = (index, hit, ship, sunk) ->
  if hit == "hit"
    if sunk
      $('#my_messages').html("P45 sunk your " + ship + " !!!")
    else
      $('#my_messages').html("P45 hit your " + ship + " !!!")
    
    $('#ships').append($('<div>').addClass('just_hit'))
    $hit = $('.just_hit')
    hitPix = getPixelPosition(indexToCoords(index).x, indexToCoords(index).y)
    placeItem($hit, hitPix.left, hitPix.top)
    $hit.hide()
    $hit.removeClass('just_hit').addClass('hit')
    $hit.fadeIn(1000)

  else if hit == "already_hit"
    $('#my_messages').html("P45 fired on coordinates that were already hit<br>"+
      "Their bot isn't very smart, is it?")
  else # hit == "miss"
    $('#my_messages').html("P45 missed...")


window.updateMyStats = (hits, misses, sunk_ships) ->
  $('#my_stats h4').html("YOU<hr>")
  $('#my_stats .hits').html("<span class='key'>Hits: </span>" + 
                            "<span class='value'>"+ hits+ "</span>")
  $('#my_stats .misses').html("<span class='key'>Misses: </span>" +
                              "<span class='value'>" + misses+ "</span>")
  $('#my_stats .sunk').html("<span class='key'>Sunk: </span>")
  if sunk_ships != null
    for ship in sunk_ships
      $('#my_stats .sunk').append("<br><span class='value'>" + ship + "</span>")
  
  setTimeout (-> $('#my_messages').empty()), 3000
  setTimeout (->
    $('#enemy_messages').html("Your turn!  Click on an enemy square to fire.")
    ), 3000

window.updateEnemyStats = (hits, misses, sunk_ships) ->
  $('#enemy_stats h4').html("PLATFORM 45<hr>")
  $('#enemy_stats .hits').html("<span class='key'>Hits: </span>" + 
                            "<span class='value'>"+ hits+ "</span>")
  $('#enemy_stats .misses').html("<span class='key'>Misses: </span>" +
                              "<span class='value'>" + misses+ "</span>")
  $('#enemy_stats .sunk').html("<span class='key'>Sunk: </span>")
  if sunk_ships != null  
    for ship in sunk_ships
      $('#enemy_stats .sunk').append("<br><span class='value'>" + ship + "</span>")
  #setTimeout (-> $('#my_messages').html("P45's turn..."), 3000


window.yourTurn = () ->
  

window.gameOver = () ->

#Board coordinate system is... X [0..9], Y [0..9]
                            #from the upper-left corner 0,0 to lower right 9,9
getPixelPosition = (x,y) ->     #Take an x,y position and return pixel counts from upperleft    
  result =
    'left': (x * (window.width+window.border))+'px'
    'top':  (y * (window.width+window.border))+'px'

getCoords = (left, top) ->    #opposite of getPixelPosition - this takes in px, returns coords
  result =  
    'x': left / (window.width + window.border)
    'y': top / (window.width + window.border)

placeItem = ($item, leftLoc, topLoc) ->
  $item.css('left', leftLoc)
  $item.css('top', topLoc)

indexToCoords = (index) ->
  result = 
    'x':  index % 10 
    'y':  Math.floor(index / 10)

placeShip = ($ship, index) ->
  #figure out the x&y coordinates we're placing at the moment
  if window.bow.x == window.direction.x   # ship lies N or S
    if window.bow.y < window.direction.y        # ship lies S
      x = window.bow.x
      y = window.bow.y + index
    else # window.bow.y > window.direction.y    # ship lies N
      x = window.bow.x
      y = window.bow.y - index
  else #window.bow.y == window.direction.y  - ship lies E or W
    if window.bow.x < window.direction.x        # ship lies E
      x = window.bow.x + index
      y = window.bow.y
    else # window.bow.y > window.direction.y    # ship lies W
      x = window.bow.x - index
      y = window.bow.y

  # Once we've determined the x & y coordinates to place square, place it!
  shipPix = getPixelPosition(x, y)
  placeItem($ship, shipPix.left, shipPix.top)