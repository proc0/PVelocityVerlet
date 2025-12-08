
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
  
  boolean pause = false;
  PickerColor particleFill;
  boolean reset = false;
  boolean restart = false;
  
  void initialize(LazyGui gui) {
    // force unpaused init
    gui.toggleSet("pause", false);
    // transferring saved values by LazyGui
    randomColors = gui.toggle("random colors");
    fill = gui.colorPicker("color").hex;
    gravity = gui.toggle("gravity");
    minRadius = clamp(gui.sliderInt("min radius"), 1, 20);
    maxRadius = clamp(gui.sliderInt("max radius"), 5, 25);
    population = clamp(gui.sliderInt("population"), 2, 200);
  }
  
  void update(LazyGui gui) {
    pause = gui.toggle("pause");
    gravity = gui.toggle("gravity");
    randomColors = gui.toggle("random colors");
    particleFill = gui.colorPicker("color", fill);
    fill = particleFill.hex;

    minRadius = gui.sliderInt("min radius", minRadius, 1, 20);
    maxRadius = gui.sliderInt("max radius", maxRadius, 5, 25);
    population = gui.sliderInt("population", population, 2, 500);
    reset = gui.button("RESET");
    restart = gui.button("RESTART");
  }
  
  void reset(LazyGui gui) {
    gui.toggleSet("gravity", gravity);
    gui.toggleSet("random colors", randomColors);
    gui.colorPickerSet("color", fill);
    gui.sliderIntSet("min radius", minRadius);
    gui.sliderIntSet("max radius", maxRadius);
    gui.sliderIntSet("population", population);  
  }
}
