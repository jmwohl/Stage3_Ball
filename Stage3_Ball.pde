import com.jonwohl.*;
import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;
import processing.serial.*;
import cc.arduino.*;

int displayW = 1024;
int displayH = 768;

int camW = 320;
int camH = 240;

PVector resizeRatio = new PVector(displayW / camW, displayH / camH);

Arduino arduino;
int buttonPin = 4;

Ball ball;
Capture cam;
PImage out;
Attention attention;
PImage src, dst;
OpenCV opencv;
ArrayList<Contour> contours;

boolean buttonDown = false;

void setup() {
  size(displayW, displayH);
  frameRate(30);
  String[] ards = Arduino.list();
  println(ards);
  
  // for Mac
  arduino = new Arduino(this, ards[ards.length - 1], 57600);
  // for Odroid
//  arduino = new Arduino(this, ards[ards.length - 1], 57600);
  arduino.pinMode(4, Arduino.INPUT);
  
  cam = new Capture(this, camW, camH);
  cam.start();
  
  // instantiate focus passing an initial input image
  attention = new Attention(this, cam);
  out = attention.focus(cam, cam.width, cam.height);
  
  // this opencv object is for contour (i.e. paddle) detection
  opencv = new OpenCV(this, out);
  
  // new Ball(x, y, vx, vy, radius)
  ball = new Ball(random(0,width), random(0, height), random(3, 6), random(3, 6), random(40, 80));
}

void draw() {
  background(0);
  
  if (cam.available()) { 
    // Reads the new frame
    cam.read();
  }
  
  // show attention view on buttonpress
  if (arduino.digitalRead(buttonPin) == Arduino.HIGH){
    buttonDown = true; 
  } else {
    buttonDown = false;
  }
  
  if (!buttonDown) {
    out = attention.focus(cam, cam.width, cam.height);
    out.filter(THRESHOLD, map(mouseY, 0, 786, 0, 1));
    image(out, 0, 0, width, height);
  } else {
    out = cam;
    image(out, 0, 0, width, height);
    drawAttention();
  }
  
  // warp the selected region on the input image (cam) to an output image of width x height
  out = attention.focus(cam, width, height);
  
  opencv.loadImage(out);
  
  opencv.gray();
  float thresh = map(mouseY, 0, height, 0, 255); 
  opencv.threshold(int(thresh));
//  opencv.invert();
  
  // draw the warped and thresholded image
  dst = opencv.getOutput();
  image(dst, 0, 0);
  
  // use the first contour, assume it's the only/biggest one.
  contours = opencv.findContours();
  if (contours.size() > 0) {
    Contour contour = contours.get(0);
    
    // find and draw the centroid, justforthehellavit.
    ArrayList<PVector> points = contour.getPolygonApproximation().getPoints();
    PVector centroid = calculateCentroid(points);
    fill(255, 0, 0);
    ellipse(centroid.x, centroid.y, 10, 10);
    
    // see if the ball is within the bounding box of the contour, if so it's a hit
    Rectangle bb = contour.getBoundingBox();
    if (bb.contains(ball.pos.x, ball.pos.y + ball.rad/2)) {
      println("hit!");
      ball.vel.y = -ball.vel.y;
    }
    
    contour.draw();
  }
  
  ball.move();
  ball.draw();
  
}



PVector calculateCentroid(ArrayList<PVector> points) {
  ArrayList<Float> x = new ArrayList<Float>();
  ArrayList<Float> y = new ArrayList<Float>();
  for(PVector point : points) {
    x.add(point.x);
    y.add(point.y); 
  }
  float xTemp = findAverage(x);
  float yTemp = findAverage(y);
  PVector cen = new PVector(xTemp,yTemp);
  return cen;
   
}

float findAverage(ArrayList<Float> vals) {
  float numElements = vals.size();
  float sum = 0;
  for (int i=0; i< numElements; i++) {
    sum += vals.get(i);
  }
  return sum/numElements;
}
