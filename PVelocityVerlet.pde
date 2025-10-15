// https://github.com/KrabCode/LazyGui
import com.krab.lazy.*;

int INIT_WIDTH = 640;
int INIT_HEIGHT = 360;
int NUM_PARTICLES = 2;

LazyGui gui;
Particle[] particles = new Particle[NUM_PARTICLES];

void settings() {
  size(INIT_WIDTH, INIT_HEIGHT, P2D);
}

void setup() {
  LazyGuiSettings guiSettings = new LazyGuiSettings()
    .setMainFontSize(10)
    .setSideFontSize(10)
    .setHideBuiltInFolders(true);
  gui = new LazyGui(this, guiSettings);
  // start unpaused
  gui.toggleSet("pause", false);
  
  init();
}

void draw() {
  boolean pause = gui.toggle("pause");
  boolean restart = gui.button("restart");
  if (pause) return;
  if(restart) init();

  background(50);
  
  for(Particle particle : particles){
    move(particle);
    checkCollision(particle);
    render(particle);
  }
}


public class Particle {
  public PVector position = new PVector(0, 0);
  public PVector velocity = new PVector(0, 0);
  public PVector acceleration = new PVector(0, 0);
  public float mass = 16.0;
  public float radius = 6.0;
  public float restitution = 1.0;
  public color fill = color(204, 153, 0);
  
  public Particle(PVector position) {
    this.position = position;
  }
  
  public Particle(PVector position, PVector velocity) {
    this.position = position;
    this.velocity = velocity;
  }
  
  public Particle(PVector position, PVector velocity, PVector acceleration) {
    this.position = position;
    this.velocity = velocity;
    this.acceleration = acceleration;
  }
}

void init(){
  
  PVector[] testPositions = { new PVector(0, 100), new PVector(400, 200) };
  PVector[] testVelocity = { new PVector(2, 1), new PVector(-2, 0) };
  color[] testColors = { color(140, 100, 90), color(212, 50, 12) };
  
  for(int i = 0; i < NUM_PARTICLES; i++){
     //PVector position = new PVector(random(width), random(height));
     PVector position = testPositions[i];
     //PVector velocity = new PVector(random(-1, 1), random(-1, 1));
     PVector velocity = testVelocity[i];
     
     particles[i] = new Particle(position, velocity);
     particles[i].fill = testColors[i];
  } 
}

void move(Particle particle){
  particle.position = PVector.add(particle.position, particle.velocity);
  //particle.velocity = particle.velocity.add(particle.acceleration);
}

void render(Particle particle){
  push();
  fill(particle.fill);
  circle(particle.position.x, particle.position.y, 10);
  pop();
}

void checkCollision(Particle p1){
 
  for(Particle p2 : particles){
    if(p1 == p2) continue;
    
    float distance = PVector.dist(p1.position, p2.position);
    float collisionDistance = p1.radius + p2.radius;
    
    if(distance <= collisionDistance){
       collideV2(p1, p2);
       collideV2(p2, p1);
    }
  }
}

void collideV1(Particle p1, Particle p2) {
  float mRatio = (p2.restitution + 1)*p2.mass/(p1.mass + p2.mass);
  PVector vDiff = PVector.sub(p1.velocity, p2.velocity);
  PVector rDiff = PVector.sub(p1.position, p2.position);
  PVector projection = vDiff.mult(PVector.dot(rDiff.normalize(), vDiff)/vDiff.magSq());
  
  p1.velocity = PVector.sub(p1.velocity, projection.mult(mRatio));
}

void collideV2(Particle p1, Particle p2) {
  PVector normal = PVector.sub(p2.position, p1.position).normalize();
  PVector vDiff = PVector.sub(p2.velocity, p1.velocity);
  
  PVector impulse = PVector.mult(normal, PVector.dot(vDiff, normal));
  
  p1.velocity = PVector.add(p1.velocity, PVector.div(impulse, p1.mass));
  p2.velocity = PVector.add(p2.velocity, PVector.div(impulse, p2.mass));
}
