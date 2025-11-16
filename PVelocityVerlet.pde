// https://github.com/KrabCode/LazyGui
import com.krab.lazy.*;

final Vector WINDOW = new Vector(640, 360);
final PVector ZERO_FORCE = new PVector(0, 0);
final PVector GRAVITY = new PVector(0, 982.0);
PVector FORCE = ZERO_FORCE;

LazyGui gui;
Grid grid;
Particle[] particles;
Particle grabbed;
ParticleOptions options;

// default settings
public class ParticleOptions {
  public int population = 200;
  public int minRadius = 5;
  public int maxRadius = 10;
  public int maxInitVelocity = 100;
  public int minInitVelocity = -100;
  public float massRatio = 0.5;
  public boolean randomColors = true;
  public boolean gravity = false;
  public color fill = color(132, 180, 202);
}

void settings() {
  size(WINDOW.x, WINDOW.y, P2D);
}

void setup() {
  LazyGuiSettings guiSettings = new LazyGuiSettings()
    .setMainFontSize(10)
    .setSideFontSize(10)
    .setHideBuiltInFolders(true);
  gui = new LazyGui(this, guiSettings);
  // initialize options
  options = new ParticleOptions();
  // start unpaused
  gui.toggleSet("pause", false);
  options.randomColors = gui.toggle("random colors");
  options.fill = gui.colorPicker("color").hex;
  options.gravity = gui.toggle("gravity");
  options.minRadius = clamp(gui.sliderInt("min radius"), 1, 20);
  options.maxRadius = clamp(gui.sliderInt("max radius"), 5, 25);
  options.population = clamp(gui.sliderInt("population"), 2, 200);
  // initialize particles
  initialize();
}

float deltaTime = 0;
int lastTime = 0;
void draw() {
  // delta time calculation
  int currentTime = millis();
  deltaTime = (currentTime - lastTime) / 1000.0f;
  lastTime = currentTime;
  
  boolean pause = false;
  // UI
  if(!gui.isMouseOutsideGui()){
    pause = gui.toggle("pause");
    boolean gravity = gui.toggle("gravity");
    boolean randomColors = gui.toggle("random colors");
    PickerColor particleFill = gui.colorPicker("color", options.fill);
    int minRadius = gui.sliderInt("min radius", options.minRadius, 1, 20);
    int maxRadius = gui.sliderInt("max radius", options.maxRadius, 5, 25);
    int population = gui.sliderInt("population", options.population, 2, 500);
    boolean reset = gui.button("RESET");
    boolean restart = gui.button("RESTART");
    
    if(reset){
      options = new ParticleOptions();
      
      gui.toggleSet("gravity", options.gravity);
      gui.toggleSet("random colors", options.randomColors);
      gui.colorPickerSet("color", options.fill);
      gui.sliderIntSet("min radius", options.minRadius);
      gui.sliderIntSet("max radius", options.maxRadius);
      gui.sliderIntSet("population", options.population);
    }
    
    options.gravity = gravity;
    options.randomColors = randomColors;
    options.fill = particleFill.hex;
    options.minRadius = clamp(minRadius, 1, 20);
    options.maxRadius = clamp(maxRadius, 5, 25);
    options.population = clamp(population, 2, 500);
    
    // UI events
    if (gravity) {
      FORCE = GRAVITY; 
    } else {
      FORCE = ZERO_FORCE;
    }
    
    if (restart) initialize();
  }
   
  if (pause) return;
  
  background(42);
  
  for(Particle particle : particles){
    if(particle != grabbed){   
      move(FORCE, particle);
    }
    contain(particle);
    collideZone(particle);

  }
  
  for(Particle particle : particles){
    render(particle);
  }
}

void mousePressed() {
    if(grabbed != null) return;
    
    Vector cell = grid.place(mouseX, mouseY);
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
    move(ZERO_FORCE, grabbed);
    PVector mouseVelocity = PVector.sub(mousePosition, grabbed.position);
    grabbed.velocity = PVector.add(grabbed.velocity, mouseVelocity);
    grabbed.position = mousePosition;
    grid.update(grabbed);
  }
}

void initialize(){
  grid = new Grid(width, height, options.maxRadius*3);
  particles = new Particle[options.population];
  grabbed = null;
  
  for(int i = 0; i < options.population; i++){
     particles[i] = new Particle();
     Particle p = particles[i];

     p.position = new PVector(random(options.maxRadius, width - options.maxRadius), random(options.maxRadius, height - options.maxRadius));
     p.velocity = new PVector(random(options.minInitVelocity, options.maxInitVelocity), random(options.minInitVelocity, options.maxInitVelocity));
     p.fill = options.randomColors ? color(random(10, 250), random(10, 250), random(10, 250)) : color(options.fill);
     p.radius = random(options.minRadius, options.maxRadius);
     p.mass = p.radius*options.massRatio;
     p.extent = p.radius*2;
     
     grid.add(p);
     
     contain(p);
  }
}

