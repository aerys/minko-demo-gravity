package
{
	import aerys.minko.render.Viewport;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.effect.light.LightingStyle;
	import aerys.minko.render.effect.lighting.LightingEffect;
	import aerys.minko.render.renderer.state.TriangleCulling;
	import aerys.minko.scene.node.Loader3D;
	import aerys.minko.scene.node.Model;
	import aerys.minko.scene.node.camera.FirstPersonCamera;
	import aerys.minko.scene.node.group.Group;
	import aerys.minko.scene.node.group.PickableGroup;
	import aerys.minko.scene.node.group.StyleGroup;
	import aerys.minko.scene.node.group.TransformGroup;
	import aerys.minko.scene.node.group.jiglib.BoxSkinGroup;
	import aerys.minko.scene.node.light.PointLight;
	import aerys.minko.scene.node.mesh.IMesh;
	import aerys.minko.scene.node.mesh.modifier.BVHMeshModifier;
	import aerys.minko.scene.node.mesh.modifier.NormalMeshModifier;
	import aerys.minko.scene.node.mesh.primitive.CubeMesh;
	import aerys.minko.scene.node.texture.ColorTexture;
	import aerys.minko.scene.node.texture.ITexture;
	import aerys.minko.scene.visitor.PickingVisitor;
	import aerys.minko.type.jiglib.JiglibPhysics;
	import aerys.minko.type.math.ConstVector4;
	import aerys.minko.type.math.Vector4;
	import aerys.monitor.Monitor;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	import jiglib.cof.JConfig;
	import jiglib.geometry.JPlane;
	
	public class Main extends Sprite
	{
		[Embed("../assets/wall.png")]
		private static const ASSET_WALL_DIFFUSE	: Class;

		private static const CUBE_MESH			: IMesh		= new BVHMeshModifier(new NormalMeshModifier(CubeMesh.cubeMesh));
		private static const CUBE_TEXTURE		: ITexture	= Loader3D.loadAsset(ASSET_WALL_DIFFUSE)[0] as ITexture;
		
		private static const MOUSE_SENSITIVITY	: Number	= .0015;
		private static const WALK_SPEED			: Number	= .5;
		private static const COLORS				: Array		= [0xff0000, 0x00ff00, 0x0000ff, 0xffff00, 0x00ffff, 0xff00ff];
	
		private var _viewport	: Viewport			= new Viewport();
		private var _camera		: FirstPersonCamera	= new FirstPersonCamera();
		private var _cubes		: Group				= new Group();
		private var _light		: PointLight		= new PointLight(0xffffff, .1, 0, 0, new Vector4(0., 10., 0.), 50.);
		//private var _light		: SpotLight			= new SpotLight(0xffffff, 0.1, 0., 128, new Vector4(20, 20, 20), 0, new Vector4(-1, -1, -1), 1., 0.4, 2048);
		private var _scene		: StyleGroup		= new StyleGroup(_camera, _light, _cubes);
	
		private var _speed		: Point				= new Point();
		private var _cursor		: Point				= new Point();
		
		private var _physics	: JiglibPhysics		= new JiglibPhysics(2.);

		public function Main()
		{
			if (stage)
				initialize();
			else
				addEventListener(Event.ADDED_TO_STAGE, initialize);
		}
		
		private function initialize(event : Event = null) : void
		{
			removeEventListener(Event.ENTER_FRAME, initialize);
		
			stage.frameRate = 45.;
			
			initializeMonitor();
			initializeScene();
			initializePhysics();
			initializeInputs();
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		private function initializeMonitor() : void
		{
			Monitor.monitor.watch(_viewport, ["renderingTime", "drawingTime", "numTriangles"]);
			addChild(Monitor.monitor);
		}
		
		private function enterFrameHandler(event : Event) : void
		{
			if (_viewport.visitors.length == 2)
			{
				_viewport.visitors[2] = _viewport.visitors[1];
				_viewport.visitors[1] = new PickingVisitor(2);
			}
			
			var collisions : Boolean = false;
			
			for (var i : int = 0; i < _cubes.numChildren; ++i)
				_cubes[i]..light.diffuse = .5 + Math.sin(i + getTimer() * .001) * .5;
			
			_physics.update();
			
			_camera.walk(_speed.x);
			_camera.strafe(_speed.y);
			if (_camera.position.x > 45.)
				_camera.position.x = 45.;
			else if (_camera.position.x < -45.)
				_camera.position.x = -45.;
			if (_camera.position.z > 45.)
				_camera.position.z = 45.;
			else if (_camera.position.z < -45.)
				_camera.position.z = -45.;
						
			_viewport.render(_scene);
		}
		
		private function initializePhysics() : void
		{
			_physics.system.addBody(new JPlane(null, new Vector3D(0., 1., 0., 0.)));
			_physics.system.addBody(new JPlane(null, new Vector3D(0., -1., 0., -100.)));
			_physics.system.addBody(new JPlane(null, new Vector3D(1., 0., 0., -50.)));
			_physics.system.addBody(new JPlane(null, new Vector3D(-1., 0., 0., -50.)));
			_physics.system.addBody(new JPlane(null, new Vector3D(0., 0., 1., -50.)));
			_physics.system.addBody(new JPlane(null, new Vector3D(0., 0., -1., -50.)));
		}
		
		private function initializeScene() : void
		{
			JConfig.solverType = "FAST";
			//JConfig.doShockStep = true;
			JConfig.angVelThreshold = 0.05;
			//JConfig.numPenetrationRelaxationTimesteps = 2;
			
			_viewport.antiAliasing = 8.;
			_viewport.defaultEffect = new LightingEffect();
			addChild(_viewport);
		
			_camera.position.y = 10.;
			_camera.position.z = -20.;
			_camera.rotation.x = -.3;
			
			var walls	: Model		= new Model(CUBE_MESH, ColorTexture.GREY);
			
			walls.style.set(BasicStyle.TRIANGLE_CULLING, TriangleCulling.FRONT);
			walls.transform.appendUniformScale(100)
						   .appendTranslation(0., 50., 0.);
		
			_scene.addChild(walls);
		
			// cubes
			var cube : BoxSkinGroup = createCube(0x00ff00);
		
			cube.box.x = 2.5;
			cube.box.y = 2.5;
			cube.box.z = 2.5;
			
			cube = createCube(0xff0000);
			cube.box.x = 2.5;
			cube.box.y = 2.5;
			cube.box.z = -2.5;
			
			cube = createCube(0x0000ff);
			cube.box.x = -2.5;
			cube.box.y = 2.5;
			cube.box.z = -2.5;
			
			cube = createCube(0xffff00);
			cube.box.x = -2.5;
			cube.box.y = 2.5;
			cube.box.z = 2.5;
			
			_scene.style.set(LightingStyle.LIGHT_ENABLED, 	true)
						.set(LightingStyle.CAST_SHADOWS,	true)
						.set(LightingStyle.RECEIVE_SHADOWS,	true);
		}
		
		private function initializeInputs() : void
		{
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}
		
		private function createCube(color : int = 0) : BoxSkinGroup
		{
			color ||= COLORS[int(COLORS.length * Math.random())];
			
			var light	: PointLight		= new PointLight(color, 1., 0., 0, ConstVector4.ZERO, 4.);
			var cube	: TransformGroup	= new TransformGroup(CUBE_TEXTURE, CUBE_MESH, light);
			var box		: BoxSkinGroup		= new BoxSkinGroup(5, 5, 5, cube);
			
			cube.name = "transformGroup";
			
			light.name = "light";
			cube.transform.appendUniformScale(5.);
		
			box.rigidBody.x = -15. + Math.random() * 30.;
			box.rigidBody.y = 50.;
			box.rigidBody.z = -15. + Math.random() * 30.;
			box.rigidBody.restitution = .5;
			box.rigidBody.friction = .5;
			
			_physics.system.addBody(box.rigidBody);
			
			var pg : PickableGroup = new PickableGroup(box);
			
			pg.useHandCursor = true;
			pg.addEventListener(MouseEvent.CLICK, function(e : Event) : void
			{
				shoot(box);
			});
			
			_cubes.addChild(pg);
			
			return box;
		}
		
		private function mouseMoveHandler(event : MouseEvent) : void
		{
			if (event.buttonDown)
			{
				_camera.rotation.y -= (event.stageX - _cursor.x) * MOUSE_SENSITIVITY;
				_camera.rotation.x -= (event.stageY - _cursor.y) * MOUSE_SENSITIVITY;
			}		
			
			_cursor.x = event.stageX;
			_cursor.y = event.stageY;
		}
		
		private function keyDownHandler(event : KeyboardEvent) : void
		{
			switch (event.keyCode)
			{
				case Keyboard.PAGE_UP :
					_light.diffuse = Math.min(_light.diffuse + .1, .5);
					break ;
				case Keyboard.PAGE_DOWN :
					_light.diffuse = Math.max(_light.diffuse - .1, 0.);
					break ;
				case Keyboard.UP :
					_speed.x = WALK_SPEED;
					break ;
				case Keyboard.DOWN :
					_speed.x = -WALK_SPEED;
					break ;
				case Keyboard.LEFT :
					_speed.y = WALK_SPEED;
					break ;
				case Keyboard.RIGHT :
					_speed.y = -WALK_SPEED;
					break ;
				case Keyboard.ENTER :
					if (_cubes.numChildren == 12)
					{
						_physics.system.removeBody(_cubes[0].box);
						_cubes.removeChildAt(0);
					}
					createCube();
					break ;
				case Keyboard.SPACE :
					shoot();
					break ;
				/*case Keyboard.D :
					var dof : Boolean = _scene.style.get(DepthOfFieldStyle.DOF_ENABLED)
										as Boolean;
										
					_scene.style.set(DepthOfFieldStyle.DOF_ENABLED, !dof);
					break ;*/
			}
		}
		
		private function shoot(box : BoxSkinGroup = null) : void
		{
			var minDistance 	: Number 		= box ? 0. : int.MAX_VALUE;
			var shootDirection 	: Vector4 		= null;
			
			if (!box)
			{
				for each (var pg : PickableGroup in _cubes)
				{
					var cube : BoxSkinGroup = pg[0];
					var direction : Vector4 = Vector4.subtract(new Vector4(cube.box.x, cube.box.y, cube.box.z),
															   _camera.position);
					
					if (direction.length < minDistance)
					{
						shootDirection = direction;
						minDistance = direction.length;
						box = cube;
					}
				}
			}
			else
			{
				shootDirection = Vector4.subtract(new Vector4(box.rigidBody.x, box.rigidBody.y, box.rigidBody.z),
												  _camera.position);
			}
			
			if (minDistance < 20.)
			{
				shootDirection.normalize()
							  .scaleBy(100.);
				shootDirection.y *= 2.;
				box.rigidBody.applyBodyWorldImpulse(shootDirection.toVector3D(), Vector3D.Y_AXIS);
			}
		}
		
		private function keyUpHandler(event : KeyboardEvent) : void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP :
				case Keyboard.DOWN :
					_speed.x = 0.;
					break ;
				case Keyboard.LEFT :
				case Keyboard.RIGHT :
					_speed.y = 0.;
					break ;
			}
		}
	}
}