import heronarts.lx.modulator.*;
import java.util.Stack;

public static abstract class EnvelopPattern extends LXModelPattern<VenueModel> {

  protected EnvelopPattern(LX lx) {
    super(lx);
  }
}



public static class Test extends LXPattern {

  final CompoundParameter thing = new CompoundParameter("Thing", 0, model.yRange);
  final SinLFO lfo = new SinLFO("Stuff", 0, 1, 2000);

  public Test(LX lx) {
    super(lx);
    addParameter(thing);
    startModulator(lfo);
  }

  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      colors[p.index] = palette.getColor(max(0, 100 - 10*abs(p.y - thing.getValuef())));
    }
  }
}

@LXCategory("Form")
  public class Tron extends LXPattern {

  private final static int MIN_DENSITY = 5;
  private final static int MAX_DENSITY = 80;

  private CompoundParameter period = (CompoundParameter)
    new CompoundParameter("Speed", 150000, 400000, 50000)
    .setExponent(.5)
    .setDescription("Speed of movement");

  private CompoundParameter size = (CompoundParameter)
    new CompoundParameter("Size", 2*FEET, 6*INCHES, 5*FEET)
    .setExponent(2)
    .setDescription("Size of strips");

  private CompoundParameter density = (CompoundParameter)
    new CompoundParameter("Density", 25, MIN_DENSITY, MAX_DENSITY)
    .setDescription("Density of tron strips");

  public Tron(LX lx) {  
    super(lx);
    addParameter("period", this.period);
    addParameter("size", this.size);
    addParameter("density", this.density);    
    for (int i = 0; i < MAX_DENSITY; ++i) {
      addLayer(new Mover(lx, i));
    }
  }

  class Mover extends LXLayer {

    final int index;

    final TriangleLFO pos = new TriangleLFO(0, lx.total, period);

    private final MutableParameter targetBrightness = new MutableParameter(100); 

    private final DampedParameter brightness = new DampedParameter(this.targetBrightness, 50); 

    Mover(LX lx, int index) {
      super(lx);
      this.index = index;
      startModulator(this.brightness);
      startModulator(this.pos.randomBasis());
    }

    public void run(double deltaMs) {
      this.targetBrightness.setValue((density.getValuef() > this.index) ? 100 : 0);
      float maxb = this.brightness.getValuef();
      if (maxb > 0) {
        float pos = this.pos.getValuef();
        float falloff = maxb / size.getValuef();
        for (LXPoint p : model.points) {
          float b = maxb - falloff * LXUtils.wrapdistf(p.index, pos, model.points.length);
          if (b > 0) {
            addColor(p.index, LXColor.gray(b));
          }
        }
      }
    }
  }

  public void run(double deltaMs) {
    setColors(#000000);
  }
}

@LXCategory("Texture")
  public class Noise extends LXPattern {

  public final CompoundParameter scale =
    new CompoundParameter("Scale", 10, 5, 40);

  private final LXParameter scaleDamped =
    startModulator(new DampedParameter(this.scale, 5, 10)); 

  public final CompoundParameter floor =
    new CompoundParameter("Floor", 0, -2, 2)
    .setDescription("Lower bound of the noise");

  private final LXParameter floorDamped =
    startModulator(new DampedParameter(this.floor, .5, 2));    

  public final CompoundParameter range =
    new CompoundParameter("Range", 1, .2, 4)
    .setDescription("Range of the noise");

  private final LXParameter rangeDamped =
    startModulator(new DampedParameter(this.range, .5, 4));

  public final CompoundParameter xSpeed = (CompoundParameter)
    new CompoundParameter("XSpd", 0, -6, 6)
    .setDescription("Rate of motion on the X-axis")
    .setPolarity(LXParameter.Polarity.BIPOLAR);

  public final CompoundParameter ySpeed = (CompoundParameter)
    new CompoundParameter("YSpd", 0, -6, 6)
    .setDescription("Rate of motion on the Y-axis")
    .setPolarity(LXParameter.Polarity.BIPOLAR);

  public final CompoundParameter zSpeed = (CompoundParameter)
    new CompoundParameter("ZSpd", 1, -6, 6)
    .setDescription("Rate of motion on the Z-axis")
    .setPolarity(LXParameter.Polarity.BIPOLAR);

  public final CompoundParameter xOffset = (CompoundParameter)
    new CompoundParameter("XOffs", 0, -1, 1)
    .setDescription("Offset of symmetry on the X-axis")
    .setPolarity(LXParameter.Polarity.BIPOLAR);

  public final CompoundParameter yOffset = (CompoundParameter)
    new CompoundParameter("YOffs", 0, -1, 1)
    .setDescription("Offset of symmetry on the Y-axis")
    .setPolarity(LXParameter.Polarity.BIPOLAR);

  public final CompoundParameter zOffset = (CompoundParameter)
    new CompoundParameter("ZOffs", 0, -1, 1)
    .setDescription("Offset of symmetry on the Z-axis")
    .setPolarity(LXParameter.Polarity.BIPOLAR);

  public Noise(LX lx) {
    super(lx);
    addParameter("scale", this.scale);
    addParameter("floor", this.floor);
    addParameter("range", this.range);
    addParameter("xSpeed", this.xSpeed);
    addParameter("ySpeed", this.ySpeed);
    addParameter("zSpeed", this.zSpeed);
    addParameter("xOffset", this.xOffset);
    addParameter("yOffset", this.yOffset);
    addParameter("zOffset", this.zOffset);
  }

  private class Accum {
    private float accum = 0;
    private int equalCount = 0;

    void accum(double deltaMs, float speed) {
      if (speed != 0) {
        float newAccum = (float) (this.accum + deltaMs * speed * 0.00025);
        if (newAccum == this.accum) {
          if (++this.equalCount >= 5) {
            this.equalCount = 0;
            newAccum = 0;
          }
        }
        this.accum = newAccum;
      }
    }
  };

  private final Accum xAccum = new Accum();
  private final Accum yAccum = new Accum();
  private final Accum zAccum = new Accum();

  @Override
    public void run(double deltaMs) {
    xAccum.accum(deltaMs, xSpeed.getValuef());
    yAccum.accum(deltaMs, ySpeed.getValuef());
    zAccum.accum(deltaMs, zSpeed.getValuef());

    float sf = scaleDamped.getValuef() / 1000.;
    float rf = rangeDamped.getValuef();
    float ff = floorDamped.getValuef();
    float xo = xOffset.getValuef();
    float yo = yOffset.getValuef();
    float zo = zOffset.getValuef();
    for (LXPoint p : model.points) {
      float b = ff + rf * noise(sf*p.x + xo - xAccum.accum, sf*p.y + yo - yAccum.accum, sf*p.z + zo - zAccum.accum);
      colors[p.index] = LXColor.gray(constrain(b*100, 0, 100));
    }
  }
}

//Sets the group to be located in
@LXCategory("Form")
  // Defines the pattern
  public static class Rings extends EnvelopPattern {
  //sets the knob; the variables are defined as (default, min, max)
  //leaving out the min and max defaults to 0 to 1 range
  public final CompoundParameter amplitude =
    new CompoundParameter("Rotation", 0);

  //knob for rotational speed  
  public final CompoundParameter ROTspeed = (CompoundParameter)
    new CompoundParameter("RSpeed", 10000, 20000, 1000)
    .setExponent(.25);

  //Knob for Y speed  
  public final CompoundParameter Yspeed = (CompoundParameter)
    new CompoundParameter("YSpeed", 10000, 40000, 1000)
    .setExponent(.25);  

  public final CompoundParameter thickness =
    new CompoundParameter("Thickness", 40, 10, 100);  

  //defines number of rings; the original stated 2 but 1 looks better for this
  public Rings(LX lx) {
    super(lx);
    for (int i = 0; i < 1; ++i) {
      addLayer(new Ring(lx));
    }
    addParameter("Rotation", this.amplitude);
    addParameter("ROT speed", this.ROTspeed);
    addParameter("Y speed", this.Yspeed);
    addParameter("Thickness", this.thickness);
  }

  //sets color which is white
  public void run(double deltaMs) {
    setColors(#000000);
  }

  //defines the class Ring which is what is added to Rings in the above code
  class Ring extends LXLayer {

    private LXProjection proj = new LXProjection(model);
    // y rotation SawLFO(start value, endvalue, period)
    private final SawLFO yRot = new SawLFO(0, TWO_PI, 9000 + 2000 * Math.random());
    // z rotation SinLFO(start value, endvalue, period)
    private final SinLFO zRot = new SinLFO(-1, 1, ROTspeed);
    // z amplitude
    //private final SinLFO zAmp = new SinLFO(0.5, .5, 13000 + 3000 * Math.random());
    private final SinLFO zAmp = new SinLFO(PI / 10, PI/4, 13000 + 3000 * Math.random());
    //y offset
    //private final SinLFO yOffset = new SinLFO(-2*FEET, 2*FEET, 12000 + 5000*Math.random());
    private final SinLFO yOffset = new SinLFO(-5, 5, Yspeed);

    public Ring(LX lx) {
      super(lx);
      startModulator(yRot.randomBasis());
      startModulator(zRot.randomBasis());
      startModulator(zAmp.randomBasis());
      startModulator(yOffset.randomBasis());
    }

    public void run(double deltaMs) {
      proj.reset().center().rotateY(yRot.getValuef()).rotateZ(amplitude.getValuef() * zAmp.getValuef() * zRot.getValuef());
      float yOffset = this.yOffset.getValuef();
      float falloff = thickness.getValuef();//40; //100 / (2*FEET);
      for (LXVector v : proj) {
        float b = 100 - falloff * abs(v.y - yOffset);  
        if (b > 0) {
          addColor(v.index, LXColor.gray(b));
        }
      }
    }
  }
}

@LXCategory("Form")
  // Defines the pattern
  public static class SawRings extends EnvelopPattern {
  //sets the knob; the variables are defined as (default, min, max)
  //leaving out the min and max defaults to 0 to 1 range
  public final CompoundParameter amplitude =
    new CompoundParameter("Rotation", 0);

  //knob for rotational speed  
  public final CompoundParameter ROTspeed = (CompoundParameter)
    new CompoundParameter("RSpeed", 10000, 20000, 1000)
    .setExponent(.25);

  //Knob for Y speed  
  public final CompoundParameter Yspeed = (CompoundParameter)
    new CompoundParameter("YSpeed", 10000, 40000, 1000)
    .setExponent(.25);  

  public final CompoundParameter thickness = (CompoundParameter)
    new CompoundParameter("Thickness", 40, 0, 100) 
    .setExponent(4.0);  

  public final CompoundParameter SawMin =
    new CompoundParameter("SawMin", -8 *FEET, -20*FEET, 20*FEET);    

  public final CompoundParameter SawMax =
    new CompoundParameter("SawMax", 8*FEET, -20*FEET, 20*FEET);  

  //defines number of rings; the original stated 2 but 1 looks better for this
  public SawRings(LX lx) {
    super(lx);
    for (int i = 0; i < 1; ++i) {
      addLayer(new Ring(lx));
    }
    addParameter("Rotation", this.amplitude);
    addParameter("ROT speed", this.ROTspeed);
    addParameter("Y speed", this.Yspeed);
    addParameter("Thickness", this.thickness);
    addParameter("SawMin", this.SawMin);
    addParameter("SawMax", this.SawMax);
  }

  //sets color in background Hex #000000 is Black
  public void run(double deltaMs) {
    setColors(#000000);
  }

  //defines the class Ring which is what is added to Rings in the above code
  class Ring extends LXLayer {

    private LXProjection proj = new LXProjection(model);
    // y rotation SawLFO(start value, endvalue, period)
    private final SinLFO yRot = new SinLFO(0, TWO_PI, 9000 + 2000 * Math.random());
    // z rotation SinLFO(start value, endvalue, period)
    private final SinLFO zRot = new SinLFO(-1, 1, ROTspeed);
    // z amplitude
    //private final SinLFO zAmp = new SinLFO(0.5, .5, 13000 + 3000 * Math.random());
    private final SinLFO zAmp = new SinLFO(PI / 10, PI/4, 13000 + 3000 * Math.random());
    //y offset
    //private final SinLFO yOffset = new SinLFO(-2*FEET, 2*FEET, 12000 + 5000*Math.random());
    private final SawLFO yOffset = new SawLFO(SawMin, SawMax, Yspeed);

    public Ring(LX lx) {
      super(lx);
      startModulator(yRot.randomBasis());
      startModulator(zRot.randomBasis());
      startModulator(zAmp.randomBasis());
      startModulator(yOffset.randomBasis());
    }

    public void run(double deltaMs) {
      proj.reset().center().rotateY(yRot.getValuef()).rotateZ(amplitude.getValuef() * zAmp.getValuef() * zRot.getValuef());
      float yOffset = this.yOffset.getValuef();
      float falloff = thickness.getValuef();//40; //100 / (2*FEET);
      for (LXVector v : proj) {
        float b = 100 - falloff * abs(v.y - yOffset);  
        if (b > 0) {
          addColor(v.index, LXColor.gray(b));
        }
      }
    }
  }
}

@LXCategory(LXCategory.TEXTURE)
  public class Sparkle extends LXPattern {

  public final SinLFO[] sparkles = new SinLFO[60]; 
  private final int[] map = new int[model.size];

  public Sparkle(LX lx) {
    super(lx);
    for (int i = 0; i < this.sparkles.length; ++i) {
      this.sparkles[i] = (SinLFO) startModulator(new SinLFO(0, random(50, 120), random(2000, 7000)));
    }
    for (int i = 0; i < model.size; ++i) {
      this.map[i] = (int) constrain(random(0, sparkles.length), 0, sparkles.length-1);
    }
  }

  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      colors[p.index] = LXColor.gray(constrain(this.sparkles[this.map[p.index]].getValuef(), 0, 100));
    }
  }
}

@LXCategory(LXCategory.TEXTURE)
  public class Starlight extends LXPattern {

  public final CompoundParameter speed = new CompoundParameter("Speed", 1, 2, .5);
  public final CompoundParameter base = new CompoundParameter("Base", -10, -20, 100);

  public final LXModulator[] brt = new LXModulator[50];
  private final int[] map1 = new int[model.size];
  private final int[] map2 = new int[model.size];

  public Starlight(LX lx) {
    super(lx);
    for (int i = 0; i < this.brt.length; ++i) {
      this.brt[i] = startModulator(new SinLFO(this.base, random(50, 120), new FunctionalParameter() {
        private final float rand = random(1000, 5000);
        public double getValue() {
          return rand * speed.getValuef();
        }
      }
      ).randomBasis());
    }
    for (int i = 0; i < model.size; ++i) {
      this.map1[i] = (int) constrain(random(0, this.brt.length), 0, this.brt.length-1);
      this.map2[i] = (int) constrain(random(0, this.brt.length), 0, this.brt.length-1);
    }
    addParameter("speed", this.speed);
    addParameter("base", this.base);
  }

  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      int i = p.index;
      float brt = this.brt[this.map1[i]].getValuef() + this.brt[this.map2[i]].getValuef(); 
      colors[i] = LXColor.gray(constrain(.5*brt, 0, 100));
    }
  }
}

