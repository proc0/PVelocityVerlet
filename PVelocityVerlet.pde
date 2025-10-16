// https://github.com/KrabCode/LazyGui
import com.krab.lazy.*;

int INIT_WIDTH = 640;
int INIT_HEIGHT = 360;
int NUM_PARTICLES = 62;

LazyGui gui;
Particle[] particles = new Particle[NUM_PARTICLES];
PVector defaultForce = new PVector(0, 98.0);
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
  boolean restart = gui.button("restart");
  
  if (pause) return;
  if(restart) initTest2(NUM_PARTICLES);
  
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

public class Particle {
  public PVector position = new PVector(0, 0);
  public PVector velocity = new PVector(0, 0);
  public PVector acceleration = new PVector(0, 0);
  public PVector cell;
  public color fill = color(204, 153, 0);
  public float mass = 1.1;
  public float radius = 5.0;
  public float restitution = 1.5;
  
  public Particle() {}
}

void initTest(int numParticles){
  PVector[] testPositions = { new PVector(100, 100), new PVector(300, 200) };
  PVector[] testVelocity = { new PVector(100, 100), new PVector(-100, 0) };
  color[] testColors = { color(250, 50, 50), color(50, 50, 250) };
  
  grid = new Grid(width, height, 6);
  
  for(int i = 0; i < numParticles; i++){
     //PVector position = new PVector(random(width), random(height));
     PVector position = testPositions[i];
     //PVector velocity = new PVector(random(-1, 1), random(-1, 1));
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
  grid = new Grid(width, height, 6);
  
  for(int i = 0; i < numParticles; i++){
     PVector position = new PVector(random(12, width - 12), random(12, height - 12));
     PVector velocity = new PVector(random(-100, 100), random(-100, 100));
     color fill = color(random(10, 250), random(10, 250), random(10, 250));
     
     particles[i] = new Particle();
     particles[i].position = position;
     particles[i].velocity = velocity;
     particles[i].fill = fill;
     
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
  Particle newP = new Particle();
 
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
