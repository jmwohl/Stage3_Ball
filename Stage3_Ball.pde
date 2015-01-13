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
int potPin = 0;

Ball ball;
Capture cam;
PImage out;
Attention attention;
PImage src, dst;
OpenCV opencv;
ArrayList<Contour> contours;
boolean debugView;
int paddleMaxArea = 20000;
int paddleMinArea = 1000;
int ballRadius = 100;

boolean buttonDown = true;

void setup() {
  size(displayW, displayH);
  frameRate(30);
  String[] ards = Arduino.list();
  // println(ards);
  
  // for Mac
  //arduino = new Arduino(this, ards[ards.length - 1], 57600);
  // for Odroid
  arduino = new Arduino(this, "/dev/ttyACM0", 57600);
  arduino.pinMode(4, Arduino.INPUT);
  
  cam = new Capture(this, camW, camH, "/dev/video0", 30);
  //cam = new Capture(this, camW, camH, 30);
  //cam = new Capture(this, camW, camH, "Sirius USB2.0 Camera", 30);

  cam.start();
  
  // instantiate focus passing an initial input image
  attention = new Attention(this, cam);
  out = attention.focus(cam, cam.width, cam.height);
  
  // this opencv object is for contour (i.e. paddle) detection
  opencv = new OpenCV(this, out);
  
  // new Ball(x, y, vx, vy, radius)
  ball = new Ball(random(0,width), random(0, height), 11, 11, ballRadius);
}

void draw() {
  background(0);
  
  if (cam.available()) { 
    // Reads the new frame
    cam.read();
  }
  
  // show attention view on buttonpress
  if (arduino.digitalRead(buttonPin) == Arduino.HIGH){
    //buttonDown = true; 
  } else {
    //buttonDown = false;
  }
  
  // warp the selected region on the input image (cam) to an output image of width x height
  out = attention.focus(cam, cam.width, cam.height);
  
  // threshold using only the red pixels
  float thresh = map(arduino.analogRead(potPin), 0, 1024, 0, 255); 
  redThreshold(out, thresh);
  
  opencv.loadImage(out);
  
  // draw the warped and thresholded image
  dst = opencv.getOutput();
  
  // use the first contour, assume it's the only/biggest one.
  contours = opencv.findContours();
  if (contours.size() > 0) {
    Contour contour = contours.get(0);
    
    // find and draw the centroid, justforthehellavit.
    ArrayList<PVector> points = contour.getPolygonApproximation().getPoints();
    PVector centroid = calculateCentroid(points);
    fill(255);
    //ellipse(centroid.x, centroid.y, 10, 10);
    
    // see if the ball is within the bounding box of the contour, if so it's a hit
    noFill();
    Rectangle bb = contour.getBoundingBox();
    bb.setBounds((int) (displayW - bb.x * resizeRatio.x - bb.width), (int)(bb.y * resizeRatio.y), (int)(bb.width * resizeRatio.x), (int)(bb.height * resizeRatio.y));
    if (buttonDown) {
      stroke(0, 255, 0);
      //rect(bb.x, bb.y, bb.width, bb.height);
      rect((width - bb.x - bb.width), bb.y, bb.width, bb.height);
    }
    noStroke();
    // resize bb
    // println("rectArea: " + getArea(bb));
    if (bb.contains(ball.pos.x, ball.pos.y + ball.rad/2) && ball.vel.y > 0 && getArea(bb) < paddleMaxArea && getArea(bb) > paddleMinArea) {
      // println("hit!");
      ball.vel.y = -ball.vel.y;
    }
    
//    contour.draw();
  }
  
  ball.move();
  ball.draw();
  if (debugView){
    image(dst, 0, 0);
  }
}

void keyPressed() {
  if (key == 'D' || key == 'd') {
    debugView = !debugView;  
  }
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

void redThreshold(PImage img, float thresh){
  img.loadPixels();
  int numPix = 0;
  for (int i=0; i < img.pixels.length; i++){
    if (red(img.pixels[i]) > thresh){
      img.pixels[i] = color(255, 255, 255);
      numPix++;
    } else {
      img.pixels[i] = color(0, 0, 0);
    }
  } 
  img.updatePixels();
  // print("numPix: " + numPix);
}

int getArea(Rectangle r){
  int area = r.width*r.height;
  return area;
}
