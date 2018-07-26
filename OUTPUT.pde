import java.net.SocketException;

LXOutput getOutput(LX lx) throws IOException {
  switch (environment) {
  //case MIDWAY: 
    //return new MidwayOutput(lx);
  case SATELLITE: 
    return new SatelliteOutput(lx);
  }
  return null;
}


class SatelliteOutput extends LXDatagramOutput {
  SatelliteOutput(LX lx) throws IOException {
    super(lx);
    int universe = 0;
    int columnIp = 1;
    for (Ring ring : venue.rings) {
      for (Strand strand : ring.strands) {
        // Top to bottom
        int[] indices = new int[strand.size];
        for (int i = 0; i < indices.length; i++) {
          indices[indices.length-1-i] = strand.points[i].index;
        }
        addDatagram(new ArtNetDatagram(indices, 512, universe++).setAddress("192.168.0." + columnIp));
      }
      ++columnIp;
    }
  }
}