@LXCategory("MIDI")
  public static class Flash extends LXPattern implements CustomDeviceUI {

  private final BooleanParameter manual =
    new BooleanParameter("Trigger")
    .setMode(BooleanParameter.Mode.MOMENTARY)
    .setDescription("Manually triggers the flash");

  private final BooleanParameter midi =
    new BooleanParameter("MIDI", true)
    .setDescription("Toggles whether the flash is engaged by MIDI note events");

  private final BooleanParameter midiFilter =
    new BooleanParameter("Note Filter")
    .setDescription("Whether to filter specific MIDI note");

  private final DiscreteParameter midiNote = (DiscreteParameter)
    new DiscreteParameter("Note", 0, 128)
    .setUnits(LXParameter.Units.MIDI_NOTE)
    .setDescription("Note to filter for");

  private final CompoundParameter brightness =
    new CompoundParameter("Brt", 100, 0, 100)
    .setDescription("Sets the maxiumum brightness of the flash");

  private final CompoundParameter velocitySensitivity =
    new CompoundParameter("Vel>Brt", .5)
    .setDescription("Sets the amount to which brightness responds to note velocity");

  private final CompoundParameter attack = (CompoundParameter)
    new CompoundParameter("Attack", 50, 25, 1000)
    .setExponent(2)
    .setUnits(LXParameter.Units.MILLISECONDS)
    .setDescription("Sets the attack time of the flash");

  private final CompoundParameter decay = (CompoundParameter)
    new CompoundParameter("Decay", 1000, 50, 10000)
    .setExponent(2)
    .setUnits(LXParameter.Units.MILLISECONDS)
    .setDescription("Sets the decay time of the flash");

  private final CompoundParameter shape = (CompoundParameter)
    new CompoundParameter("Shape", 1, 1, 4)
    .setDescription("Sets the shape of the attack and decay curves");

  private final MutableParameter level = new MutableParameter(0);

  private final ADEnvelope env = new ADEnvelope("Env", 0, level, attack, decay, shape);

  public Flash(LX lx) {
    super(lx);
    addModulator(this.env);
    addParameter("brightness", this.brightness);
    addParameter("attack", this.attack);
    addParameter("decay", this.decay);
    addParameter("shape", this.shape);
    addParameter("velocitySensitivity", this.velocitySensitivity);
    addParameter("manual", this.manual);
    addParameter("midi", this.midi);
    addParameter("midiFilter", this.midiFilter);
    addParameter("midiNote", this.midiNote);
  }

  @Override
    public void onParameterChanged(LXParameter p) {
    if (p == this.manual) {
      if (this.manual.isOn()) {
        level.setValue(brightness.getValue());
      }
      this.env.engage.setValue(this.manual.isOn());
    }
  }

  private boolean isValidNote(MidiNote note) {
    return this.midi.isOn() && (!this.midiFilter.isOn() || (note.getPitch() == this.midiNote.getValuei()));
  }

  @Override
    public void noteOnReceived(MidiNoteOn note) {
    if (isValidNote(note)) {
      level.setValue(brightness.getValue() * lerp(1, note.getVelocity() / 127., velocitySensitivity.getValuef()));
      this.env.engage.setValue(true);
    }
  }

  @Override
    public void noteOffReceived(MidiNote note) {
    if (isValidNote(note)) {
      this.env.engage.setValue(false);
    }
  }

  public void run(double deltaMs) {
    setColors(LXColor.gray(env.getValue()));
  }

  @Override
    public void buildDeviceUI(UI ui, UI2dContainer device) {
    device.setContentWidth(216);
    new UIADWave(ui, 0, 0, device.getContentWidth(), 90).addToContainer(device);

    new UIButton(0, 92, 84, 16).setLabel("Trigger").setParameter(this.manual).setTriggerable(true).addToContainer(device);

    new UIButton(88, 92, 40, 16).setParameter(this.midi).setLabel("Midi").addToContainer(device);

    final UIButton midiFilterButton = (UIButton)
      new UIButton(132, 92, 40, 16)
      .setParameter(this.midiFilter)
      .setLabel("Note")
      .setEnabled(this.midi.isOn())
      .addToContainer(device);

    final UIIntegerBox midiNoteBox = (UIIntegerBox)
      new UIIntegerBox(176, 92, 40, 16)
      .setParameter(this.midiNote)
      .setEnabled(this.midi.isOn() && this.midiFilter.isOn())
      .addToContainer(device);

    new UIKnob(0, 116).setParameter(this.brightness).addToContainer(device);
    new UIKnob(44, 116).setParameter(this.attack).addToContainer(device);
    new UIKnob(88, 116).setParameter(this.decay).addToContainer(device);
    new UIKnob(132, 116).setParameter(this.shape).addToContainer(device);

    final UIKnob velocityKnob = (UIKnob)
      new UIKnob(176, 116)
      .setParameter(this.velocitySensitivity)
      .setEnabled(this.midi.isOn())
      .addToContainer(device);

    this.midi.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter p) {
        velocityKnob.setEnabled(midi.isOn());
        midiFilterButton.setEnabled(midi.isOn());
        midiNoteBox.setEnabled(midi.isOn() && midiFilter.isOn());
      }
    }
    ); 

    this.midiFilter.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter p) {
        midiNoteBox.setEnabled(midi.isOn() && midiFilter.isOn());
      }
    }
    );
  }

  class UIADWave extends UI2dComponent {
    UIADWave(UI ui, float x, float y, float w, float h) {
      super(x, y, w, h);
      setBackgroundColor(ui.theme.getDarkBackgroundColor());
      setBorderColor(ui.theme.getControlBorderColor());

      LXParameterListener redraw = new LXParameterListener() {
        public void onParameterChanged(LXParameter p) {
          redraw();
        }
      };

      brightness.addListener(redraw);
      attack.addListener(redraw);
      decay.addListener(redraw);
      shape.addListener(redraw);
    }

    public void onDraw(UI ui, PGraphics pg) {
      double av = attack.getValue();
      double dv = decay.getValue();
      double tv = av + dv;
      double ax = av/tv * (this.width-1);
      double bv = brightness.getValue() / 100.;

      pg.stroke(ui.theme.getPrimaryColor());
      int py = 0;
      for (int x = 1; x < this.width-2; ++x) {
        int y = (x < ax) ?
          (int) Math.round(bv * (height-4.) * Math.pow(((x-1) / ax), shape.getValue())) :
          (int) Math.round(bv * (height-4.) * Math.pow(1 - ((x-ax) / (this.width-1-ax)), shape.getValue()));
        if (x > 1) {
          pg.line(x-1, height-2-py, x, height-2-y);
        }
        py = y;
      }
    }
  }
}
//-------------------------------------------
//NEW PATTERNS
public static abstract class RotationPattern extends EnvelopPattern {
  
