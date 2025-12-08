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
