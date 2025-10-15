import com.krab.lazy.*;

int INIT_WIDTH = 640;
int INIT_HEIGHT = 360;
int NUM_PARTICLES = 2;


public class Particle {
  public PVector position = new PVector(0, 0);
  public PVector velocity = new PVector(0, 0);
  public PVector acceleration = new PVector(0, 0);
  
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
  
  for(int i = 0; i < NUM_PARTICLES; i++){
     PVector position = new PVector(random(width), random(height));
     PVector velocity = new PVector(random(-1, 1), random(-1, 1));

     particles[i] = new Particle(position, velocity);
  }
}

void draw() {
  boolean pause = gui.toggle("pause");
  if (pause) return;

  background(50);
  
  Motion(particles);
  Render(particles);
}


void Motion(Particle[] particles){
  for(Particle particle : particles){
     particle.position = PVector.add(particle.position, particle.velocity);
     //particle.velocity = particle.velocity.add(particle.acceleration);
  }
}

void Render(Particle[] particles){
  for(Particle particle : particles){
     circle(particle.position.x, particle.position.y, 10); 
  }
}
