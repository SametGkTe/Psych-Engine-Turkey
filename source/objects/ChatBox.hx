package objects;

// Dummy ChatBox class to prevent compilation errors
// The actual ChatBox is in online.objects but we don't have online package
class ChatBox extends FlxSprite {
	public var focused:Bool = false;
	
	public function new(camera:FlxCamera) {
		super();
		focused = false;
	}
}
