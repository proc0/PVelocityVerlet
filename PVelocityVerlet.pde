// https://github.com/KrabCode/LazyGui
import com.krab.lazy.*;

int INIT_WIDTH = 640;
int INIT_HEIGHT = 360;
int NUM_PARTICLES = 2;

LazyGui gui;
Particle[] particles = new Particle[NUM_PARTICLES];
PVector defaultForce = new PVector(0, 0);

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

float deltaTime = 0;
int lastTime = 0;
void draw() {
  int currentTime = millis();
  deltaTime = (currentTime - lastTime) / 1000.0f;
  lastTime = currentTime;
  
  boolean pause = gui.toggle("pause");
  boolean restart = gui.button("restart");
  if (pause) return;
  if(restart) init();
  
  background(50);
  
  for(Particle particle : particles){
    move(defaultForce, particle);
    checkCollision(particle);
    render(particle);
  }
}


public class Particle {
  public PVector position = new PVector(0, 0);
  public PVector velocity = new PVector(0, 0);
  public PVector acceleration = new PVector(0, 0);
  public float mass = 1.0;
  public float radius = 5.0;
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
  
  PVector[] testPositions = { new PVector(100, 100), new PVector(300, 200) };
  PVector[] testVelocity = { new PVector(100, 100), new PVector(-100, 0) };
  color[] testColors = { color(250, 50, 50), color(50, 50, 250) };
  
  for(int i = 0; i < NUM_PARTICLES; i++){
     //PVector position = new PVector(random(width), random(height));
     PVector position = testPositions[i];
     //PVector velocity = new PVector(random(-1, 1), random(-1, 1));
     PVector velocity = testVelocity[i];
     
     particles[i] = new Particle(position, velocity);
     particles[i].fill = testColors[i];
  } 
}

void move(PVector force, Particle particle){
  float halfDeltaTimeSq = pow(deltaTime, 2)/2;
  PVector newVelocity =  PVector.mult(particle.velocity, deltaTime);
  PVector newAcceleration = PVector.mult(particle.acceleration, halfDeltaTimeSq);
  particle.position = PVector.add(particle.position, PVector.add(newVelocity, newAcceleration));
  
  PVector nextAcceleration = PVector.div(force, particle.mass);
  PVector halfStepVelocity = PVector.add(particle.velocity, PVector.mult(particle.acceleration, deltaTime/2));
  particle.velocity = PVector.add(halfStepVelocity, PVector.mult(nextAcceleration, deltaTime/2));
}

void render(Particle particle){
  push();
  fill(particle.fill);
  circle(particle.position.x, particle.position.y, particle.radius*2);
  pop();
}

void checkCollision(Particle p1){
  
  checkBounds(p1);
  //Particle bounds = checkBounds(p1);
   
  //if(bounds.position.x > 0 || bounds.position.y > 0){
  //   collideV1(p1, bounds);
  //}
  
  for(Particle p2 : particles){
    if(p1 == p2) continue;
    
    float distance = PVector.dist(p1.position, p2.position);
    float collisionDistance = p1.radius + p2.radius;
    
    if(distance <= collisionDistance){
       //collideV1(p1, p2);
       //collideV1(p2, p1);
       
       collideV2(p2, p1, collisionDistance - distance);
    }
  }
}

void collideV1(Particle p1, Particle p2) {
  float mRatio = (p1.restitution + 1 + p2.mass)/(p1.mass + p2.mass);
  PVector vDiff = PVector.sub(p1.velocity, p2.velocity);
  PVector rDiff = PVector.sub(p1.position, p2.position);
  PVector projection = vDiff.mult(PVector.dot(rDiff.normalize(), vDiff)/vDiff.magSq());
  
  p1.velocity = PVector.add(p1.velocity, projection.mult(mRatio));
}

void collideV2(Particle p1, Particle p2, float distanceDifference) {
  PVector normal = PVector.sub(p2.position, p1.position).normalize();
  PVector vDiff = PVector.sub(p2.velocity, p1.velocity);
  
  PVector impulse = PVector.mult(normal, PVector.dot(vDiff, normal));
  PVector repulse = PVector.mult(normal, distanceDifference); // reapulsion
  
  p1.velocity = PVector.add(p1.velocity, PVector.div(impulse, p1.mass));
  p1.position = PVector.sub(p1.position, PVector.div(repulse, p1.mass));
  
  p2.velocity = PVector.sub(p2.velocity, PVector.div(impulse, p2.mass));
  p2.position = PVector.add(p2.position, PVector.div(repulse, p2.mass));
}

void checkBounds(Particle p) {
  Particle newP = new Particle(new PVector(0, 0));
 
  if(p.position.x - p.radius < 0) {
    newP.position.x = p.position.x - p.radius;
    newP.position.y = p.position.y;
  } else if (p.position.x + p.radius > width) {
    newP.position.x = p.position.x + p.radius;
    newP.position.y = p.position.y;
  }
  
  if(p.position.y - p.radius < 0){
    newP.position.y = p.position.y - p.radius;
    newP.position.x = p.position.x;
  } else if (p.position.y + p.radius > height) {
    newP.position.y = p.position.y + p.radius;
    newP.position.x = p.position.x;
  }
  
  newP.velocity.x = -p.velocity.x;
  newP.velocity.y = -p.velocity.y;
  newP.acceleration = p.acceleration;
  
  if(newP.position.x != 0 || newP.position.y != 0){
    collideV2(p, newP, 0);
  }
  
}
