class Ball {
  PVector pos;
  PVector vel;
  float rad;
  
  Ball(float x, float y, float vx, float vy, float radius) {
    pos = new PVector(x, y);
    vel = new PVector(vx, vy);
    rad = radius;
  }
  
  void move() {
    if (pos.x >= width - rad/2) {
      pos.x = width - rad/2;
      vel.x = -vel.x;
    } else if (pos.x <= rad/2) {
      pos.x = rad/2;
      vel.x = -vel.x;
    }
    if (pos.y >= height - rad/2) {
      // ball hit bottom of window, game over
      println("Game Over!");
      pos.x = random(0, width);
      pos.y = random(0, height/2);
      vel.x = random(3, 6);
      vel.y = random(3, 6);
    } else if (pos.y <= rad/2) {
      pos.y = rad/2;
      vel.y = -vel.y;
    }
      
    pos.x += vel.x;
    pos.y += vel.y;
  }
  
  void draw() {
    fill(255);
    ellipse(pos.x, pos.y, rad, rad);
  }
  
}
