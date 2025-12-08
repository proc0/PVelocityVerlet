// https://github.com/KrabCode/LazyGui
import com.krab.lazy.*;

// constants
final Vector WINDOW = new Vector(640, 360);
final PVector ZERO_FORCE = new PVector(0, 0);
final PVector GRAVITY = new PVector(0, 982.0);

// globals
PVector force = ZERO_FORCE;
LazyGui gui;
Grid grid;
Particle[] particles;
ParticleOptions options;

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
  // load previous options state
  options.initialize(gui);
  options.update(gui);
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
  
  // UI Options
  if(!gui.isMouseOutsideGui()){
    options.update(gui);
    
    if(options.reset){
      options = new ParticleOptions();
      options.reset(gui);
    }

    if (options.gravity) {
      force = GRAVITY; 
    } else {
      force = ZERO_FORCE;
    }
    
    if (options.restart) initialize();
  }
   
  if (options.pause) return;
  
  background(42);
  
  for(Particle particle : particles){
    if(!particle.grabbed){
      if(particle.isConnected){
        updateSpring(particle);
      }
      
      move(force, particle);
    } else {
      moveGrabbed(particle);
    }
    update(particle);
    collideZone(particle);
  }

  for(Particle particle : particles){
    render(particle);
  }
}

void mousePressed() {
    Vector cell = grid.place(mouseX, mouseY);
    ArrayList<Particle> zone = grid.cells[cell.x][cell.y];
    
    for(Particle particle : zone) {
       if(particle.contains(mouseX, mouseY)) {
          particle.grabbed = true;
          break;
       }
    }
}

void mouseReleased() { //<>//
    Vector cell = grid.place(mouseX, mouseY);
    ArrayList<Particle> zone = grid.cells[cell.x][cell.y];
    
    for(Particle particle : zone) {
       if(particle.grabbed) {
          particle.grabbed = false;
          moveGrabbed(particle);
          if(particle.isConnected){
            updateSpring(particle);
          } else {
            move(ZERO_FORCE, particle);
          }
          break;
       }
    }
}

void initialize(){
  grid = new Grid(width, height, options.maxRadius*4);
  particles = new Particle[options.population];
  
  for(int i = 0; i < options.population; i++){
     particles[i] = new Particle();
     Particle p = particles[i];
      
     p.id = i;
     p.position = new PVector(random(options.maxRadius, width - options.maxRadius), random(options.maxRadius, height - options.maxRadius));
     p.velocity = new PVector(random(options.minInitVelocity, options.maxInitVelocity), random(options.minInitVelocity, options.maxInitVelocity));
     p.fill = options.randomColors ? color(random(10, 250), random(10, 250), random(10, 250)) : color(options.fill);
     p.radius = random(options.minRadius, options.maxRadius);
     p.mass = p.radius*options.massRatio;
     p.extent = p.radius*2;

     grid.add(p);
     
     update(p);
  }
  
  // example connected particles
  // TODO: add method to connected to a mesh?
  for(int j=0; j<4; j++){
    particles[j].isConnected = true;
    particles[j].connections.append(j+1);
    particles[j].restLength = 50;
  }
  
  for(int k=4; k<7; k++){
    particles[k].isConnected = true;
    particles[k].connections.append(k-4);
    particles[k].connections.append(k+1);
    particles[k].restLength = 50;
  }
}

void render(Particle particle){
  if(particle.isConnected){
    for(int pid : particle.connections){
      Particle connected = particles[pid];
      line(particle.position.x, particle.position.y, connected.position.x, connected.position.y);
    }
  }
  fill(particle.fill);
  circle(particle.position.x, particle.position.y, particle.extent);
}

void moveGrabbed(Particle grabbed) {
  PVector mousePosition = new PVector(mouseX, mouseY);
  PVector mouseVelocity = PVector.sub(mousePosition, grabbed.position);
  grabbed.velocity = PVector.add(grabbed.velocity, mouseVelocity);
  grabbed.position = mousePosition;
  repulseZone(grabbed);
}

void move(PVector force, Particle particle){
  float halfDeltaTimeSq = pow(deltaTime, 2)/2;
  PVector newVelocity =  PVector.mult(particle.velocity, deltaTime);
  PVector newAcceleration = PVector.mult(particle.acceleration, halfDeltaTimeSq);
  particle.position = PVector.add(particle.position, PVector.add(newVelocity, newAcceleration));
      
  repulseZone(particle);
  
  if(particle.collided) return;
  
  particle.acceleration = newAcceleration;
  PVector nextAcceleration = PVector.div(force, particle.mass);
  PVector halfStepVelocity = PVector.add(particle.velocity, PVector.mult(particle.acceleration, deltaTime/2));
  particle.velocity = PVector.add(halfStepVelocity, PVector.mult(nextAcceleration, deltaTime/2));
}

void updateSpring(Particle particle){
  for(int pid : particle.connections) {
    Particle connected = particles[pid];
    
    PVector distance = PVector.sub(particle.position, connected.position);
    float distention = distance.mag() - particle.restLength;
    float restoreForce = particle.stiffness * distention; // F = -kx
    PVector repulseForce = PVector.mult(PVector.div(distance, distance.mag()), restoreForce);
    PVector dampingForce = PVector.mult(PVector.sub(particle.velocity, connected.velocity), particle.damping);
    PVector springForce = PVector.add(repulseForce, dampingForce);
    PVector oppositeForce = PVector.mult(springForce, -1);
    
    particle.velocity.add(PVector.div(oppositeForce, particle.mass));
    connected.velocity.add(PVector.div(springForce, connected.mass));
    move(oppositeForce, particle);
    move(springForce, connected);
  }
}

void repulseZone(Particle p1) {
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

void repulse(Particle p1, Particle p2){
  float particleDistance = PVector.dist(p1.position, p2.position);
  float collideDistance = p1.radius + p2.radius;
  
  float deltaDist = collideDistance - particleDistance;
  
  PVector normal1 = PVector.sub(p1.position, p2.position).normalize();
  PVector normal2 = PVector.sub(p2.position, p1.position).normalize();
  
  PVector repulse1 = PVector.mult(normal1, deltaDist);
  PVector repulse2 = PVector.mult(normal2, deltaDist);
  
  if(!p1.grabbed) {
    p1.position = PVector.add(p1.position, PVector.div(repulse1, p1.mass));
  }
  if(!p2.grabbed) { 
    p2.position = PVector.add(p2.position, PVector.div(repulse2, p2.mass));
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
  
  if(!p1.grabbed) {
    p1.velocity = PVector.add(normalVectorVelocity1, tangentVectorVelocity1);
  }
  if(!p2.grabbed) {
    p2.velocity = PVector.add(normalVectorVelocity2, tangentVectorVelocity2);
  }
}

void contain(Particle particle) {
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

void update(Particle particle){
  Vector cell = grid.place(particle.position.x, particle.position.y);

  if(cell.x == 0 || cell.y == 0 || cell.x == grid.cellCount.x-1 || cell.y == grid.cellCount.y-1){
    contain(particle);
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
