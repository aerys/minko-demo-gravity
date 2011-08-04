package
{
	import aerys.minko.scene.node.group.TransformGroup;
	import aerys.minko.scene.node.group.jiglib.BoxSkinGroup;
	import aerys.minko.scene.node.light.PointLight;
	import aerys.minko.scene.node.mesh.IMesh;
	import aerys.minko.scene.node.mesh.modifier.BVHMeshModifier;
	import aerys.minko.scene.node.mesh.modifier.NormalMeshModifier;
	import aerys.minko.scene.node.mesh.primitive.CubeMesh;
	import aerys.minko.scene.node.texture.ITexture;
	import aerys.minko.type.math.ConstVector4;
	
	import aze.motion.eaze;
	
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.getTimer;
	
	import jiglib.collision.CollisionInfo;
	import jiglib.events.JCollisionEvent;
	
	public class LightCube extends BoxSkinGroup
	{
		private static const CUBE_MESH			: IMesh		= new BVHMeshModifier(new NormalMeshModifier(CubeMesh.cubeMesh));
		private static const COLORS				: Array		= [0xff0000,
															   0x00ff00,
															   0x0000ff,
															   0xffff00,
															   0x00ffff,
															   0xff00ff];
		private static const SOUNDS				: Array		= [new ImpactPianoMonoC1(),
															   new ImpactPianoMonoC2(),
															   new ImpactPianoMonoC3(),
															   new ImpactPianoMonoC4(),
															   new ImpactBowlBlendC1(),
															   new ImpactBowlBlendC2(),
															   new ImpactBowlBlendC3(),
															   new ImpactBowlBlendC4()];
	
		private static const MAX_SOUNDS			: int		= 12;
		private static const SOUND_DELAY		: int		= 100;
		
		private static var _numPlayingSounds	: int		= 0;
	
		private var _sound			: Sound			= null;
		private var _channel		: SoundChannel	= null;
		private var _lastCollision	: int			= 0;
		
		public function get sound() : Sound	{ return _sound; }
		
		public function LightCube(texture : ITexture, color : uint = 0)
		{
			color ||= COLORS[int(COLORS.length * Math.random())];
			
			var light	: PointLight		= new PointLight(color, 1., 0., 0, ConstVector4.ZERO, 4.);
			var cube	: TransformGroup	= new TransformGroup(texture, CUBE_MESH, light);
			
			_sound = SOUNDS[int(Math.random() * SOUNDS.length)];
		
			super(5, 5, 5, cube);

			light.name = "light";
			cube.transform.appendUniformScale(5.);
		
			rigidBody.x = -15. + Math.random() * 30.;
			rigidBody.y = 50.;
			rigidBody.z = -15. + Math.random() * 30.;
//			rigidBody.restitution = .5;
			rigidBody.friction = .5;
			rigidBody.addEventListener(JCollisionEvent.COLLISION_START, collisionStartHandler);
		}
		
		private function collisionStartHandler(event : JCollisionEvent) : void
		{
			var t : int = getTimer();
			
			if (t - _lastCollision < SOUND_DELAY || _numPlayingSounds >= MAX_SOUNDS)
				return ;
			
			_lastCollision = t;
			_numPlayingSounds++;
			
			if (_channel)
			{
			/*	eaze(_channel).to(.5, {volume: 0})
							  .onComplete(_channel.stop)
							  .onComplete(soundCompleteHandler);*/
			}
			_channel = _sound.play(0, 0, new SoundTransform(.1));
			if (_channel)
			{
				_channel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
				eaze(_channel).delay(2.).to(1., {volume: 0})
					.onComplete(_channel.stop)
					.onComplete(soundCompleteHandler);
			}
		}
		
		private function soundCompleteHandler(event : Event = null) : void
		{
			_numPlayingSounds--;
		}
	}
}