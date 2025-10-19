// https://github.com/KrabCode/LazyGui
import com.krab.lazy.*;

Vector WINDOW = new Vector(640, 360);
PVector ZERO_FORCE = new PVector(0, 0);
PVector GRAVITY = new PVector(0, 982.0);
PVector FORCE = ZERO_FORCE;
int POPULATION = 112;

LazyGui gui;
Grid grid;

Particle[] particles = new Particle[POPULATION];

void settings() {
  size(WINDOW.x, WINDOW.y, P2D);
}

void setup() {
  LazyGuiSettings guiSettings = new LazyGuiSettings()
    .setMainFontSize(10)
    .setSideFontSize(10)
    .setHideBuiltInFolders(true);
  gui = new LazyGui(this, guiSettings);
  
  // start unpaused
  gui.toggleSet("pause", false);
  // init particles
  initTest2(POPULATION);
}

float deltaTime = 0;
int lastTime = 0;
void draw() {
  // delta time calculation
  int currentTime = millis();
  deltaTime = (currentTime - lastTime) / 1000.0f;
  lastTime = currentTime;
  
  boolean pause = gui.toggle("pause");
  boolean gravity = gui.toggle("gravity");
  boolean restart = gui.button("restart");
  
  if (pause) return;
  if(restart) initTest2(POPULATION);
  if(gravity) FORCE = GRAVITY; else FORCE = ZERO_FORCE;

  background(50);
  
  for(Particle particle : particles){
    contain(particle);
    collideZone(particle);
  }    
  
  for(Particle particle : particles){
    if(grabbed != particle){   
      move(FORCE, particle);
    }
    collideZone(particle);
    render(particle);
  }
}

Particle grabbed;
void mousePressed() {
    Vector cell = grid.place(new Particle(mouseX, mouseY));
    ArrayList<Particle> zone = grid.cells[cell.x][cell.y];
    
    for(Particle p : zone) {
       if(p.getRight() > mouseX && p.getBottom() > mouseY && p.getLeft() < mouseX && p.getTop() < mouseY) {
          grabbed = p;
          break;
       }
    }
}

void mouseReleased() {
   grabbed = null; 
}

void mouseDragged() {
  if(grabbed != null){
    PVector mousePosition = new PVector(mouseX, mouseY);
    PVector mouseVelocity = PVector.sub(mousePosition, grabbed.position);
    grabbed.velocity = PVector.add(grabbed.velocity, mouseVelocity.mult(2));
    grabbed.position = mousePosition;
    
    ArrayList<Particle> zone = grid.getZoneParticles(grabbed);
   
    for(Particle particle : zone){
      collideZone(particle);
    }
  }
}

void initTest(int numParticles){
  PVector[] testPositions = { new PVector(100, 100), new PVector(300, 200) };
  PVector[] testVelocity = { new PVector(100, 100), new PVector(-100, 0) };
  color[] testColors = { color(250, 50, 50), color(50, 50, 250) };
  
  grid = new Grid(width, height, 6);
  
  for(int i = 0; i < 2; i++){ //<>//
     PVector position = testPositions[i];
     PVector velocity = testVelocity[i];
     
     particles[i] = new Particle();
     particles[i].position = position;
     particles[i].velocity = velocity;
     particles[i].fill = testColors[i];
     
     grid.add(particles[i]);
  }
  
}

void initTest2(int numParticles){
  // TODO: abstract radius (6)
  grid = new Grid(width, height, 12);
  
  for(int i = 0; i < numParticles; i++){
     PVector position = new PVector(random(12, width - 12), random(12, height - 12));
     PVector velocity = new PVector(random(-100, 100), random(-100, 100));
     color fill = color(random(10, 250), random(10, 250), random(10, 250));
     float radius = random(5, 10);
     
     particles[i] = new Particle();
     particles[i].position = position;
     particles[i].velocity = velocity;
     particles[i].fill = fill;
     particles[i].radius = radius;
     particles[i].mass = radius/2;
     
     grid.add(particles[i]);
  }
}

