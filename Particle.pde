public class Particle {
  public PVector position = new PVector(0, 0);
  public PVector velocity = new PVector(0, 0);
  public PVector acceleration = new PVector(0, 0);
  public Vector cell = new Vector(0, 0);
  
  public color fill = color(0, 0, 0);
  public float mass = 1.0;
  public float radius = 1.0;
  public float restitution = 0.8;
  public float extent = 2.0; // Processing circle method
  public int queryId = -1;
  boolean collided = false;
  boolean grabbed = false;
  
  public Particle() {}
  
  public Particle(float x, float y) {
    this.position = new PVector(x, y);
  }
  
  float getLeft() {
    return this.position.x - this.radius; 
  }
  
  float getTop() {
    return this.position.y - this.radius; 
  }
  
  float getRight() {
    return this.position.x + this.radius; 
  }
  
  float getBottom() {
    return this.position.y + this.radius; 
  }
  
  void reflectX () {
    this.velocity.x = -this.restitution*this.velocity.x;
  }
  
  void reflectY () {
    this.velocity.y = -this.restitution*this.velocity.y;
  }
}
