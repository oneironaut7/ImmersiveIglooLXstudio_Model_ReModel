import java.net.InetAddress;
import java.util.Map;

class EnvelopOscListener implements LXOscListener {
  
  private int getIndex(OscMessage message) {
    String[] parts = message.getAddressPattern().toString().split("/");
    try {
      return Integer.valueOf(parts[parts.length - 1]);
    } catch (Exception x) {
      return -1;
    }
  }
  
  public void oscMessage(OscMessage message) {
    if (message.matches("/envelop/tempo/beat")) {
      lx.tempo.trigger(message.getInt()-1);
    } else if (message.matches("/envelop/tempo/bpm")) {
      lx.tempo.setBpm(message.getDouble());
    } else if (message.matches("/envelop/meter/decode")) {
      envelop.decode.setLevels(message);
    } else if (message.hasPrefix("/envelop/meter/source")) {
      int index = getIndex(message) - 1;
      if (index >= 0 && index < envelop.source.channels.length) {
        envelop.source.setLevel(index, message);
      }
    } else if (message.hasPrefix("/envelop/source")) {
      int index = getIndex(message) - 1;
      if (index >= 0 && index < envelop.source.channels.length) {
        Envelop.Source.Channel channel = envelop.source.channels[index];
        float rx = 0, ry = 0, rz = 0;
        String type = message.getString();
        if (type.equals("xyz")) {
          rx = message.getFloat();
          ry = message.getFloat();
          rz = message.getFloat();
        } else if (type.equals("aed")) {
          float azimuth = message.getFloat() / 180. * PI;
          float elevation = message.getFloat() / 180. * PI;
          float radius = message.getFloat();
          rx = radius * cos(-azimuth + HALF_PI) * cos(elevation);
          ry = radius * sin(-azimuth + HALF_PI) * cos(elevation);
          rz = radius * sin(elevation);
        }
        channel.xyz.set(rx, ry, rz);
        channel.active = true;
        channel.tx = venue.cx + rx * venue.xRange/2;
        channel.ty = venue.cy + rz * venue.yRange/2;
        channel.tz = venue.cz + ry * venue.zRange/2;
      }
    }
  }
}

class EnvelopOscMeterListener implements LXOscListener {
  public void oscMessage(OscMessage message) {
    if (message.matches("/server/dsp/meter/input")) {
      envelop.source.setLevels(message);
    } else if (message.matches("/server/dsp/meter/decoded")) {
      envelop.decode.setLevels(message);
    } else {
      println(message);
    }
  }
}

class EnvelopOscSourceListener implements LXOscListener {
    
  public void oscMessage(OscMessage message) {
    String[] parts = message.getAddressPattern().toString().split("/");
    if (parts.length == 4) {
      if (parts[1].equals("source")) {
        try {
          int index = Integer.parseInt(parts[2]) - 1;
          if (index >= 0 && index < envelop.source.channels.length) {
            Envelop.Source.Channel channel = envelop.source.channels[index];
            if (parts[3].equals("active")) {
              channel.active = message.getFloat() > 0;
            } else if (parts[3].equals("xyz")) {
              float rx = message.getFloat();
              float ry = message.getFloat();
              float rz = message.getFloat();
              channel.xyz.set(rx, ry, rz);
              channel.tx = venue.cx + rx * venue.xRange/2;
              channel.ty = venue.cy + rz * venue.yRange/2;
              channel.tz = venue.cz + ry * venue.zRange/2;
            }
          } else {
            println("Invalid source channel message: " + message);
          }
        } catch (NumberFormatException nfx) {}
      }
    }
  }
}