  protected final CompoundParameter rate = (CompoundParameter)
  new CompoundParameter("Rate", .25, .01, 2)
    .setExponent(2)
    .setUnits(LXParameter.Units.HERTZ)
    .setDescription("Rate of the rotation");
    
  protected final SawLFO phase = new SawLFO(0, TWO_PI, new FunctionalParameter() {
    public double getValue() {
      return 1000 / rate.getValue();
    }
  });
  
  protected RotationPattern(LX lx) {
    super(lx);
    startModulator(this.phase);
    addParameter("rate", this.rate);
  }
}
@LXCategory("Form")
public static class Helix extends RotationPattern {
    
  private final CompoundParameter size = (CompoundParameter)
    new CompoundParameter("Size", 10*FEET, 6*INCHES, 20*FEET)
    .setDescription("Size of the corkskrew");
    
  private final CompoundParameter coil = (CompoundParameter)
    new CompoundParameter("Coil", 4*FEET, .25*FEET, 25*FEET)
    .setExponent(.5)
    .setDescription("Coil amount");
    
  private final DampedParameter dampedCoil = new DampedParameter(coil, .2);
  
  public Helix(LX lx) {
    super(lx);
    addParameter("size", this.size);
    addParameter("coil", this.coil);
    startModulator(dampedCoil);
    setColors(0);
  }
  
  public void run(double deltaMs) {
    float phaseV = this.phase.getValuef();
    float sizeV = this.size.getValuef();
    float falloff = 200 / sizeV;
    float coil = this.dampedCoil.getValuef();
    
    for (Strand strand : model.strands) {
      float yp = -sizeV + ((phaseV + (TWO_PI + PI + coil * strand.theta)) % TWO_PI) / TWO_PI * (model.yRange + 2*sizeV);
      float yp2 = -sizeV + ((phaseV + TWO_PI + coil * strand.theta) % TWO_PI) / TWO_PI * (model.yRange + 2*sizeV);
      for (LXPoint p : strand.points) {
        float d1 = 100 - falloff*abs(p.y - yp);
        float d2 = 100 - falloff*abs(p.y - yp2);
        float b = max(d1, d2);
        colors[p.index] = b > 0 ? LXColor.gray(b) : #000000;
      }
    }
  }
}
@LXCategory("Texture")
public static final class Swarm extends EnvelopPattern {
  
  private static final double MIN_PERIOD = 200;
  
  public final CompoundParameter chunkSize =
    new CompoundParameter("Chunk", 10, 5, 20)
    .setDescription("Size of the swarm chunks");
  
  private final LXParameter chunkDamped = startModulator(new DampedParameter(this.chunkSize, 5, 5));
  
  public final CompoundParameter speed =
    new CompoundParameter("Speed", .5, .01, 1)
    .setDescription("Speed of the swarm motion");
    
  public final CompoundParameter oscillation =
    new CompoundParameter("Osc", 0)
    .setDescription("Amoount of oscillation of the swarm speed");
  
  private final FunctionalParameter minPeriod = new FunctionalParameter() {
    public double getValue() {
      return MIN_PERIOD / speed.getValue();
    }
  };
  
  private final FunctionalParameter maxPeriod = new FunctionalParameter() {
    public double getValue() {
      return MIN_PERIOD / (speed.getValue() + oscillation.getValue());
    }
  };
  
  private final SawLFO pos = new SawLFO(0, 1, startModulator(
    new SinLFO(minPeriod, maxPeriod, startModulator(
      new SinLFO(9000, 23000, 49000).randomBasis()
  )).randomBasis()));
  
  private final SinLFO swarmA = new SinLFO(0, 4*PI, startModulator(
    new SinLFO(37000, 79000, 51000)
  ));
  
