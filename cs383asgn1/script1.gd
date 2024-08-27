extends Node2D

# Member variables
var screen_size
var pad_size
var direction = Vector2(0, 0)
var startGame = false
var inHelp = false
var leftScore = 0
var rightScore = 0
var lastWinnerLeft = false

# Constants for movement speed
const initialBallSpeed = 80
var ballSpeed = initialBallSpeed
const padSpeed = 150

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var HelpButton = get_node("HelpButton")
	var closeButton = get_node("PauseMenu/CloseHelpButton")
	HelpButton.pressed.connect(self._help_button_pressed)
	closeButton.pressed.connect(self._close_help_menu)
	
	screen_size = get_viewport_rect().size
	pad_size = get_node("PlayerController").get_texture().get_size()
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var ballPosition = get_node("Ball").position
	var UserRect = Rect2( get_node("PlayerController").position - pad_size * .5, pad_size)
	var WallRect = Rect2( get_node("Wall").position - pad_size * .5, pad_size)
	
	var nextPos = ballPosition + direction * ballSpeed * delta
	if(!inHelp):
		ballPosition = nextPos;
	
	# If the ball is touching the upper or lower bounds of the frame, invert the positive vector.
	if((ballPosition.y < 0 and direction.y < 0) or (ballPosition.y > screen_size.y and direction.y > 0)):
		direction.y = -direction.y
	
	# Handle collision with the wall and the user
	if(UserRect.has_point(ballPosition) and direction.x < 0):
		CollideWithRect(ballPosition.y, get_node("PlayerController").position.y)
	else:
			if (WallRect.has_point(ballPosition) and direction.x > 0):
				CollideWithRect(ballPosition.y, get_node("Wall").position.y)
	
	# Check for Game Over
	if (ballPosition.x < 0 or ballPosition.x > screen_size.x):
		var LeftWin = true
		if(ballPosition.x < 0):
			LeftWin = false
		ballPosition = ResetGame(ballPosition, LeftWin)
	
	get_node("Ball").position = ballPosition
	
	# Start Game
	if(Input.is_action_pressed("StartGame") and startGame == false):
		var dir = 0
		if(lastWinnerLeft):
			dir = 1
		else:
			dir = -1
		direction = Vector2(dir, 0)
		startGame = true
		ballSpeed = initialBallSpeed
		print_debug("startGame: %s" % startGame)
	
	# Handle player movement
	var playerPosition = get_node("PlayerController").position
	
	if(playerPosition.y > 0 and Input.is_action_pressed("move_up") and !inHelp):
		playerPosition.y += -padSpeed * delta
	if(playerPosition.y < screen_size.y and Input.is_action_pressed("move_down") and !inHelp):
		playerPosition.y += padSpeed * delta
		
	get_node("PlayerController").position = playerPosition
	
	# Handle "opponent" movement
	var wallPosition = get_node("Wall").position
	
	if(ballPosition.y > wallPosition.y):
		wallPosition.y += padSpeed * delta
	elif(ballPosition.y < wallPosition.y):
		wallPosition.y += -padSpeed * delta
	else:
		wallPosition.y = wallPosition.y
		
	get_node("Wall").position = wallPosition
	
	if(Input.is_action_pressed("ExitGame")):
		get_tree().quit()
	
	
func _help_button_pressed():
	get_tree().paused = true
	get_node("PauseMenu").show()

func _close_help_menu():
	get_node("PauseMenu").hide()
	get_tree().paused = false

func CollideWithRect(p: float, r: float):
	get_node("Sound").play()
	direction.x = -direction.x
	var diff = (p - r)
	if(diff > .5):
		diff = .5
	elif(diff < -.5):
		diff = -.5
	direction.y = diff
	direction = direction.normalized()
	ballSpeed *= 1.25

func ResetGame(ballP: Vector2, LeftWin: bool) -> Vector2:
	print_debug("Entered ResetGame")
	startGame = false
	ballP.x = screen_size.x * .5
	ballP.y = screen_size.y * .5
	ballSpeed = 0
	var score = get_node("Score")
	print_debug("Left Score: %s" % leftScore)
	print_debug("Right Score: %s" % rightScore)
	if(LeftWin):
		leftScore += 1
	else:
		rightScore += 1
	score.text = "%s | %s" % [leftScore , rightScore]
	print_debug("Score: %s" % score.text)
	print_debug("startGame: %s" % startGame)
	return ballP
