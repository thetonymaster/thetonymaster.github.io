Filter[] filters;
Pipe[] pipes;
ArrayList<Message> messages;
int messagenumber;
static final int labelPadding = 20;

color[] transColors;
color[] strokeTr;
float[] radiiTr;
boolean clicked;

Pipe p1;
Pipe p2;
int currFilter;
Producer p;

Message m1;

void setup(){
  size(400,150);

  setupTransforms();

  messages = new ArrayList<Message>();
  filters = new Filter[3];
  p = new Producer(50, 50, "Producer");
  s = new Sink(330, 50, "Sink");

  filters[0] = new Filter(50, 120, 10,"Filter A");
  filters[1] = new Filter(50, 190, 60, "Filter B");
  filters[2] = new Filter(50, 260, 5, "Filter C" );

  currFilter = 0;
  messagenumber = 0;

  pipes = new Pipe[4];
  pipes[0] = new Pipe(60, 50, 105, 50);
  pipes[1] = new Pipe(135, 50, 175, 50);
  pipes[2] = new Pipe(205, 50, 245, 50);
  pipes[3] = new Pipe(275, 50, 320, 50);

  clicked = false;

}

void draw() {
  background(255);

  for(int c = 0; c < pipes.length; c++) {
    pipes[c].draw();
  }

  for (int i = 0; i < messages.size(); i++) {
    Message mes = messages.get(i);

    mes.draw();
    if (mes.finished()) {
      messages.remove(i);
    }
  }

  for (int c = 0; c < filters.length; c++) {
    filters[c].draw();
  }
  p.draw();
  s.draw();



  stroke(0);
  fill (0);
  textAlign(CENTER, CENTER);
  text("Click on the producer to send a message", 180, 100);

}

void mousePressed(){
  if (p.isBelowMouse()){
      clicked = true;
      p.toggleColor();
  }
}

void mouseReleased(){
  if(clicked){
    clicked = false;
    p.toggleColor();
    messages.add(new Message(62.5,50));
  }
}

void setupTransforms(){
 transColors = new color[4];
 strokeTr = new color[4];
 radiiTr = new float[4];

 transColors[0] = color(139,139,131);
 transColors[1] = color(205,205,193);
 transColors[2] = color(238,238,224);
 transColors[3] = color(255,255,240);

 strokeTr[0] = color(255,250,250);
 strokeTr[1] = color(238,233,233);
 strokeTr[2] = color(205,201,201);
 strokeTr[3] = color(139,137,137);


 radiiTr[0] = 5;
 radiiTr[1] = 7;
 radiiTr[2] = 9;
 radiiTr[3] = 11;

}

class Message {
  float xpos;
  float ypos;
  float speed;
  float radius;
  color c;
  int delay;
  int currPipe;
  boolean done;

  Message(float xpos1, float ypos1){
    xpos = xpos1;
    ypos = ypos1;

    c = color(255);

    speed = 0.3;
    radius = 5;
    delay = 0;
    currPipe = 0;
    done = false;
  }

  void setSpeed(float tempspeed) {
    speed = tempspeed;
  }

  void setDelay(int tempdelay){
    delay = tempdelay;
  }

  void move() {
    pipe = pipes[currPipe];
    float distA = dist(pipe.getXpos(), pipe.getYpos(),
                    pipe.getXposFinal(), pipe.getYposFinal());
    float distB = dist(pipe.getXpos(), pipes[currPipe].getYpos() ,xpos, ypos);

    if (distB > distA) {
      currPipe = currPipe + 1;
      if (currPipe > (pipes.length - 1)){
        done = true;
        return;
      }

      pipe = pipes[currPipe];

      xpos = pipe.getXpos();
      ypos = pipe.getYpos();

    } else {
      xpos = xpos + speed;
    }

  }

  boolean finished() {
    return done;
  }

  void draw() {
    move();
    stroke(strokeTr[currPipe]);
    fill(transColors[currPipe]);
    ellipseMode(CENTER);
    ellipse(xpos, ypos, radiiTr[currPipe], radiiTr[currPipe]);
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

class Filter extends Node {
  float radius;
  color c = color(146,169,186);
  int delay;

  Filter(float tempYpos, float tempXpos, int delaytemp, String label){
    c = color(146,169,186);
    super(label, c, tempXpos, tempYpos);
    radius = 30;
    delay = delaytemp;
  }

  void draw(){
  stroke(0);
    ellipseMode(CENTER);
    fill(c);
    rect(x, y, radius, radius - 10);
    super.drawLabel();
  }

  int getDelay(){
    return delay;
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
    width = 20;
    height = 20;
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

class Sink extends Node{
  float height;
  float width;
  color c = color(146,169,186);

  Sink(float tempxpos, float tempypos, String label){
    super(label, c, tempxpos, tempypos);
    width = 20;
    height = 20;
  }

  void draw(){
     rectMode(CENTER);
     rect(super.getX(), super.getY(), width, height);
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