  private final SinLFO swarmY = new SinLFO(
    startModulator(new SinLFO(model.xMin, model.cx, 19000).randomBasis()),
    startModulator(new SinLFO(model.cx, model.xMax, 23000).randomBasis()),
    startModulator(new SinLFO(14000, 37000, 19000))
  );
  
  private final SinLFO swarmSize = new SinLFO(.6, 1, startModulator(
    new SinLFO(7000, 19000, 11000)
  ));
  
  public final CompoundParameter size =
    new CompoundParameter("Size", 1, 2, .5)
    .setDescription("Size of the overall swarm");
  
  public Swarm(LX lx) {
    super(lx);
    addParameter("chunk", this.chunkSize);
    addParameter("size", this.size);
    addParameter("speed", this.speed);
    addParameter("oscillation", this.oscillation);
    startModulator(this.pos.randomBasis());
    startModulator(this.swarmA);
    startModulator(this.swarmY);
    startModulator(this.swarmSize);
    setColors(#000000);
  }
 
  public void run(double deltaMs) {
    float chunkSize = this.chunkDamped.getValuef();
    float pos = this.pos.getValuef();
    float swarmA = this.swarmA.getValuef();
    float swarmY = this.swarmY.getValuef();
    float swarmSize = this.swarmSize.getValuef() * this.size.getValuef();
    
    for (Ring ring : model.rings) {
      int ri = 0;
      for (Strand strand : ring.strands) {
        for (int i = 0; i < strand.points.length; ++i) {
          LXPoint p = strand.points[i];
          float f = (i % chunkSize) / chunkSize;
          if ((ring.index + ri) % 3 == 2) {
            f = 1-f;
          }
          float fd = 40*LXUtils.wrapdistf(ring.azimuth, swarmA, TWO_PI) + abs(p.x - swarmY);
          fd *= swarmSize;
          colors[p.index] = LXColor.gray(max(0, 100 - fd - (100 + fd) * LXUtils.wrapdistf(f, pos, 1)));
        }
        ++ri;
      }
    }
  }
}

public class Bugs extends EnvelopPattern {
  
  public final CompoundParameter speed = (CompoundParameter)
    new CompoundParameter("Speed", 10, 20, 1)
    .setDescription("Speed of the bugs");
  
  public final CompoundParameter size =
    new CompoundParameter("Size", .1, .005, .4)
    .setDescription("Size of the bugs");
  
  public Bugs(LX lx) {
    super(lx);
    for (Strand strand : model.strands) {
      for (int i = 0; i < 10; ++i) {
        addLayer(new Layer(lx, strand));
      }
    }
    addParameter("speed", this.speed);
    addParameter("size", this.size);
  }
  
  class RandomSpeed extends FunctionalParameter {
    
    private final float rand;
    
    RandomSpeed(float low, float hi) {
      this.rand = random(low, hi);
    }
    
    public double getValue() {
      return this.rand * speed.getValue();
    }
  }
  
  class Layer extends LXModelLayer<VenueModel> {
    
    private final Strand strand;
    private final LXModulator pos = startModulator(new SinLFO(
      startModulator(new SinLFO(0, .5, new RandomSpeed(500, 1000)).randomBasis()),
      startModulator(new SinLFO(.5, 1, new RandomSpeed(500, 1000)).randomBasis()),
      new RandomSpeed(3000, 8000)
    ).randomBasis());
    
    private final LXModulator size = startModulator(new SinLFO(
      startModulator(new SinLFO(.1, .3, new RandomSpeed(500, 1000)).randomBasis()),
      startModulator(new SinLFO(.5, 1, new RandomSpeed(500, 1000)).randomBasis()),
      startModulator(new SinLFO(4000, 14000, random(3000, 18000)).randomBasis())
    ).randomBasis());
    
    Layer(LX lx, Strand strand) {
      super(lx);
      this.strand = strand;
    }
    
    //changed from yn to xn which is y normalized
    public void run(double deltaMs) {
      float size = Bugs.this.size.getValuef() * this.size.getValuef();
      float falloff = 100 / max(size, (1.5*INCHES / model.xRange));
      float pos = this.pos.getValuef();
      for (LXPoint p : this.strand.points) {
        float b = 100 - falloff * abs(p.xn - pos);
        if (b > 0) {
          addColor(p.index, LXColor.gray(b));
        }
      }
    }
  }
  
  public void run(double deltaMs) {
    setColors(#000000);
  }
}
@LXCategory("Form")
public class Bouncing extends LXPattern {
  
  public CompoundParameter gravity = (CompoundParameter)
    new CompoundParameter("Gravity", -200, -10, -400)
    .setExponent(2)
    .setDescription("Gravity factor");
  
  public CompoundParameter size =
    new CompoundParameter("Length", 2*FEET, 1*FEET, 8*FEET)
    .setDescription("Length of the bouncers");
  
  public CompoundParameter amp =
    new CompoundParameter("Height", model.yRange, 1*FEET, model.yRange)
    .setDescription("Height of the bounce");
  
  public Bouncing(LX lx) {
    super(lx);
    addParameter("gravity", this.gravity);
    addParameter("size", this.size);
    addParameter("amp", this.amp);
    for (Ring ring : venue.rings) {
      addLayer(new Bouncer(lx, ring));
    }
  }
  
  class Bouncer extends LXLayer {
    
    private final Ring ring;
    private final Accelerator position;
    
    Bouncer(LX lx, Ring ring) {
      super(lx);
      this.ring = ring;
      this.position = new Accelerator(ring.yMax, 0, gravity);
      startModulator(position);
    }
    
    public void run(double deltaMs) {
      if (position.getValue() < 0) {
        position.setValue(-position.getValue());
        position.setVelocity(sqrt(abs(2 * (amp.getValuef() - random(0, 2*FEET)) * gravity.getValuef()))); 
      }
      float h = palette.getHuef();
      float falloff = 100. / size.getValuef();
      for (Strand strand : ring.strands) {
        for (LXPoint p : strand.points) {
          float b = 100 - falloff * abs(p.y - position.getValuef());
          if (b > 0) {
            addColor(p.index, LXColor.gray(b));
          }
        }
      }
    }
  }
    
  public void run(double deltaMs) {
    setColors(LXColor.BLACK);
  }
}


@LXCategory("Envelop")
public class EnvelopDecode extends EnvelopPattern {
  
  public final CompoundParameter mode = new CompoundParameter("Mode", 0);
  public final CompoundParameter fade = new CompoundParameter("Fade", 1*FEET, 0.001, 6*FEET);
  public final CompoundParameter damping = (CompoundParameter)
    new CompoundParameter("Damping", 10, 10, .1)
    .setExponent(.25);
    
  private final DampedParameter[] dampedDecode = new DampedParameter[envelop.decode.channels.length]; 
  
  public EnvelopDecode(LX lx) {
    super(lx);
    addParameter("mode", mode);
    addParameter("fade", fade);
    addParameter("damping", damping);
    int d = 0;
    for (LXParameter parameter : envelop.decode.channels) {
      startModulator(dampedDecode[d++] = new DampedParameter(parameter, damping));
    }
  }
  
  public void run(double deltaMs) {
    float fv = fade.getValuef();
    float falloff = 100 / fv;
    float mode = this.mode.getValuef();
    float faden = fade.getNormalizedf();
    for (Ring ring : venue.rings) {
      float levelf = this.dampedDecode[ring.index].getValuef();
      float level = levelf * (model.zRange / 2.);
      for (Strand strand : ring.strands) {
        for (LXPoint p : strand.points) {
          float zn = abs(p.z - model.cz);
          float b0 = constrain(falloff * (level - zn), 0, 100);
          float b1max = lerp(100, 100*levelf, faden);
          float b1 = (zn > level) ? max(0, b1max - 80*(zn-level)) : lerp(0, b1max, zn / level); 
          colors[p.index] = LXColor.gray(lerp(b0, b1, mode));
        }
      }
    }
  }
}

@LXCategory("Envelop")
public class EnvelopObjects extends EnvelopPattern implements CustomDeviceUI {
  
  public final CompoundParameter size = new CompoundParameter("Base", 4*FEET, 0, 24*FEET);
  public final BoundedParameter response = new BoundedParameter("Level", 0, 1*FEET, 24*FEET);
  public final CompoundParameter spread = new CompoundParameter("Spread", 1, 1, .2); 
  
  public EnvelopObjects(LX lx) {
    super(lx);
    addParameter("size", this.size);
    addParameter("response", this.response);
    addParameter("spread", this.spread);
    for (Envelop.Source.Channel object : envelop.source.channels) {
      Layer layer = new Layer(lx, object);
      addLayer(layer);
      addParameter("active-" + object.index, layer.active);
    }
  }
  
