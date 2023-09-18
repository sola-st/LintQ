class Father extends int {
  Father() { this in [1 .. 10] }
  string foo() { result = "" }
}

class Foo extends int {
  Foo() { this in [1 .. 5] }
}

class Son1 extends Father {
  override string foo() { result = "Son1" }
}

class Son2 extends Father {
  override string foo() { result = "Son2" }
}

class Son1Instance extends Foo instanceof Father {
  string foo() { result = "Son1Instance" }
}

class Son2Instance extends Foo instanceof Father {
  string foo() { result = "Son2Instance" }
}

class ParentName extends string {
  ParentName() { this in ["dad", "mom"] }
}