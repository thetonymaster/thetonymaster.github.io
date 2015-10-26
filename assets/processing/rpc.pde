Server s;
Client c;
Pipe p;
boolean clicked;
static final int labelPadding = 40;
ArrayList<Message> messages;

void setup() {
  size(400,300);
  frameRate(30);
  messages = new ArrayList<Message>();

  clicked = false;

  c = new Client(100, 150,"Client");
  s = new Server(300, 150,"Server");
  p = new Pipe(125, 150, 275, 150)

}

void draw(){
  background(255);
  p.draw();

  for (int i = 0; i < messages.size(); i++) {
    Message mes = messages.get(i);

    mes.draw();
    if (mes.finished()) {
      messages.remove(i);
    }
  }


  c.draw();
  s.draw();

}

void mousePressed(){
  if (c.isBelowMouse()){
      clicked = true;
      c.toggleColor();
  }
}

void mouseReleased(){
  if(clicked){
    clicked = false;
    c.toggleColor();
    messages.add(new Message(102.5,150));
  }
}



class Server extends Node{
  float height;
  float width;
  color c = color(146,169,186);

  Server(float tempxpos, float tempypos, String label){
    super(label, c, tempxpos, tempypos);
    width = 50;
    height = 50;
  }

  void draw(){
     fill(c);
     rectMode(CENTER);
     rect(super.getX(), super.getY(), width, height);
     super.drawLabel();
  }
}


class Client extends Node{
  float height;
  float width;
  color c = color(127,255,212);
  color clicked = color(102,205,170);
  boolean toggle;
  Client(float tempxpos, float tempypos, String label){
    super(label, c, tempxpos, tempypos);
    width = 50;
    height = 50;
    toggle = false;
 }


  boolean isBelowMouse() {
    float closest = 20;
    float d = dist(mouseX, mouseY, this.x, this.y);
    return d < closest;
  }

  void toggleColor(){
    toggle = !toggle;
  }


 void draw(){
    rectMode(CENTER);
    if(toggle){
     fill(clicked);
    }else{
     fill(super.nodeColor);
    }
    ellipse(super.getX(), super.getY(), width, height);
    super.drawLabel();
 }

}

abstract class Node{
  float x, y;
  int raii = 10;
  String label;
  color nodeColor;

  Node(string label, color nodeColor, float x, float y) {
    this.label = label;
    this.nodeColor = nodeColor;
    this.x = x;
    this.y = y;
  }

  float getX(){
    return x;
  }

  float getY() {
    return y;
  }

  void drawLabel() {
    stroke(0);
    fill (0);
    textAlign(CENTER, CENTER);
    text(getLabel(), x, y+labelPadding);
  }

  String getLabel() {
    return label;
  }

}


class Message {
  float xpos;
  float ypos;
  float speed;
  float radius;
  color c;
  int delay;
  boolean done;
  boolean direction;
  int delay;

  Message(float xpos1, float ypos1){
    xpos = xpos1;
    ypos = ypos1;

    c = color(random(255),random(255),random(255));
    delay = 0;
    speed = 0.9;
    radius = 5;
    done = false;
    direction = true;
  }

  void setSpeed(float tempspeed) {
    speed = tempspeed;
  }


  void move() {
  float pipeDist = dist(p.getXpos(), p.getYpos(),
                  p.getXposFinal(), p.getYposFinal());
  float msgDist = 0;

    if (direction) {
      msgDist = dist(p.getXpos(), p.getYpos(), xpos, ypos);

      if (msgDist > (pipeDist + 15)) {
        delay = int(random(90));
        direction = false;
      } else {
        xpos = xpos + speed;
      }
    } else {
      msgDist = dist(p.getXposFinal(), p.getYposFinal(), xpos, ypos);

      if (msgDist > (pipeDist + 15)) {
        done = true;
      } else {
        xpos = xpos - speed;
      }
    }


  }

  boolean finished() {
    return done;
  }

  void draw() {
    if (delay > 0) {
      delay--;
    } else {
      move();
    }
    fill(c);
    ellipseMode(CENTER);
    ellipse(xpos, ypos, 15, 15);
  }
}


class Pipe {
    float xpos;
    float ypos;
    float x2pos;
    float y2pos;

    Pipe(float xpos1, float ypos1, float xpos2, float ypos2){

      xpos = xpos1;
      ypos = ypos1;

      x2pos = xpos2;
      y2pos = ypos2;

    }

    void draw(){
        line(xpos, ypos, x2pos, y2pos);
    }

    float getXpos() {
      return xpos;
    }

    float getXposFinal() {
      return x2pos;
    }

    float getYpos() {
      return ypos;
    }

    float getYposFinal() {
      return y2pos;
    }
}
