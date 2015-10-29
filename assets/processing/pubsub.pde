Consumer[] s;
Producer c;
Exchange e;
Pipe[] p;
color[] topicColor;
boolean clicked;
static final int labelPadding = 40;
ArrayList<Message> messages;

void setup() {
  size(450,400);
  frameRate(30);
  messages = new ArrayList<Message>();

  topicColor = new color[3];

  topicColor[0] = color(51,51,255);
  topicColor[1] = color(0,153,0);
  topicColor[2] = color(255,51,51);

  clicked = false;
  s = new Consumer[3];
  p = new Pipe[4];
  c = new Producer(100, 200,"Producer");
  e = new Exchange(225, 200,"Exchange");
  s[1] = new Consumer(350, 100,"Consumer A", topicColor[0]);
  s[0] = new Consumer(350, 200,"Consumer B", topicColor[1]);
  s[2] = new Consumer(350, 300,"Consumer C", topicColor[2]);
  p[0] = new Pipe(125, 200, 200, 200);
  p[1] = new Pipe(250, 200, 335, 100);
  p[2] = new Pipe(250, 200, 335, 200);
  p[3] = new Pipe(250, 200, 335, 300);


}

void draw(){
  background(255);

  for (int i = 0; i < p.length; i++){
    p[i].draw();
  }

  for (int i = 0; i < messages.size(); i++) {
    Message mes = messages.get(i);

    mes.draw();
    if (mes.finished()) {
      messages.remove(i);
    }
  }

  for (int i = 0; i < s.length; i++){
    s[i].draw();
  }

  c.draw();
  e.draw();
  fill(topicColor[0]);
  ellipse(60, 10, 13, 13);
  text("Topic A", 100, 10);


  fill(topicColor[1]);
  ellipse(60, 30, 13, 13);
  text("Topic B", 100, 30);


  fill(topicColor[2]);
  ellipse(60, 50, 13, 13);
  text("Topic C", 100, 50);

  fill(0);
  text("Click on the producer to send a message", 160, 70);
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
    messages.add(new Message(125,200));
  }
}



class Consumer extends Node{
  float height;
  float width;

  Consumer(float tempxpos, float tempypos, String label, color consColor){
    super(label, consColor, tempxpos, tempypos);
    width = 30;
    height = 30;
  }

  void draw(){
     fill(this.nodeColor);
     rectMode(CENTER);
     rect(super.getX(), super.getY(), width, height);
     super.drawLabel();
  }
}

class Exchange extends Node{
  float height;
  float width;
  color c = color(146,169,186);

  Exchange(float tempxpos, float tempypos, String label){
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


class Producer extends Node{
  float height;
  float width;
  color c = color(127,255,212);
  color clicked = color(102,205,170);
  boolean toggle;

  Producer(float tempxpos, float tempypos, String label){
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
  boolean done;
  boolean direction;
  int pipe;
  int pps;
  int dest;


  Message(float xpos1, float ypos1){
    xpos = xpos1;
    ypos = ypos1;



    c = color(random(255),random(255),random(255));
    pipe = 0;
    speed = 0.9;
    radius = 3;
    done = false;
    dest = int(random(3)) + 1;
    pps = 0;
  }

  void setSpeed(float tempspeed) {
    speed = tempspeed;
  }


  void move() {
    pp = p[pipe];
    float pipeDist = dist(pp.getXpos(), pp.getYpos(),
                    pp.getXposFinal(), pp.getYposFinal());
    float msgDist = dist(pp.getXpos(), pp.getYpos(), xpos, ypos);
    float a = atan2(pp.getXposFinal()-pp.getXpos(),  pp.getYposFinal()-pp.getYpos());

    float xspeed = sin(a);
    float yspeed = cos(a);

    if (msgDist > (pipeDist + 8)) {
      pps++;
      if (pps > 1) {
        done = true;
        return;
      }
      pipe = dest;
      xpos = p[pipe].getXpos();

    } else {
      xpos = xpos + speed*xspeed;
      ypos = ypos + speed*yspeed;
    }


  }

  boolean finished() {
    return done;
  }

  void draw() {
    move();
    fill(topicColor[dest-1]);
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
