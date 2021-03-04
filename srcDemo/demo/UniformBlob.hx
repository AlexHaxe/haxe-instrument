package demo;

class UniformBlob {
	public final id:Int;

	public final name:String;

	public final buffer:Any;

	final locations:Map<String, Int>;

	public function new(_name:String, _buffer:Any, _locations:Map<String, Int>) {
		id = 1;
		name = _name;
		buffer = _buffer;
		locations = _locations;
	}

	public function setMatrix(_name:String, _matrix:Any) {
		if (locations.exists(_name)) {
			// final byteOffset = buffer.byteOffset + locations[_name].unsafe();
			final byteMatrix = _matrix;

			// buffer.bytes.blit(byteOffset, byteMatrix.bytes, byteMatrix.byteOffset, 64);
		}
	}

	public function setVector4(_name:String, _vector:Any) {
		if (locations.exists(_name)) {
			// final byteOffset = buffer.byteOffset + locations[_name].unsafe();
			final byteVector = _vector;

			// buffer.bytes.blit(byteOffset, byteVector.bytes, byteVector.byteOffset, 16);
		}
	}
}
