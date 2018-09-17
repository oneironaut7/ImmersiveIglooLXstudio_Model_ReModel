import java.util.Arrays;
import java.util.Collections;
import java.util.List;


VenueModel getModel() {
  switch (environment) {
  case SATELLITE: return new Satellite();
  //case ONEDANCE: return new OneDance();
  }
  return null;
}

//------------------------------------------------------------------
static abstract class VenueModel extends LXModel {
    
  static abstract class Config {
    
    static class Strand {
      public final PVector position;
      public final int numPoints;
      public final float y_axis;
      public final float start_deg;
      public final float stop_deg;
      public final float radius;
      
      Strand(PVector position, int numPoints, float y_axis, float start_deg, float stop_deg,float radius ) {
        this.position = position;
        this.numPoints = numPoints;
        this.y_axis = y_axis;
        this.start_deg = start_deg;
        this.stop_deg = stop_deg;
        this.radius = radius;
      }
    }
    
    public abstract PVector[] getRings();
    public abstract Strand[] getStrands();
  }
  
  public final List<Ring> rings;
  public final List<Strand> strands;
  public final List<LXPoint> strandPoints;
  
  protected VenueModel(Config config) {
    super(new Fixture(config));
    //Fixture defines the entire size of installation
    Fixture f = (Fixture) fixtures.get(0);
    rings = Collections.unmodifiableList(Arrays.asList(f.rings));
    final Strand[] strands = new Strand[rings.size() * config.getStrands().length];
    final List<LXPoint> strandPoints = new ArrayList<LXPoint>();
    int a = 0;
    for (Ring ring : rings) {
      for (Strand strand : ring.strands) {
        strands[a++] = strand;
      }
    }
    this.strands = Collections.unmodifiableList(Arrays.asList(strands));
    this.strandPoints = Collections.unmodifiableList(strandPoints);
  }
  
  private static class Fixture extends LXAbstractFixture {
    
    final Ring[] rings;
    
    Fixture(Config config) {
      rings = new Ring[config.getRings().length];
      LXTransform transform = new LXTransform();
      int ci = 0;
      for (PVector pv : config.getRings()) {
        transform.push();
        transform.translate(pv.x, 0, pv.y);
        float theta = atan2(pv.y, pv.x) - HALF_PI;
        transform.rotateY(-theta);
        addPoints(rings[ci] = new Ring(config, ci, transform, theta));
        transform.pop();
        ++ci;
      }
    }
  }
}

//------------------------------------------------------------------

static class Satellite extends VenueModel {
  
  //Radius of Array
  final static float EDGE_LENGTH = 12*FEET;
  final static float HALF_EDGE_LENGTH =EDGE_LENGTH / 2;
  final static float INCIRCLE_RADIUS = HALF_EDGE_LENGTH + EDGE_LENGTH / sqrt(2);
  
  final static PVector[] PLATFORM_POSITIONS = {
    new PVector( 0,0,  101)
  };
  
  final static PVector[] RING_POSITIONS;
  static {
    float ratio = 1;//(INCIRCLE_RADIUS - Ring.RADIUS - 6*INCHES) / INCIRCLE_RADIUS;
    RING_POSITIONS = new PVector[PLATFORM_POSITIONS.length];
    for (int i = 0; i < PLATFORM_POSITIONS.length; ++i) {
      RING_POSITIONS[i] = PLATFORM_POSITIONS[i].copy().mult(ratio);
    }
  };
  final static float y_axis1 = 2*FEET;
  final static float y_axis2 = 7*FEET;
  final static float y_axis3 = 11*FEET;
  final static float y_axis4 = 15*FEET;
  final static float y_axis5 = 18*FEET;
  final static float y_axis6 = 20*FEET;
  final static float y_axis7 = 5*FEET;
  final static float radius1 = 20*FEET;
  final static float radius2 = 18*FEET;
  final static float radius3 = 16*FEET;
  final static float radius4 = 13*FEET;
  final static float radius5 = 9*FEET;
  final static float radius6 = 4*FEET;
  //controls number of RAILS in a column and where they are relative to a central point
  final static VenueModel.Config.Strand[] STRANDS = {
    //(position, num_points, point spacing) 
    //fc board #1
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis1, 310.01, 350, radius1), //Strand 1
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis1, 270.01, 310, radius1), //Strand 2     new VenueModel.Config.Strand(new PVector(0, 0, 0), 32, y_axis7, 0, 180.01, radius1), //Strand 2 //
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis1, 270, 230, radius1), //Strand 3  new VenueModel.Config.Strand(new PVector(0, 0, 0), 32, y_axis7, 360, 180, radius1), //Strand 3 //
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis1, 230.01, 190, radius1), //Strand 4
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis2, 310.01, 350, radius2), //Strand 5
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis2, 270.01, 310, radius2), //Strand 6 
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis2, 270, 230, radius2), //Strand 7
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis2, 230.01, 190, radius2), //Strand 8
    //fc board #2
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 64, y_axis3, -30.01,  30, radius3), //Strand 9
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis3, 270.01, 330, radius3), //Strand 10 
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis3, 270, 215, radius3), //Strand 11
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 64, y_axis3, 215.01, 150, radius3), //Strand 12
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis4, -50.01,  20, radius4), //Strand 13
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis4, 270.01, 340, radius4), //Strand 14
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis4, 270, 205, radius4), //Strand 15
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis4, 205.01, 145, radius4), //Strand 16
    //fc board #3
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 0,  0, 0,  0, 0),                //Strand 17
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 64, y_axis5, -70, 10.01, radius5),  //Strand 18
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 64, y_axis5, 290.1,140, radius5), //Strand 19 
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 64, y_axis5, 140,  10, radius5), //Strand 20
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 0, 0, 0, 0, 0),                  //Strand 21
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis6, -90, 90.01, radius6),  //Strand 22
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis6, 270.01, 90, radius6),  //Strand 23
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 0, 0, 0, 0, 0),                  //Strand 24  
    //fc board #4
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 0, 0, 0,  0, 0),                 //Strand 25
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 64, y_axis3, 90.01, 150, radius3),  //Strand 26 
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis3, 90, 60, radius3),   //Strand 27
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 64, y_axis3, 60.01, 30, radius3),   //Strand 28
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 0, 0, 0,  0, 0),                 //Strand 29
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 64, y_axis4, 90.01, 145, radius4),  //Strand 30
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 64, y_axis4, 90, 20.01, radius4),   //Strand 31
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 0, 0, 0, 0, 0),                  //Strand 32
    //fc board #5
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis1, 130.01, 170, radius1), //Strand 33
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis1, 90.01, 130, radius1),  //Strand 34
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis1, 90, 50, radius1),   //Strand 35
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis1, 50.01, 10, radius1),   //Strand 36
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis2, 130.01, 170, radius2), //Strand 37
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis2, 90.01, 130, radius2),  //Strand 38 
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis2, 90, 50, radius2),   //Strand 39
    new VenueModel.Config.Strand(new PVector(0, 0, 0), 50, y_axis2, 50.01, 10, radius2)   //Strand 40
};
  
  final static VenueModel.Config CONFIG = new VenueModel.Config() {
    public PVector[] getRings() {
      return RING_POSITIONS;
    }
    
    public VenueModel.Config.Strand[] getStrands() {
      return STRANDS;
    }
  };
  
  Satellite() {
    super(CONFIG);
  }
}

