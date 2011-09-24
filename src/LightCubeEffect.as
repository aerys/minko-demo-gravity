package
{
	import aerys.minko.render.RenderTarget;
	import aerys.minko.render.effect.IRenderingEffect;
	import aerys.minko.render.effect.SinglePassEffect;
	import aerys.minko.render.shader.IShader;
	
	public class LightCubeEffect extends SinglePassEffect implements IRenderingEffect
	{
		private static const SHADER	: IShader	= new LightCubeShader();
		
		public function LightCubeEffect()
		{
			super(SHADER);
		}
	}
}