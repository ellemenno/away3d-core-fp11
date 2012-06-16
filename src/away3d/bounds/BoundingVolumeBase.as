package away3d.bounds
{

	import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.errors.AbstractMethodError;
	import away3d.primitives.WireframePrimitiveBase;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * An abstract base class for all bounding volume classes. It should not be instantiated directly.
	 */
	public class BoundingVolumeBase
	{
		protected var _min:Vector3D;
		protected var _max:Vector3D;
		protected var _aabbPoints:Vector.<Number> = new Vector.<Number>();
		protected var _aabbPointsDirty:Boolean = true;
		protected var _boundingRenderable:WireframePrimitiveBase;
		protected var _rayFarT:Number;

		/**
		 * Creates a new BoundingVolumeBase object
		 */
		public function BoundingVolumeBase() {
			_min = new Vector3D();
			_max = new Vector3D();
		}

		public function get boundingRenderable():WireframePrimitiveBase {
			if( !_boundingRenderable ) {
				_boundingRenderable = createBoundingRenderable();
				updateBoundingRenderable();
			}

			return _boundingRenderable;
		}

		protected function updateBoundingRenderable():void {
			throw new AbstractMethodError();
		}

		protected function createBoundingRenderable():WireframePrimitiveBase {
			throw new AbstractMethodError();
		}

		/**
		 * Sets the bounds to zero size.
		 */
		public function nullify():void {
			_min.x = _min.y = _min.z = 0;
			_max.x = _max.y = _max.z = 0;
			_aabbPointsDirty = true;
			if( _boundingRenderable ) updateBoundingRenderable();
		}

		public function disposeRenderable():void {
			if( _boundingRenderable ) _boundingRenderable.dispose();
			_boundingRenderable = null;
		}

		/**
		 * The maximum extreme of the bounds
		 */
		public function get max():Vector3D {
			return _max;
		}

		/**
		 * The minimum extreme of the bounds
		 */
		public function get min():Vector3D {
			return _min;
		}

		/**
		 * Updates the bounds to fit a list of vertices
		 * @param vertices A Vector.&lt;Number&gt; of vertex data to be bounded.
		 */
		public function fromVertices( vertices:Vector.<Number> ):void {
			var i:uint;
			var len:uint = vertices.length;
			var minX:Number, minY:Number, minZ:Number;
			var maxX:Number, maxY:Number, maxZ:Number;

			if( len == 0 ) {
				nullify();
				return;
			}

			var v:Number;

			minX = maxX = vertices[uint( i++ )];
			minY = maxY = vertices[uint( i++ )];
			minZ = maxZ = vertices[uint( i++ )];

			while( i < len ) {
				v = vertices[i++];
				if( v < minX ) minX = v;
				else if( v > maxX ) maxX = v;
				v = vertices[i++];
				if( v < minY ) minY = v;
				else if( v > maxY ) maxY = v;
				v = vertices[i++];
				if( v < minZ ) minZ = v;
				else if( v > maxZ ) maxZ = v;
			}

			fromExtremes( minX, minY, minZ, maxX, maxY, maxZ );
		}

		/**
		 * Updates the bounds to fit a Geometry object.
		 * @param geometry The Geometry object to be bounded.
		 */
		public function fromGeometry( geometry:Geometry ):void {
			var subs:Vector.<SubGeometry> = geometry.subGeometries;
			var lenS:uint = subs.length;
			
			if (lenS > 0 && subs[0].vertexData.length >= 3) {
				var j:uint;
				var lenV:uint;
				var vertices:Vector.<Number>;
				var i:uint;
				var v:Number;
				var minX:Number, minY:Number, minZ:Number;
				var maxX:Number, maxY:Number, maxZ:Number;
	
				minX = maxX = subs[0].vertexData[0];
				minY = maxY = subs[0].vertexData[1];
				minZ = maxZ = subs[0].vertexData[2];
	
				while( j < lenS ) {
					vertices = subs[j++].vertexData;
					lenV = vertices.length;
					i = 0;
					while( i < lenV ) {
						v = vertices[i++];
						if( v < minX ) minX = v;
						else if( v > maxX ) maxX = v;
						v = vertices[i++];
						if( v < minY ) minY = v;
						else if( v > maxY ) maxY = v;
						v = vertices[i++];
						if( v < minZ ) minZ = v;
						else if( v > maxZ ) maxZ = v;
					}
				}
	
				fromExtremes( minX, minY, minZ, maxX, maxY, maxZ );
			}
			else {
				fromExtremes(0,0,0, 0,0,0);
			}
		}

		/**
		 * Sets the bound to fit a given sphere.
		 * @param center The center of the sphere to be bounded
		 * @param radius The radius of the sphere to be bounded
		 */
		public function fromSphere( center:Vector3D, radius:Number ):void {
			// this is BETTER overridden, because most volumes will have shortcuts for this
			// but then again, sphere already overrides it, and if we'd call "fromSphere", it'd probably need a sphere bound anyway
			fromExtremes( center.x - radius, center.y - radius, center.z - radius, center.x + radius, center.y + radius, center.z + radius );
		}

		/**
		 * Sets the bounds to the given extrema.
		 */
		public function fromExtremes( minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number ):void {
			_min.x = minX;
			_min.y = minY;
			_min.z = minZ;
			_max.x = maxX;
			_max.y = maxY;
			_max.z = maxZ;
			_aabbPointsDirty = true;
			if( _boundingRenderable ) updateBoundingRenderable();
		}

		/**
		 * Tests if the bounds are in the camera frustum.
		 * @param mvpMatrix The model view projection matrix for the object to which this bounding box belongs.
		 * @return True if the bounding box is at least partially inside the frustum
		 */
		public function isInFrustum( mvpMatrix:Matrix3D ):Boolean {
			throw new AbstractMethodError();
		}

		/*public function classifyAgainstPlane(plane : Plane3D) : int
		 {
		 throw new AbstractMethodError();
		 return -1;
		 }*/

		/**
		 * Clones the current BoundingVolume object
		 * @return An exact duplicate of this object
		 */
		public function clone():BoundingVolumeBase {
			throw new AbstractMethodError();
		}

		public function get aabbPoints():Vector.<Number> {
			if( _aabbPointsDirty )
				updateAABBPoints();

			return _aabbPoints;
		}

		public function intersectsRay( p:Vector3D, dir:Vector3D ):Number {
			throw new AbstractMethodError();
		}

		public function containsPoint( p:Vector3D ):Boolean {
			throw new AbstractMethodError();
		}

		protected function updateAABBPoints():void {
			var maxX:Number = _max.x, maxY:Number = _max.y, maxZ:Number = _max.z;
			var minX:Number = _min.x, minY:Number = _min.y, minZ:Number = _min.z;
			_aabbPoints[0] = minX;
			_aabbPoints[1] = minY;
			_aabbPoints[2] = minZ;
			_aabbPoints[3] = maxX;
			_aabbPoints[4] = minY;
			_aabbPoints[5] = minZ;
			_aabbPoints[6] = minX;
			_aabbPoints[7] = maxY;
			_aabbPoints[8] = minZ;
			_aabbPoints[9] = maxX;
			_aabbPoints[10] = maxY;
			_aabbPoints[11] = minZ;
			_aabbPoints[12] = minX;
			_aabbPoints[13] = minY;
			_aabbPoints[14] = maxZ;
			_aabbPoints[15] = maxX;
			_aabbPoints[16] = minY;
			_aabbPoints[17] = maxZ;
			_aabbPoints[18] = minX;
			_aabbPoints[19] = maxY;
			_aabbPoints[20] = maxZ;
			_aabbPoints[21] = maxX;
			_aabbPoints[22] = maxY;
			_aabbPoints[23] = maxZ;
			_aabbPointsDirty = false;
		}

		public function get rayFarT():Number {
			return _rayFarT;
		}
	}
}