  public void buildDeviceUI(UI ui, UI2dContainer device) {
    int i = 0;
    for (LXLayer layer : getLayers()) {
      new UIButton((i % 4)*33, (i/4)*28, 28, 24)
      .setLabel(Integer.toString(i+1))
      .setParameter(((Layer)layer).active)
      .setTextAlignment(PConstants.CENTER, PConstants.CENTER)
      .addToContainer(device);
      ++i;
    }
    int knobSpacing = UIKnob.WIDTH + 4;
    new UIKnob(0, 116).setParameter(this.size).addToContainer(device);
    new UIKnob(knobSpacing, 116).setParameter(this.response).addToContainer(device);
    new UIKnob(2*knobSpacing, 116).setParameter(this.spread).addToContainer(device);

    device.setContentWidth(3*knobSpacing - 4);
  }
  
  class Layer extends LXModelLayer<VenueModel> {
    
    private final Envelop.Source.Channel object;
    private final BooleanParameter active = new BooleanParameter("Active", true); 
    
    private final MutableParameter tx = new MutableParameter();
    private final MutableParameter ty = new MutableParameter();
    private final MutableParameter tz = new MutableParameter();
    private final DampedParameter x = new DampedParameter(this.tx, 50*FEET);
    private final DampedParameter y = new DampedParameter(this.ty, 50*FEET);
    private final DampedParameter z = new DampedParameter(this.tz, 50*FEET);
    
    Layer(LX lx, Envelop.Source.Channel object) {
      super(lx);
      this.object = object;
      startModulator(this.x);
      startModulator(this.y);
      startModulator(this.z);
    }
    
    public void run(double deltaMs) {
      if (!this.active.isOn()) {
        return;
      }
      this.tx.setValue(object.tx);
      this.ty.setValue(object.ty);
      this.tz.setValue(object.tz);
      if (object.active) {
        float x = this.x.getValuef();
        float y = this.y.getValuef();
        float z = this.z.getValuef();
        float spreadf = spread.getValuef();
        float falloff = 100 / (size.getValuef() + response.getValuef() * object.getValuef());
        for (LXPoint p : model.strandPoints) {
          float dist = dist(p.x * spreadf,  p.z * spreadf,p.y, x * spreadf,  z * spreadf ,y);
          float b = 100 - dist*falloff;
          if (b > 0) {
            addColor(p.index, LXColor.gray(b));
          }
        }
      }
    }
  }
  
  public void run(double deltaMs) {
    setColors(LXColor.BLACK);
  }
}

@LXCategory("MIDI")
public class NotePattern extends EnvelopPattern {
  
  private final CompoundParameter attack = (CompoundParameter)
    new CompoundParameter("Attack", 50, 25, 1000)
    .setExponent(2)
    .setUnits(LXParameter.Units.MILLISECONDS)
    .setDescription("Sets the attack time of the flash");
    
  private final CompoundParameter decay = (CompoundParameter)
    new CompoundParameter("Decay", 1000, 50, 10000)
    .setExponent(2)
    .setUnits(LXParameter.Units.MILLISECONDS)
    .setDescription("Sets the decay time of the flash");
    
  private final CompoundParameter size = new CompoundParameter("Size", .2)
    .setDescription("Sets the base size of notes");
    
  private final CompoundParameter pitchBendDepth = new CompoundParameter("BendAmt", 0.5)
    .setDescription("Controls the depth of modulation from the Pitch Bend wheel");
  
  private final CompoundParameter modBrightness = new CompoundParameter("Mod>Brt", 0)
    .setDescription("Sets the amount of LFO modulation to note brightness");
  
  private final CompoundParameter modSize = new CompoundParameter("Mod>Sz", 0)
    .setDescription("Sets the amount of LFO modulation to note size");
  
  private final CompoundParameter lfoRate = (CompoundParameter)
    new CompoundParameter("LFOSpd", 500, 1000, 100)
    .setExponent(2)
    .setDescription("Sets the rate of LFO modulation from the mod wheel");
  
  private final CompoundParameter velocityBrightness = new CompoundParameter("Vel>Brt", .5)
    .setDescription("Sets the amount of modulation from note velocity to brightness");
  
  private final CompoundParameter velocitySize = new CompoundParameter("Vel>Size", .5)
    .setDescription("Sets the amount of modulation from note velocity to size");
  
  private final CompoundParameter position = new CompoundParameter("Pos", .5)
    .setDescription("Sets the base position of middle C");
    
  private final CompoundParameter pitchDepth = new CompoundParameter("Note>Pos", 1, .1, 4)
    .setDescription("Sets the amount pitch modulates the position");
    
  private final DiscreteParameter soundObject = new DiscreteParameter("Object", 0, 17)
    .setDescription("Which sound object to follow");
  
  private final LXModulator lfo = startModulator(new SinLFO(0, 1, this.lfoRate));
  
  private float pitchBendValue = 0;
  private float modValue = 0;
  
  private final NoteLayer[] notes = new NoteLayer[128];
  
  public NotePattern(LX lx) {
    super(lx);
    for (int i = 0; i < notes.length; ++i) {
      addLayer(this.notes[i] = new NoteLayer(lx, i));
    }
    addParameter("attack", this.attack);
    addParameter("decay", this.decay);
    addParameter("size", this.size);
    addParameter("pitchBendDepth", this.pitchBendDepth);
    addParameter("velocityBrightness", this.velocityBrightness);
    addParameter("velocitySize", this.velocitySize);
    addParameter("modBrightness", this.modBrightness);
    addParameter("modSize", this.modSize);
    addParameter("lfoRate", this.lfoRate);
    addParameter("position", this.position);
    addParameter("pitchDepth", this.pitchDepth);
    addParameter("soundObject", this.soundObject);
  }
  
  protected class NoteLayer extends LXLayer {
    
    private final int pitch;
    
    private float velocity;
    
    private final MutableParameter level = new MutableParameter(0); 
    
    private final ADEnvelope envelope = new ADEnvelope("Env", 0, level, attack, decay);
    
    NoteLayer(LX lx, int pitch) {
      super(lx);
      this.pitch = pitch;
      addModulator(envelope);
    }
    
    public void run(double deltaMs) {
      float pos = position.getValuef() + pitchDepth.getValuef() * (this.pitch - 64) / 64.;
      float level = envelope.getValuef() * (1 - modValue * modBrightness.getValuef() * lfo.getValuef()); 
      if (level > 0) {        
        float xn = pos + pitchBendDepth.getValuef() * pitchBendValue;
        float sz =
          size.getValuef() +
          velocity * velocitySize.getValuef() +
          modValue * modSize.getValuef() * (lfo.getValuef() - .5); 
        
        Envelop.Source.Channel sourceChannel = null;
        int soundObjectIndex = soundObject.getValuei();
        if (soundObjectIndex > 0) {
          sourceChannel = envelop.source.channels[soundObjectIndex - 1];
        }
        
        float falloff = 50.f / sz;
      for (Strand strand : venue.strands) {
          float l2 = level;
          if (sourceChannel != null) {
            float l2fall = 100 / (20*FEET);
            l2 = level - l2fall * max(0, dist(sourceChannel.tx, sourceChannel.tz, strand.cx, strand.cz) - 2*FEET);
          } 
          for (LXPoint p : strand.points) {
            float b = l2 - falloff * abs(p.xn - xn);
            if (b > 0) {
              addColor(p.index, LXColor.gray(b));
            }
          }
        }
      }
    }
  }
  
  @Override
  public void noteOnReceived(MidiNoteOn note) {
    NoteLayer noteLayer = this.notes[note.getPitch()];
    noteLayer.velocity = note.getVelocity() / 127.;
    noteLayer.level.setValue(lerp(100.f, noteLayer.velocity * 100, this.velocityBrightness.getNormalizedf()));
    noteLayer.envelope.engage.setValue(true);
  }
  
  @Override
  public void noteOffReceived(MidiNote note) {
    this.notes[note.getPitch()].envelope.engage.setValue(false);
  }
  
  @Override
  public void pitchBendReceived(MidiPitchBend pb) {
    this.pitchBendValue = (float) pb.getNormalized();
  }
  
  @Override
  public void controlChangeReceived(MidiControlChange cc) {
    if (cc.getCC() == MidiControlChange.MOD_WHEEL) {
      this.modValue = (float) cc.getNormalized();
    }
  }
  
  public void run(double deltaMs) {
    setColors(#000000);
  }
}

@LXCategory("Form")
public static class Warble extends RotationPattern {
  