//------------------------------------------------------------------


static class Ring extends LXModel {
  
  final static float SPEAKER_ANGLE = 22./180.*PI;
  
  final static float HEIGHT = Strand.HEIGHT;
  //Distance between rails and radius of ARCs
  final static float RADIUS =  20*INCHES;
  
  final int index;
  final float azimuth;
  
  final List<Strand> strands;
  final List<LXPoint> strandPoints;
  
  Ring(VenueModel.Config config, int index, LXTransform transform, float azimuth) {
    super(new Fixture(config, transform));
    this.index = index;
    this.azimuth = azimuth;
    Fixture f = (Fixture) fixtures.get(0);
    this.strands = Collections.unmodifiableList(Arrays.asList(f.strands));
    List<LXPoint> strandPoints = new ArrayList<LXPoint>();
    for (Strand strand : this.strands) {
      for (LXPoint p : strand.points) {
        //This is where the points are added
        strandPoints.add(p);
      }
    }
    this.strandPoints = Collections.unmodifiableList(strandPoints); 
  }
  
  private static class Fixture extends LXAbstractFixture {
    final Strand[] strands;
    
    Fixture(VenueModel.Config config, LXTransform transform) {
      
      // Transform begins on the floor at center of column
      transform.push();
      
      // Strands
      this.strands = new Strand[config.getStrands().length];
      //Places each Rail per Column in its place relative to the height.
      for (int i = 0; i < config.getStrands().length; ++i) {
        VenueModel.Config.Strand strand = config.getStrands()[i]; 
        transform.translate(RADIUS * strand.position.x, 0, RADIUS * strand.position.z);
        addPoints(strands[i] = new Strand(strand, transform));
        transform.translate(-RADIUS * strand.position.x, 0, -RADIUS * strand.position.z);
      }
      
      transform.pop();
    }
  }
}
//------------------------------------------------------------------
static class Strand extends LXModel {
  
  final static int LEFT = 0;
  final static int RIGHT = 1;
  //height used to place arcs
  final static float HEIGHT = 12*FEET;
  
  
  public final float theta;
  
  
  Strand(VenueModel.Config.Strand strand, LXTransform transform) {
    super(new Fixture(strand, transform));
    this.theta = atan2(transform.z(), transform.x());
  }
  
  private static class Fixture extends LXAbstractFixture {
    Fixture(VenueModel.Config.Strand strand, LXTransform transform) {
      float radius = strand.radius;
      float dtr = (2*PI)/360; //degrees to radians 
      float start_rad = strand.start_deg * dtr;
      float total_degrees = (strand.stop_deg*dtr) - (strand.start_deg*dtr); //in radians
      float degree_inc = (total_degrees/strand.numPoints); //in radians
      int count = 0;
      //transform.push();
      //transform.translate(strand.pointSpacing / 2., 0,  0);
      
      for (int i = 0; i < strand.numPoints; ++i) {
        addPoint(new LXPoint(radius* sin(start_rad+ (i*degree_inc)), strand.y_axis, radius* cos(start_rad +(i*degree_inc))));
        ++count;
        }
     if (count == 32){  
        for (int i = 0; i < 32; ++i) {
        addPoint(new LXPoint(0, 0, 0));
        }
      }    
      if (count == 50){  
        for (int i = 0; i < 14; ++i) {
        addPoint(new LXPoint(0, 0, 0));
        }
      }  
      if (count == 0){  
        for (int i = 0; i < 64; ++i) {
        addPoint(new LXPoint(0, 0, 0));
        }
      }  
    //  transform.pop();
    }
  }
}