void render(Particle particle){
  push();
  fill(particle.fill);
  circle(particle.position.x, particle.position.y, particle.radius*2);
  pop();
}

void move(PVector force, Particle particle){
  float halfDeltaTimeSq = pow(deltaTime, 2)/2;
  PVector newVelocity =  PVector.mult(particle.velocity, deltaTime);
  PVector newAcceleration = PVector.mult(particle.acceleration, halfDeltaTimeSq);
  particle.position = PVector.add(particle.position, PVector.add(newVelocity, newAcceleration));
  particle.acceleration = newAcceleration;
  
  PVector nextAcceleration = PVector.div(force, particle.mass);
  PVector halfStepVelocity = PVector.add(particle.velocity, PVector.mult(particle.acceleration, deltaTime/2));
  particle.velocity = PVector.add(halfStepVelocity, PVector.mult(nextAcceleration, deltaTime/2));
}

void collideZone(Particle p1){
  ArrayList<Particle> zoneParticles = grid.getZoneParticles(p1);
  
  for(Particle p2 : zoneParticles){
    if(p1 == p2) continue;
    
    float particleDistance = PVector.dist(p1.position, p2.position);
    float collideDistance = p1.radius + p2.radius;
    
    if(particleDistance <= collideDistance){
       collide(p1, p2);
       repulse(p1, p2);
    }
  }
}

void collide(Particle p1, Particle p2) {
  PVector normal = PVector.sub(p1.position, p2.position);
  PVector unitNormal = normal.normalize();
  PVector unitTangent = new PVector(-unitNormal.y, unitNormal.x);
  
  float normalComponent1 = PVector.dot(p1.velocity, unitNormal);
  float tangentComponent1 = PVector.dot(p1.velocity, unitTangent);
  float normalComponent2 = PVector.dot(p2.velocity, unitNormal);
  float tangentComponent2 = PVector.dot(p2.velocity, unitTangent);
  
  float totalMass = p1.mass + p2.mass;
  float normalVelocity1 = (normalComponent1*(p1.mass - p2.mass) + 2*p2.mass*normalComponent2)/totalMass;
  float normalVelocity2 = (normalComponent2*(p2.mass - p1.mass) + 2*p1.mass*normalComponent1)/totalMass;
  
  PVector normalVectorVelocity1 = PVector.mult(unitNormal, normalVelocity1);
  PVector normalVectorVelocity2 = PVector.mult(unitNormal, normalVelocity2);
  PVector tangentVectorVelocity1 = PVector.mult(unitTangent, tangentComponent1);
  PVector tangentVectorVelocity2 = PVector.mult(unitTangent, tangentComponent2);
  
  p1.velocity = PVector.add(normalVectorVelocity1, tangentVectorVelocity1);
  p2.velocity = PVector.add(normalVectorVelocity2, tangentVectorVelocity2);
}

void repulse(Particle p1, Particle p2){
  float particleDistance = PVector.dist(p1.position, p2.position);
  float collideDistance = p1.radius + p2.radius;
  
  float deltaDist = collideDistance - particleDistance;
  float deltaRatio1 = p1.radius/deltaDist;
  float deltaRatio2 = p2.radius/deltaDist;
  
  if(deltaRatio1 < deltaRatio2){
    PVector repulse1 = PVector.mult(PVector.sub(p1.position, p2.position).normalize(), deltaDist);
    p1.position = PVector.add(p1.position, PVector.div(repulse1, p1.mass));
  } else if(deltaRatio2 > deltaRatio1){
    PVector repulse2 = PVector.mult(PVector.sub(p2.position, p1.position).normalize(), deltaDist);
    p2.position = PVector.add(p2.position, PVector.div(repulse2, p2.mass));
  } else {
    PVector repulse1 = PVector.mult(PVector.sub(p1.position, p2.position).normalize(), deltaDist/2);
    PVector repulse2 = PVector.mult(PVector.sub(p2.position, p1.position).normalize(), deltaDist/2);
    
    p1.position = PVector.add(p1.position, PVector.div(repulse1, p1.mass));
    p2.position = PVector.add(p2.position, PVector.div(repulse2, p2.mass));
  }
}