  private final CompoundParameter size = (CompoundParameter)
    new CompoundParameter("Size", 2*FEET, 6*INCHES, 12*FEET)
    .setDescription("Size of the warble");
    
  private final CompoundParameter depth = (CompoundParameter)
    new CompoundParameter("Depth", .4, 0, 1)
    .setExponent(2)
    .setDescription("Depth of the modulation");
  
  private final CompoundParameter interp = 
    new CompoundParameter("Interp", 1, 1, 3)
    .setDescription("Interpolation on the warble");
    
  private final DampedParameter interpDamped = new DampedParameter(interp, .5, .5);
  private final DampedParameter depthDamped = new DampedParameter(depth, .4, .4);
    
  public Warble(LX lx) {
    super(lx);
    startModulator(this.interpDamped);
    startModulator(this.depthDamped);
    addParameter("size", this.size);
    addParameter("interp", this.interp);
    addParameter("depth", this.depth);
    setColors(0);
  }
  
  public void run(double deltaMs) {
    float phaseV = this.phase.getValuef();
    float interpV = this.interpDamped.getValuef();
    int mult = floor(interpV);
    float lerp = interpV % mult;
    float falloff = 200 / size.getValuef();
    float depth = this.depthDamped.getValuef();
    for (Strand strand : model.strands) {
      float y1 = model.yRange * depth * sin(phaseV + mult * strand.theta);
      float y2 = model.yRange * depth * sin(phaseV + (mult+1) * strand.theta);
      float yo = lerp(y1, y2, lerp);
      for (LXPoint p : strand.points) {
        colors[p.index] = LXColor.gray(max(0, 100 - falloff*abs(p.y - model.cy - yo)));
      }
    }
  }
}

@LXCategory("MIDI")
public class Blips extends EnvelopPattern {
  
  public final CompoundParameter speed = new CompoundParameter("Speed", 500, 4000, 250); 
  
  final Stack<Blip> available = new Stack<Blip>();
    
  public Blips(LX lx) {
    super(lx);
    addParameter("speed", this.speed);
  }
  
  class Blip extends LXModelLayer<VenueModel> {
    
    public final LinearEnvelope dist = new LinearEnvelope(0, model.yRange, new FunctionalParameter() {
      public double getValue() {
        return speed.getValue() * lerp(1, .6, velocity);
      }
    });

    private float yStart;
    private int ring;
    private boolean active = false;
    private float velocity = 0;

    public Blip(LX lx) {
      super(lx);
      addModulator(this.dist);
    }
    
    public void trigger(MidiNoteOn note) {
      this.velocity = note.getVelocity() / 127.;
      this.ring = note.getPitch() % venue.rings.size();
      this.yStart = venue.cy + random(-2*FEET, 2*FEET); 
      this.dist.trigger();
      this.active = true;
    }
    
    public void run(double deltaMs) {
      if (!this.active) {
        return;
      }
      boolean touched = false;
      float dist = this.dist.getValuef();
      float falloff = 100 / (1*FEET);
      float level = lerp(50, 100, this.velocity);
      for (LXPoint p : venue.rings.get(this.ring).strandPoints) {
        float b = level - falloff * abs(abs(p.y - this.yStart) - dist);
        if (b > 0) {
          touched = true;
          addColor(p.index, LXColor.gray(b));
        }
      }
      if (!touched) {
        this.active = false;
        available.push(this);
      }
    }
  }
  
  @Override
  public void noteOnReceived(MidiNoteOn note) {
    // TODO(mcslee): hack to not fight with flash
    if (note.getPitch() == 72) {
      return;
    }
    
    Blip blip;
    if (available.empty()) {
      addLayer(blip = new Blip(lx));
    } else {
      blip = available.pop();
    }
    blip.trigger(note);
  }
  
  public void run(double deltaMs) {
    setColors(#000000);
  }
}

@LXCategory("Envelop")
public class EnvelopShimmer extends EnvelopPattern {
  
  private final int BUFFER_SIZE = 512; 
  private final float[][] buffer = new float[model.rings.size()][BUFFER_SIZE];
  private int bufferPos = 0;
  
  public final CompoundParameter interp = new CompoundParameter("Mode", 0); 
  
  public final CompoundParameter speed = (CompoundParameter)
    new CompoundParameter("Speed", 1, 5, .1)
    .setDescription("Speed of the sound waves emanating from the speakers");
    
    public final CompoundParameter taper = (CompoundParameter)
    new CompoundParameter("Taper", 1, 0, 10)
    .setExponent(2)
    .setDescription("Amount of tapering applied to the signal");
  
  private final DampedParameter speedDamped = new DampedParameter(speed, 1);
  
  public EnvelopShimmer(LX lx) {
    super(lx);
    addParameter("intern", interp);
    addParameter("speed", speed);
    addParameter("taper", taper);
    startModulator(speedDamped);
    for (float[] buffer : this.buffer) {
      for (int i = 0; i < buffer.length; ++i) {
        buffer[i] = 0;
      }
    }
  }
  
  public void run(double deltaMs) {
    float speed = this.speedDamped.getValuef();
    float interp = this.interp.getValuef();
    float taper = this.taper.getValuef() * lerp(3, 1, interp); 
    for (Ring ring : model.rings) {
      float[] buffer = this.buffer[ring.index];
      buffer[this.bufferPos] = envelop.decode.channels[ring.index].getValuef();
      for (Strand strand : ring.strands) {
        for (int i = 0; i < strand.points.length; ++i) {
          LXPoint p = strand.points[i];
          int i3 = i % (strand.points.length/3);
          float td = abs(i3 - strand.points.length / 6);
          float threeWay = getValue(buffer, speed * td);
          float nd = abs(i - strand.points.length / 2);
          float normal = getValue(buffer, speed * nd);
          float bufferValue = lerp(threeWay, normal, interp);
          float d = lerp(td, nd, interp);
          colors[p.index] = LXColor.gray(max(0, 100 * bufferValue - d*taper));
        }
      }      
    }
    --bufferPos;
    if (bufferPos < 0) {
      bufferPos = BUFFER_SIZE - 1;
    }
  }
  
  private float getValue(float[] buffer, float bufferOffset) {
    int offsetFloor = (int) bufferOffset;
    int bufferTarget1 = (bufferPos + offsetFloor) % BUFFER_SIZE;
    int bufferTarget2 = (bufferPos + offsetFloor + 1) % BUFFER_SIZE;
    return lerp(buffer[bufferTarget1], buffer[bufferTarget2], bufferOffset - offsetFloor);
  }
}


@LXCategory("MIDI")
public class RingNotes extends EnvelopPattern {
  
  private final RingLayer[] rings = new RingLayer[model.rings.size()]; 
  
  public RingNotes(LX lx) {
    super(lx);
    for (Ring ring : model.rings) {
      int c = ring.index;
      addLayer(rings[c] = new RingLayer(lx, ring));
      addParameter("attack-" + c, rings[c].attack);
      addParameter("decay-" + c, rings[c].decay);
    }
  }
  
  @Override
  public void noteOnReceived(MidiNoteOn note) {
    int channel = note.getChannel();
    if (channel < this.rings.length) {
      this.rings[channel].envelope.engage.setValue(true);
    }
  }
  
  @Override
  public void noteOffReceived(MidiNote note) {
    int channel = note.getChannel();
    if (channel < this.rings.length) {
      this.rings[channel].envelope.engage.setValue(false);
    }
  }
  
  private class RingLayer extends LXLayer {
    
    private final CompoundParameter attack;
    private final CompoundParameter decay;
    private final ADEnvelope envelope;
    
    private final Ring ring;
    
    private final LXModulator vibrato = startModulator(new SinLFO(.8, 1, 400));
    
    public RingLayer(LX lx, Ring ring) {
      super(lx);
      this.ring = ring;
      
      this.attack = (CompoundParameter)
        new CompoundParameter("Atk-" + ring.index, 50, 25, 2000)
        .setExponent(4)
        .setUnits(LXParameter.Units.MILLISECONDS)
        .setDescription("Sets the attack time of the flash");
    
      this.decay = (CompoundParameter)
        new CompoundParameter("Dcy-" + ring.index, 1000, 50, 2000)
        .setExponent(4)
        .setUnits(LXParameter.Units.MILLISECONDS)
        .setDescription("Sets the decay time of the flash");
    
      this.envelope = new ADEnvelope("Env", 0, new FixedParameter(100), attack, decay);

      addModulator(this.envelope);
    }
    
    public void run(double deltaMs) {
      float level = this.vibrato.getValuef() * this.envelope.getValuef();
      for (LXPoint p : ring.points) {
        colors[p.index] = LXColor.gray(level);
      }
    }
  }
  
