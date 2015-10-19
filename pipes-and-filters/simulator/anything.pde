Filter[] filters;
Pipe[] pipes;

Pipe p1;
Pipe p2;
int currFilter;

Message m1;

void setup(){
  size(300,300);
  filters = new Filter[3];
  filters[0] = new Filter(150, 50, 10);
  filters[1] = new Filter(150, 120, 60);
  filters[2] = new Filter(150, 190, 5);

  currFilter = 0;

  pipes = new Pipe[2];
  pipes[0] = new Pipe(65, 150, 105, 150);
  pipes[1] = new Pipe(135, 150, 175, 150);

  m1 = new Message(67.5,150);
  frameRate(30);

}

void draw() {
  background(255);

  for (int c = 0; c < filters.length; c++) {
    filters[c].display();
  }

  if (currFilter < filters.length - 2) {
    if (m1.getXpos() >= filters[currFilter].getXpos() + 70) {
        currFilter = currFilter + 1;
        m1.setDelay(filters[currFilter].getDelay());
        m1.setXpos(filters[currFilter].getNextXpos());
    }
  }
  if (currFilter == filters.length - 2 && m1.getXpos() >= filters[currFilter].getXpos() + 70) {
    currFilter = 0;
    m1.setDelay(0);
    m1.setXpos(filters[currFilter].getNextXpos());
  }


  for(int c = 0; c < pipes.length; c++) {
    pipes[c].display();
  }

  m1.move();

}

class Message {
  float xpos;
  float ypos;
  float speed;
  float radius;
  color c;
  int delay;

  Message(float xpos1, float ypos1){
    xpos = xpos1;
    ypos = ypos1;

    c = color(255);

    speed = 0.5;
    radius = 5;
    delay = 0;
  }

  void setSpeed(float tempspeed) {
    speed = tempspeed;
  }

  void setDelay(int tempdelay){
    delay = tempdelay;
  }

  void move() {
    if (delay > 0) {
      delay = delay - 1;
    } else {

      xpos = xpos + speed;
      ellipseMode(CENTER);
      fill(c);
      ellipse(xpos, ypos, radius, radius);
    }


  }


  float getXpos(){
    return (xpos + 2.5);
  }

  float getYpos(){
    return (ypos + 2.5);
  }

  void setXpos(float x) {
    xpos = x + 2.5;
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

    void display(){
        line(xpos, ypos, x2pos, y2pos);
    }
}

class Filter {
  float xpos;
  float ypos;
  float radius;
  color c;
  int delay;

  Filter(float tempYpos, float tempXpos, int delaytemp){
    c = color(146,169,186);
    ypos = tempYpos;
    xpos = tempXpos;
    radius = 30;
    delay = delaytemp;
  }

  void display(){
    ellipseMode(CENTER);
    fill(c);
    ellipse(xpos,ypos, radius, radius);
  }

  int getDelay(){
    return delay;
  }

  float getXpos(){
    return (xpos - 15);
  }

  float getYpos(){
    return (ypos - 15);
  }

  float getNextXpos(){
    return (xpos + 15);
  }

}