void containerCollide(Particle particle) {
  if(particle.getLeft() < 0) {
    particle.position.x = particle.radius;
    particle.reflectX();
  } else if (particle.getRight() > width) {
    particle.position.x = width - particle.radius;
    particle.reflectX();
  }
  
  if(particle.getTop() < 0){
    particle.position.y = particle.radius;
    particle.reflectY();
  } else if (particle.getBottom() > height) {
    particle.position.y = height - particle.radius;
    particle.reflectY();
  }
}

void contain(Particle particle){
  Vector cell = grid.place(particle);

  if(cell.x == 0 || cell.y == 0 || cell.x == grid.cellCount.x-1 || cell.y == grid.cellCount.y-1){
     containerCollide(particle);
  }

  if(cell.x != particle.cell.x || cell.y != particle.cell.y){
    grid.update(particle);
  } 
}

class Vector {
   int x = 0;
   int y = 0;
   
   Vector(int x, int y) {
      this.x = x;
      this.y = y;
   }
}

public class Particle {
  public PVector position = new PVector(0, 0);
  public PVector velocity = new PVector(0, 0);
  public PVector acceleration = new PVector(0, 0);
  public Vector cell = new Vector(0, 0);
  
  public color fill = color(0, 0, 0);
  public float mass = 1.0;
  public float radius = 1.0;
  public float restitution = 0.8;
  
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

class Grid {
  ArrayList<Particle>[][] cells;
  Vector cellCount;
  int cellSize;
  
  Grid(int gridWidth, int gridHeight, int cellSize){
      this.cellSize = cellSize;
      int columns = ceil(gridWidth/cellSize);
      int rows = ceil(gridHeight/cellSize);
      
      this.cellCount = new Vector(columns, rows);
      this.cells = new ArrayList[columns][rows];
      for(int x = 0; x < columns; x++){
         for(int y = 0; y < rows; y++){
            this.cells[x][y] = new ArrayList<Particle>();
         }
      }
  }
  
  Vector place(Particle particle) {
    int x = (int)particle.position.x/this.cellSize;
    int y = (int)particle.position.y/this.cellSize;
    
    if(x < 0) x = 0;
    if(y < 0) y = 0;
    if(x >= this.cellCount.x) x = this.cellCount.x - 1;
    if(y >= this.cellCount.y) y = this.cellCount.y - 1;
    
    return new Vector(x, y);
  }
  
  void add(Particle particle) {
    Vector cell = this.place(particle);
    
    this.cells[cell.x][cell.y].add(particle);
    particle.cell = cell;
  }
  
  void remove(Particle particle) {
    ArrayList<Particle> cell = this.cells[particle.cell.x][particle.cell.y];
    
     for(int i = 0; i < cell.size(); i++){
        Particle p = cell.get(i);
        if(p == particle){
          cell.remove(i);
          break;
        }
     }
  }
  
  void update(Particle particle) {
     this.remove(particle);
     this.add(particle);
  }
  
  ArrayList<Particle> getZoneParticles(Particle particle) {
    int left = floor((particle.getLeft())/this.cellSize);
    int right = floor((particle.getRight())/this.cellSize);
    int top = floor((particle.getTop())/this.cellSize);
    int bottom = floor((particle.getBottom())/this.cellSize);
    
    ArrayList<Particle> zoneParticles = new ArrayList<Particle>();
    for(int x = left; x <= right; x++){
      for(int y = top; y <= bottom; y++){
        if(x < 0 || y < 0 || x >= this.cellCount.x || y >= this.cellCount.y) continue;
        
        ArrayList<Particle> cellParticles = this.cells[x][y];
        for(Particle p : cellParticles){
           if(p != particle) zoneParticles.add(p);
        }
      }
    }
    
    return zoneParticles;
  }
}