  public void run(double deltaMs) {
    setColors(#000000);
  }
}

@LXCategory(LXCategory.TEXTURE)
public class Jitters extends LXModelPattern<VenueModel> {
  
  public final CompoundParameter period = (CompoundParameter)
    new CompoundParameter("Period", 200, 2000, 50)
    .setExponent(.5)
    .setDescription("Speed of the motion");
    
  public final CompoundParameter size =
    new CompoundParameter("Size", 8, 3, 20)
    .setDescription("Size of the movers");
    
  public final CompoundParameter contrast =
    new CompoundParameter("Contrast", 100, 50, 300)
    .setDescription("Amount of contrast");    
  
  final LXModulator pos = startModulator(new SawLFO(0, 1, period));
  
  final LXModulator sizeDamped = startModulator(new DampedParameter(size, 30));
  
  public Jitters(LX lx) {
    super(lx);
    addParameter("period", this.period);
    addParameter("size", this.size);
    addParameter("contrast", this.contrast);
  }
  
  public void run(double deltaMs) {
    float size = this.sizeDamped.getValuef();
    float pos = this.pos.getValuef();
    float sizeInv = 1 / size;
    float contrast = this.contrast.getValuef();
    boolean inv = false;
    for (Strand strand : model.strands) {
      inv = !inv;
      float pv = inv ? pos : (1-pos);
      int i = 0;
      for (LXPoint p : strand.points) {
        float pd = (i % size) * sizeInv;
        colors[p.index] = LXColor.gray(max(0, 100 - contrast * LXUtils.wrapdistf(pd, pv, 1)));
        ++i;
      }
    }
  }
}

//------------------------Tenere Patterns
@LXCategory("Form")
public class PatternClouds extends EnvelopPattern {
  public String getAuthor() {
    return "Mark C. Slee";
  }
  
  public final CompoundParameter thickness =
    new CompoundParameter("Thickness", 50, 100, 0)
    .setDescription("Thickness of the cloud formation");
  
  public final CompoundParameter xSpeed = (CompoundParameter)
    new CompoundParameter("XSpd", 0, -1, 1)
    .setPolarity(LXParameter.Polarity.BIPOLAR)
    .setDescription("Motion along the X axis");

  public final CompoundParameter ySpeed = (CompoundParameter)
    new CompoundParameter("YSpd", 0, -1, 1)
    .setPolarity(LXParameter.Polarity.BIPOLAR)
    .setDescription("Motion along the Y axis");
    
  public final CompoundParameter zSpeed = (CompoundParameter)
    new CompoundParameter("ZSpd", 0, -1, 1)
    .setPolarity(LXParameter.Polarity.BIPOLAR)
    .setDescription("Motion along the Z axis");
    
  public final CompoundParameter scale = (CompoundParameter)
    new CompoundParameter("Scale", 3, .25, 10)
    .setDescription("Scale of the clouds")
    .setExponent(2);

  public final CompoundParameter xScale =
    new CompoundParameter("XScale", 0, 0, 10)
    .setDescription("Scale along the X axis");

  public final CompoundParameter yScale =
    new CompoundParameter("YScale", 0, 0, 10)
    .setDescription("Scale along the Y axis");
    
  public final CompoundParameter zScale =
    new CompoundParameter("ZScale", 0, 0, 10)
    .setDescription("Scale along the Z axis");
    
  private float xBasis = 0, yBasis = 0, zBasis = 0;
    
  public PatternClouds(LX lx) {
    super(lx);
    addParameter("thickness", this.thickness);
    addParameter("xSpeed", this.xSpeed);
    addParameter("ySpeed", this.ySpeed);
    addParameter("zSpeed", this.zSpeed);
    addParameter("scale", this.scale);
    addParameter("xScale", this.xScale);
    addParameter("yScale", this.yScale);
    addParameter("zScale", this.zScale);
  }

  private static final double MOTION = .0005;

  public void run(double deltaMs) {
    this.xBasis -= deltaMs * MOTION * this.xSpeed.getValuef();
    this.yBasis -= deltaMs * MOTION * this.ySpeed.getValuef();
    this.zBasis -= deltaMs * MOTION * this.zSpeed.getValuef();
    float thickness = this.thickness.getValuef();
    float scale = this.scale.getValuef();
    float xScale = this.xScale.getValuef();
    float yScale = this.yScale.getValuef();
    float zScale = this.zScale.getValuef();
    for (Ring ring : model.rings) {
      for (Strand strand : ring.strands) {
        for (LXPoint p : strand.points) {
        float nv = noise(
          (scale + p.xn * xScale) * p.xn + this.xBasis,
          (scale + p.yn * yScale) * p.yn + this.yBasis, 
          (scale + p.zn * zScale) * p.zn + this.zBasis
        );
        setColor(strand, LXColor.gray(constrain(-thickness + (150 + thickness) * nv, 0, 100)));
        }
      }
    }
  }  
}

@LXCategory("Form")
public class PatternWaves extends EnvelopPattern {
  public String getAuthor() {
    return "Mark C. Slee";
  }

  final int NUM_LAYERS = 3;
  
  final float AMP_DAMPING_V = 1.5;
  final float AMP_DAMPING_A = 2.5;
  
  final float LEN_DAMPING_V = 1.5;
  final float LEN_DAMPING_A = 1.5;

  public final CompoundParameter rate = (CompoundParameter)
    new CompoundParameter("Rate", 6000, 48000, 2000)
    .setDescription("Rate of the of the wave motion")
    .setExponent(.3);

  public final CompoundParameter size =
    new CompoundParameter("Size", 4*FEET, 6*INCHES, 28*FEET)
    .setDescription("Width of the wave");
    
  public final CompoundParameter amp1 =
    new CompoundParameter("Amp1", .5, 2, .2)
    .setDescription("First modulation size");
        
  public final CompoundParameter amp2 =
    new CompoundParameter("Amp2", 1.4, 2, .2)
    .setDescription("Second modulation size");
    
  public final CompoundParameter amp3 =
    new CompoundParameter("Amp3", .5, 2, .2)
    .setDescription("Third modulation size");
    
  public final CompoundParameter len1 =
    new CompoundParameter("Len1", 1, 2, .2)
    .setDescription("First wavelength size");
    
  public final CompoundParameter len2 =
    new CompoundParameter("Len2", .8, 2, .2)
    .setDescription("Second wavelength size");
    
  public final CompoundParameter len3 =
    new CompoundParameter("Len3", 1.5, 2, .2)
    .setDescription("Third wavelength size");
    
  private final LXModulator phase =
    startModulator(new SawLFO(0, TWO_PI, rate));
    
  private final LXModulator amp1Damp = startModulator(new DampedParameter(this.amp1, AMP_DAMPING_V, AMP_DAMPING_A));
  private final LXModulator amp2Damp = startModulator(new DampedParameter(this.amp2, AMP_DAMPING_V, AMP_DAMPING_A));
  private final LXModulator amp3Damp = startModulator(new DampedParameter(this.amp3, AMP_DAMPING_V, AMP_DAMPING_A));
  
  private final LXModulator len1Damp = startModulator(new DampedParameter(this.len1, LEN_DAMPING_V, LEN_DAMPING_A));
  private final LXModulator len2Damp = startModulator(new DampedParameter(this.len2, LEN_DAMPING_V, LEN_DAMPING_A));
  private final LXModulator len3Damp = startModulator(new DampedParameter(this.len3, LEN_DAMPING_V, LEN_DAMPING_A));  

  private final LXModulator sizeDamp = startModulator(new DampedParameter(this.size, 40*FEET, 80*FEET));

  private final double[] bins = new double[512];

  public PatternWaves(LX lx) {
    super(lx);
    addParameter("rate", this.rate);
    addParameter("size", this.size);
    addParameter("amp1", this.amp1);
    addParameter("amp2", this.amp2);
    addParameter("amp3", this.amp3);
    addParameter("len1", this.len1);
    addParameter("len2", this.len2);
    addParameter("len3", this.len3);
  }

