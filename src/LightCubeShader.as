package
{
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.shader.ActionScriptShader;
	import aerys.minko.render.shader.SValue;
	import aerys.minko.scene.data.LightData;
	import aerys.minko.scene.data.StyleData;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.scene.data.WorldDataList;
	
	import flash.utils.Dictionary;
	
	/**
	 * This shader is a hack. The hack was discovered has an actual bug
	 * existed in the original lighting shader code. The combination of
	 * a wrong light attenuation and Lambert factor gave this weird result.
	 * 
	 * We thought it was very cool so we re-implemented the buggy shader
	 * in a dedicated effect.
	 *  
	 * @author Jean-Marc Le Roux
	 * 
	 */
	public class LightCubeShader extends ActionScriptShader
	{
		override protected function getOutputColor() : SValue
		{
			var pointLights		: WorldDataList	= getWorldDataList(LightData);
			var numLights		: int			= pointLights.length;
			var illumination	: SValue		= float3(0., 0., 0.);
			
			for (var lightIndex : int = 0; lightIndex < numLights; ++lightIndex)
			{
				var lightPosition 	: SValue 	= getWorldParameter(3, LightData, LightData.LOCAL_POSITION, lightIndex);
				var lightDiffuse	: SValue	= getWorldParameter(3, LightData, LightData.PREMULTIPLIED_DIFFUSE_COLOR, lightIndex);
				var squareLocalDist	: SValue	= getWorldParameter(1, LightData, LightData.SQUARE_LOCAL_DISTANCE, lightIndex);
				
				var lightToPoint 	: SValue 	= subtract(interpolate(vertexPosition), lightPosition);				
				var lightDirection	: SValue	= normalize(lightToPoint);
				var lambertFactor	: SValue	= saturate(interpolate(vertexNormal).dotProduct3(lightDirection));
				
				// hacky hacky...
				var attenuation		: SValue	= saturate(multiply(squareLocalDist,
														   reciprocal(dotProduct3(lightToPoint, lightToPoint))));
				
				// here goes the hack again...
				lightDiffuse.scaleBy(attenuation)
							.scaleBy(.8);
				illumination.incrementBy(lightDiffuse);
			}
			
			var uv		: SValue	= interpolate(vertexUV);
			var diffuse	: SValue	= sampleTexture(BasicStyle.DIFFUSE, uv);
			
			illumination = power(illumination, 1.2);
			
			return float4(multiply(diffuse.rgb, illumination), diffuse.a);
		}
		
		override protected function getOutputPosition() : SValue
		{
			return vertexClipspacePosition;
		}
		
		override public function getDataHash(styleData		: StyleData,
											 transformData	: TransformData,
											 worldData		: Dictionary) : String
		{
			return (worldData[LightData] as WorldDataList).length.toString(16);
		}
	}
}