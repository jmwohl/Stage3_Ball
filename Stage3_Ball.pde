import com.jonwohl.*;
import processing.video.*;

import gab.opencv.*;

import java.awt.Rectangle;

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

void setup() {
//  size(displayWidth, displayHeight);
  size(1024, 768);
  
  //cam = new Capture(this, 640, 480, "Sirius USB2.0 Camera", 30);
  cam = new Capture(this, 640, 480);
  cam.start();
  
  // instantiate focus passing an initial input image
  attention = new Attention(this, cam);
  out = attention.focus(cam, width, height);
  
  // this opencv object is for contour (i.e. paddle) detection
  opencv = new OpenCV(this, out);
  
  // new Ball(x, y, vx, vy, radius)
  ball = new Ball(random(0,width), random(0, height), 11, 11, ballRadius);
}

void draw() {
  background(0, 0, 0);
  
  if (cam.available()) { 
    // Reads the new frame
    cam.read();
  }
  
  // warp the selected region on the input image (cam) to an output image of width x height
  out = attention.focus(cam, width, height);
  
  
  
  //opencv.gray();
  float thresh = map(mouseY, 0, height, 0, 255); 
  redThreshold(out, thresh);
  
  opencv.loadImage(out);
  //opencv.threshold(int(thresh));
//  opencv.invert();
  
  // draw the warped and thresholded image
  dst = opencv.getOutput();
  //image(dst, 0, 0);
  
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
    stroke(0, 255, 0);
    rect(bb.x, bb.y, bb.width, bb.height);
    // resize bb
    println("rectArea: " + getArea(bb));
    if (bb.contains(ball.pos.x, ball.pos.y + ball.rad/2) && ball.vel.y > 0 && getArea(bb) < paddleMaxArea && getArea(bb) > paddleMinArea) {
      println("hit!");
      ball.vel.y = -ball.vel.y;
    }
    
//    contour.draw();
  }
  
  ball.move();
  ball.draw();
  if (debugView){
    image(dst, 0, 0, width/4, height/4);
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
  print("numPix: " + numPix);
}

int getArea(Rectangle r){
  int area = r.width*r.height;
  return area;
}