void render(Particle particle){
  push();
  fill(particle.fill);
  circle(particle.position.x, particle.position.y, particle.extent);
  pop(); //<>//
}

void move(PVector force, Particle particle){
  float halfDeltaTimeSq = pow(deltaTime, 2)/2;
  PVector newVelocity =  PVector.mult(particle.velocity, deltaTime);
  PVector newAcceleration = PVector.mult(particle.acceleration, halfDeltaTimeSq);
  particle.position = PVector.add(particle.position, PVector.add(newVelocity, newAcceleration));
      
  checkCollision(particle);
  
  if(particle.collided) return;
  
  particle.acceleration = newAcceleration;
  PVector nextAcceleration = PVector.div(force, particle.mass);
  PVector halfStepVelocity = PVector.add(particle.velocity, PVector.mult(particle.acceleration, deltaTime/2));
  particle.velocity = PVector.add(halfStepVelocity, PVector.mult(nextAcceleration, deltaTime/2));
}

void checkCollision(Particle p1) {
  ArrayList<Particle> zone = grid.getZoneParticles(p1);
  
  for(Particle p2 : zone) {
    if(p2 == p1) continue;
    
    float particleDistance = PVector.dist(p1.position, p2.position);
    float collideDistance = p1.radius + p2.radius;
    
    if(particleDistance <= collideDistance){
      repulse(p1, p2);
      p1.collided = true;
      p2.collided = true;
    }
  } 
}

void collideZone(Particle p1){
  if(!p1.collided) return;
  
  ArrayList<Particle> zoneParticles = grid.getZoneParticles(p1);
  
  for(Particle p2 : zoneParticles){
    if(p1 == p2 || !p2.collided) continue;
    
    collide(p1, p2);
    
    p1.collided = false;
    p2.collided = false;

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
  
  PVector normal1 = PVector.sub(p1.position, p2.position).normalize();
  PVector normal2 = PVector.sub(p2.position, p1.position).normalize();
  
  PVector repulse1 = PVector.mult(normal1, deltaDist);
  PVector repulse2 = PVector.mult(normal2, deltaDist);
  
  p1.position = PVector.add(p1.position, PVector.div(repulse1, p1.mass));
  p2.position = PVector.add(p2.position, PVector.div(repulse2, p2.mass));
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
  Vector cell = grid.place(particle.position.x, particle.position.y);

  if(cell.x == 0 || cell.y == 0 || cell.x == grid.cellCount.x-1 || cell.y == grid.cellCount.y-1){
     containerCollide(particle);
  }

  if(cell.x != particle.cell.x || cell.y != particle.cell.y){
    grid.update(particle);
  }
  
}

int clamp(int input, int min, int max) {
  int result = input > min  && input < max ? input : min;
  if (result > max) result = max;
  
  return result;
}

class Vector {
   int x = 0;
   int y = 0;
   int min = 0;
   int max = 0;
   
   Vector(int x, int y) {
      this.x = x;
      this.y = y;
      this.min = x;
      this.max = y;
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
  public float extent = 2.0; // Processing circle method
  public int queryId = -1;
  boolean collided = false;
  
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
  int queryIds = 0;
  
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
  
  Vector place(float _x, float _y) {
    int x = floor(_x/this.cellSize);
    int y = floor(_y/this.cellSize);
    
    if(x < 0) x = 0;
    if(y < 0) y = 0;
    if(x >= this.cellCount.x) x = this.cellCount.x - 1;
    if(y >= this.cellCount.y) y = this.cellCount.y - 1;
    
    return new Vector(x, y);
  }
  
  void add(Particle particle) {
    Vector cell = this.place(particle.position.x, particle.position.y);
    
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
    Vector topLeft = this.place(particle.getLeft(), particle.getTop());
    Vector bottomRight = this.place(particle.getRight(), particle.getBottom());
    
    int queryId = this.queryIds++;
    ArrayList<Particle> zoneParticles = new ArrayList<Particle>();
    
    if(topLeft.x == bottomRight.x && topLeft.y == bottomRight.y){
        ArrayList<Particle> cellParticles = this.cells[topLeft.x][topLeft.y];
        for(Particle p : cellParticles){
           if(p != particle && p.queryId != queryId) {
             p.queryId = queryId;
             zoneParticles.add(p);
           }
        }
    } else {
      for(int x = topLeft.x; x <= bottomRight.x; x++){
        for(int y = topLeft.y; y <= bottomRight.y; y++){
          ArrayList<Particle> cellParticles = this.cells[x][y];
          for(Particle p : cellParticles){
            if(p != particle && p.queryId != queryId) {
              p.queryId = queryId;
              zoneParticles.add(p);
            }
          }
        }
      }
    }
    
    return zoneParticles;
  }
}