  public void run(double deltaMs) {
    double phaseValue = phase.getValue();
    float amp1 = this.amp1Damp.getValuef();
    float amp2 = this.amp2Damp.getValuef();
    float amp3 = this.amp3Damp.getValuef();
    float len1 = this.len1Damp.getValuef();
    float len2 = this.len2Damp.getValuef();
    float len3 = this.len3Damp.getValuef();    
    float falloff = 100 / this.sizeDamp.getValuef();
    
    for (int i = 0; i < bins.length; ++i) {
      bins[i] = model.cy + model.yRange/2 * Math.sin(i * TWO_PI / bins.length + phaseValue);
    }
    for (Ring ring : model.rings) {
      for (Strand strand : ring.strands) {
        for (LXPoint p : strand.points) {
      int idx = Math.round((bins.length-1) * (len1 * p.xn)) % bins.length;
      int idx2 = Math.round((bins.length-1) * (len2 * (.2 + p.xn))) % bins.length;
      int idx3 = Math.round((bins.length-1) * (len3 * (1.7 - p.xn))) % bins.length; 
      
      float y1 = (float) bins[idx];
      float y2 = (float) bins[idx2];
      float y3 = (float) bins[idx3];
      
      float d1 = abs(strand.cy*amp1 - y1);
      float d2 = abs(strand.cy*amp2 - y2);
      float d3 = abs(strand.cy*amp3 - y3);
      
      float b = max(0, 100 - falloff * min(min(d1, d2), d3));      
      setColor(strand, b > 0 ? LXColor.gray(b) : #000000);
        }
      } 
    }
  }
}
@LXCategory("Color")
public class ColorTwoToneLeaves extends EnvelopPattern {
  public String getAuthor() {
    return "Mark C. Slee";
  }
  
  public final CompoundParameter tone =
    new CompoundParameter("Hue", 0, 0, 360)
    .setDescription("Second hue to be mixed in with the first");
    
  public final CompoundParameter amount =
    new CompoundParameter("Amount", 0)
    .setDescription("Amount to mix in the second color tone");
  
  private final float[] bias = new float[model.strands.size()]; 
  
  public ColorTwoToneLeaves(LX lx) {
    super(lx);
    addParameter("tone", this.tone);
    addParameter("amount", this.amount);
    for (int i = 0; i < this.bias.length; ++i) {
      this.bias[i] = random(0, 1);
    }
  }
  
  public void run(double deltaMs) {
    float sat = palette.getSaturationf();
    int c1 = LXColor.hsb(palette.getHuef(), sat, 100);
    int c2 = LXColor.hsb(this.tone.getValuef(), sat, 100);
    int li = 0;
    float amount = this.amount.getValuef();
    for (Ring ring : model.rings) {
      for (Strand strand : ring.strands) {
      float delta = amount - this.bias[li];
      if (delta <= 0) {
        setColor(strand, c1);
      } else if (delta < .1) {
        setColor(strand, LXColor.lerp(c1, c2, 10*delta));
      } else {
        setColor(strand, c2);
      }   
      ++li;
    
      }
    }
  }
}


public abstract class ColorSlideshow extends EnvelopPattern {
  public String getAuthor() {
    return "Mark C. Slee";
  }
    
  public final CompoundParameter rate =
    new CompoundParameter("Rate", 3000, 10000, 250);

  private final SawLFO lerp = (SawLFO) startModulator(new SawLFO(0, 1, rate));

  private int imageIndex;
  private final PImage[] images;
  
  public ColorSlideshow(LX lx) {
    super(lx);
    String[] paths = getPaths();
    this.images = new PImage[paths.length];
    for (int i = 0; i < this.images.length; ++i) {
      this.images[i] = loadImage(paths[i]);
      this.images[i].loadPixels();
    }
    addParameter("rate", this.rate);
    this.imageIndex = 0;
  }
  
  abstract String[] getPaths();
  
  public void run(double deltaMs) {
    float lerp = this.lerp.getValuef();
    if (this.lerp.loop()) {
      this.imageIndex = (this.imageIndex + 1) % this.images.length;
    }
    PImage image1 = this.images[this.imageIndex];
    PImage image2 = this.images[(this.imageIndex + 1) % this.images.length];
    
    int pixnum = 0;
    int strandnum = 0;
    int final_num = 0;
    
    for (Strand strand : model.strands) {
      for (LXPoint p : strand.points) {
      int c1 = image1.get( //<>//
        (int) (p.xn * (image1.width-1)),
        (int) ((1-p.zn) * (image1.height-1))
      );
      int c2 = image2.get(
        (int) (p.xn * (image2.width-1)),
        (int) ((1-p.zn) * (image2.height-1))
      );
      final_num = (strandnum *64) + pixnum;
      //println(final_num);
      colors[final_num]= LXColor.lerp(c1, c2, lerp); //(setColor(strand, LXColor.lerp(c1, c2, lerp));
      ++pixnum;
     }
     //++strandnum;
    }
  }
}
@LXCategory("Slideshows")
public class ColorSlideshowClouds extends ColorSlideshow {
  public ColorSlideshowClouds(LX lx) {
    super(lx);
  }
  
  public String[] getPaths() {
    return new String[] {
      "clouds1.jpeg",
      "clouds2.jpeg",
      "clouds3.jpeg"
      
    };
  }
}
@LXCategory("Slideshows")
public class ColorSlideshowSunsets extends ColorSlideshow {
  public ColorSlideshowSunsets(LX lx) {
    super(lx);
  }
  
  public String[] getPaths() {
    return new String[] {
      "sunset1.jpeg",
      "sunset2.jpeg",
      "sunset3.jpeg",
      "sunset4.jpeg",
      "sunset5.jpeg",
      "sunset6.jpeg"
    };
  }
}
@LXCategory("Slideshows")
public class ColorSlideshowOceans extends ColorSlideshow {
  public ColorSlideshowOceans(LX lx) {
    super(lx);
  }
  
  public String[] getPaths() {
    return new String[] {
      "ocean1.jpeg",
      "ocean2.jpeg",
      "ocean3.jpeg",
      "ocean4.jpeg"
    };
  }
}
@LXCategory("Slideshows")
public class ColorSlideshowCorals extends ColorSlideshow {
  public ColorSlideshowCorals(LX lx) {
    super(lx);
  }
  
  public String[] getPaths() {
    return new String[] {
      "coral1.jpeg",
      "coral2.jpeg",
      "coral3.jpeg",
      "coral4.jpeg",
      "coral5.jpeg"
    };
  }
}

@LXCategory("Slideshows")
public class TestSlides extends ColorSlideshow {
  public TestSlides(LX lx) {
    super(lx);
  }
  
  public String[] getPaths() {
    return new String[] {
      "black_blue_lines.jpg",
      "red_honeycomb.png",
      "RainbowGradient13.jpg",
      "polkadots1.png",
      "pinkDot.png",
      "panels3.png",
      "test.png"
    };
  }
}

//---Tom Patterns LOL
@LXCategory("Test") 
public class StrandSelect extends EnvelopPattern {
  public String getAuthor() {
    return "Tom Montagliano";
  }
    
  public final DiscreteParameter strand_num = 
    new DiscreteParameter("Strand",1,1,41);

  
  public StrandSelect(LX lx) {
    super(lx);
    addParameter("Strand", this.strand_num);
  }
  
  public void run(double deltaMs) {
    float cnt = 1;
    float snum = strand_num.getValuef(); 
    for (Strand strand : model.strands) {
      if (cnt == snum) {
      setColor(strand, #FFFFFF);
      } else {
      setColor(strand, #000000);
      }  
      ++cnt;
    }  
  
  }
}
//---Tom Patterns LOL
@LXCategory("Test") 
public class PixelTest extends EnvelopPattern {
  public String getAuthor() {
    return "Tom Montagliano";
  }
    
  public final DiscreteParameter strand_num = 
    new DiscreteParameter("Pixel #",1,1,2560);

  
  public PixelTest(LX lx) {
    super(lx);
    addParameter("Pixel #", this.strand_num);
  }
  
  public void run(double deltaMs) {
    int cnt = 0;
    int snum = strand_num.getValuei(); 
    for (int j = 0; j < 2560; j++) {
      if (cnt == snum) {
      colors[snum] = -1;//setColor(strand, #FFFFFF);
      } else {
      colors[cnt] = -16777216;//setColor(strand, #000000);
      }  
      ++cnt;
    }  
  
  }
}


@LXCategory("Test")
public class PixelSelect
  extends LXPattern
{
  public final DiscreteParameter strnd = new DiscreteParameter("Strand", 1, 1, 40);
  public final DiscreteParameter pixel = new DiscreteParameter("Pixel", 1, 1, 64);
  
  public PixelSelect(LX paramLX)
  {
    super(paramLX);
    addParameter("strand", strnd);
    addParameter("pixel", pixel);
  }
  
  public void run(double paramDouble)
  {
    int pixnum = (int)pixel.getValuei();
    int strandnum = (int)strnd.getValuei()-1;
    int final_num = (strandnum *64) + pixnum;
    
    for (int j = 0; j < colors.length; j++) {
      colors[j] = (j == final_num ? -1 : -16777216);
    }
  }
}
