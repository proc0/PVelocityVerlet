// https://github.com/KrabCode/LazyGui
import com.krab.lazy.*;

int INIT_WIDTH = 640;
int INIT_HEIGHT = 360;
int NUM_PARTICLES = 112;

LazyGui gui;
Particle[] particles = new Particle[NUM_PARTICLES];
PVector ZERO_FORCE = new PVector(0, 0);
PVector GRAVITY = new PVector(0, 982.0);
PVector defaultForce = ZERO_FORCE;

Grid grid;

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
  
  initTest2(NUM_PARTICLES);
}

float deltaTime = 0;
int lastTime = 0;
void draw() {
  int currentTime = millis();
  deltaTime = (currentTime - lastTime) / 1000.0f;
  lastTime = currentTime;
  
  boolean pause = gui.toggle("pause");
  boolean gravity = gui.toggle("gravity");
  boolean restart = gui.button("restart");
  
  if (pause) return;
  if(restart) initTest2(NUM_PARTICLES);
  if(gravity) defaultForce = defaultForce == GRAVITY ? ZERO_FORCE : GRAVITY;

  background(50);
  
  for(Particle particle : particles){
    checkGridBounds(particle);
  }
  
  for(Particle particle : particles){
    checkCollision(particle);
    move(defaultForce, particle);
    render(particle);
  }
}

Particle grabbed;
void mousePressed() {
    Particle dummy = new Particle();
    dummy.position = new PVector(mouseX, mouseY);
    PVector gridPlace = grid.place(dummy);
    
    ArrayList<Particle> gridCell = grid.cells[(int)gridPlace.x][(int)gridPlace.y];
      
    for(Particle p : gridCell) {
       if(p.position.x + p.radius > mouseX && p.position.y + p.radius > mouseY && p.position.x - p.radius < mouseX && p.position.y - p.radius < mouseY) {
          grabbed = p;
          break;
       }
    }
}

void mouseDragged() {
  if(grabbed != null){
    PVector mouseNormal = PVector.sub(grabbed.position, new PVector(mouseX, mouseY)).normalize();
    move(mouseNormal, grabbed);
  }
}

void mouseReleased() {
   grabbed = null; 
}

public class Particle {
  public PVector position = new PVector(0, 0);
  public PVector velocity = new PVector(0, 0);
  public PVector acceleration = new PVector(0, 0);
  public PVector cell;
  public color fill = color(204, 153, 0);
  public float mass = 1.0;
  public float radius = 5.0;
  public float restitution = 0.8;
  
  public Particle() {}
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
  ArrayList<Particle> neighbors = grid.getAdjacent(p1);
  
  for(Particle p2 : neighbors){
    if(p1 == p2) continue;
    
    float distance = PVector.dist(p1.position, p2.position);
    float collisionDistance = p1.radius + p2.radius;
    
    if(distance <= collisionDistance){
       collide(p1, p2);
       repulse(p1, p2);
    }
  }
}

void collide(Particle p1, Particle p2) {
  // collision
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
  // repulsion
  float distance = PVector.dist(p1.position, p2.position);
  float collisionDistance = p1.radius + p2.radius;
  
  float deltaDist = collisionDistance - distance;
  float deltaRatio1 = p1.radius/deltaDist;
  float deltaRatio2 = p2.radius/deltaDist;
  
  if(deltaRatio1 < deltaRatio2){
    PVector repulse1 = PVector.mult(PVector.sub(p1.position, p2.position).normalize(), deltaDist); // reapulsion
    p1.position = PVector.add(p1.position, PVector.div(repulse1, p1.mass));
  } else if(deltaRatio2 > deltaRatio1){
    PVector repulse2 = PVector.mult(PVector.sub(p2.position, p1.position).normalize(), deltaDist); // reapulsion
    p2.position = PVector.add(p2.position, PVector.div(repulse2, p2.mass));
  } else {
    PVector repulse1 = PVector.mult(PVector.sub(p1.position, p2.position).normalize(), deltaDist/2); // reapulsion
    PVector repulse2 = PVector.mult(PVector.sub(p2.position, p1.position).normalize(), deltaDist/2); // reapulsion
    
    p1.position = PVector.add(p1.position, PVector.div(repulse1, p1.mass));
    p2.position = PVector.add(p2.position, PVector.div(repulse2, p2.mass));
  }
  
}

void checkBounds(Particle p) {
  if(p.position.x - p.radius < 0) {
    p.position.x = p.radius;
    p.velocity.x = -p.restitution*p.velocity.x;
  } else if (p.position.x + p.radius > width) {
    p.position.x = width - p.radius;
    p.velocity.x = -p.restitution*p.velocity.x;
  }
  
  if(p.position.y - p.radius < 0){
    p.position.y = p.radius;
    p.velocity.y = -p.restitution*p.velocity.y;
  } else if (p.position.y + p.radius > height) {
    p.position.y = height - p.radius;
    p.velocity.y = -p.restitution*p.velocity.y;
  }
}

void checkGridBounds(Particle p1){
  PVector p1cell = grid.place(p1);
  int px = (int)p1cell.x;
  int py = (int)p1cell.y;
  
  if(px == 0 || py == 0 || px == grid.numCols-1 || py == grid.numRows-1){
     checkBounds(p1);
  }

  if(px != (int)p1.cell.x || py != (int)p1.cell.y){
    grid.remove(p1);
    grid.add(p1);
  } 
}

class Grid {
  int cellSize = 1;
  int numCols = 5;
  int numRows = 5;
  ArrayList<Particle>[][] cells;
  
  Grid(int gridWidth, int gridHeight, int cellSize){
      this.cellSize = cellSize;
      this.numCols = ceil(gridWidth/cellSize);
      this.numRows = ceil(gridHeight/cellSize);
     
      this.cells = new ArrayList[this.numCols][this.numRows];
      for(int x = 0; x < this.numCols; x++){
         for(int y = 0; y < this.numRows; y++){
            this.cells[x][y] = new ArrayList<Particle>();
         }
      }
  }
  
  PVector place(Particle p) {
    int px = (int)p.position.x/this.cellSize;
    int py = (int)p.position.y/this.cellSize;
    
    if(px < 0) px = 0;
    if(py < 0) py = 0;
    if(px >= this.numCols) px = this.numCols - 1;
    if(py >= this.numRows) py = this.numRows - 1;
    
    return new PVector(px, py);
  }
  
  void add(Particle p) {
    PVector cell = this.place(p);
    
    this.cells[(int)cell.x][(int)cell.y].add(p);
    p.cell = cell;
  }
  
  void remove(Particle p) {
    ArrayList<Particle> cell = this.cells[(int)p.cell.x][(int)p.cell.y];
    
     for(int i = 0; i < cell.size(); i++){
        Particle pi = cell.get(i);
        if(pi == p){
          cell.remove(i);
          break;
        }
     }
  }
  
  ArrayList<Particle> getAdjacent(Particle p) {
    PVector topLeft = new PVector(floor((p.position.x - p.radius)/this.cellSize), floor((p.position.y - p.radius)/this.cellSize)); 
    PVector bottomRight = new PVector(floor((p.position.x + p.radius)/this.cellSize), floor((p.position.y + p.radius)/this.cellSize)); 
    
    ArrayList<Particle> neighbors = new ArrayList<Particle>();
    for(int i = (int)topLeft.x; i <= (int)bottomRight.x; i++){
      for(int j = (int)topLeft.y; j <= (int)bottomRight.y; j++){
        if(i < 0 || j < 0 || i >= this.numCols || j >= this.numRows) continue;
        
        ArrayList<Particle> c = this.cells[i][j];
        for(Particle pij : c){
           if(pij != p) neighbors.add(pij);
        }
      }
    }
    
    return neighbors;
  }
}
