import java.util.concurrent.*;
import java.util.*;
final javax.swing.JFileChooser fc = new javax.swing.JFileChooser();
int negvar = 15;
int posvar = 15;

int w;
int h;

int doneCount=0;

static double RBIAS = -.5; //0 is no bias.  
// higher numbers for lighter, lower numbers for darker
static double GBIAS = .5; //0 is no bias.  
// higher numbers for lighter, lower numbers for darker
static double BBIAS = 0; //0 is no bias.  
// higher numbers for lighter, lower numbers for darker
static double BWBIAS = (RBIAS+GBIAS+BBIAS)/3;//0 is no bias.  
// higher numbers for lighter, lower numbers for darker

static int CENTERBIAS = 1; //1 is no bias, higher means more towards center
// bigger numbers also take longer to make an image, but mean more toned down

static int GREYFACTOR = 0;//0 is no bias.  
// bigger numbers for greyer, up to 127 for all grey

static float RANDOMFACTOR = 1.05;// smaller numbers are completely random (almost)
// bigger numbers more uniform layout
// 1.1 is beautiful
//0 is 100% chance

static int genNum = 30;

static int THREADNUM = 15;

static final String PARAM_CHANGE_MESSAGE = 
     "Please input the initial selection value in the form" + "\n"
     + "(red bias, green bias, blue bias, center bias, grey factor,random layout factor)";
int pixnum=0;
boolean current[][];
List<Pair> opperations;
ExecutorService exec = Executors.newFixedThreadPool(THREADNUM);
Pair centerPair;
void setup() {
  w = 1024;
  h = 768;
  opperations = Collections.synchronizedList(new LinkedList<Pair>());
  size(w, h);
  background(random(256), random(256), random(256));
  current = new boolean[width][height];
  centerPair = new Pair(width/2, height/2);
  opperations.add(centerPair);
  falsifyCurrent();
  fillAll();
}

void genMany(int howMany){
  for(int i=0;i<genNum;i++){
    newImage();
    saveRandomName();
  }
  exit();
}

void saveRandomName(){
  String filename = "";
  for(int i=0;i<16;i++){
    int thischar = (int)random(36);
    if(thischar>=26) filename+=(char)(thischar+'0');
    else if(((int)random(2))>0) filename+=(char)(thischar+'a');
    else filename+=(char)(thischar+'A');
  }
  save("starbursts/"+filename+".png");
}

void newImage(){
  opperations.add(centerPair);
  falsifyCurrent();
  fillAll();
}

void setParams(){
  String input = javax.swing.JOptionPane.showInputDialog(this, PARAM_CHANGE_MESSAGE);
  if(input==null) return;
  if(input.charAt(0)=='(') input = input.substring(1,input.length()-1);
  String[] params = input.split(",");
  try{
    RBIAS = Double.parseDouble(params[0]);
    GBIAS = Double.parseDouble(params[1]);
    BBIAS = Double.parseDouble(params[2]);
    CENTERBIAS = Integer.parseInt(params[4])+1;
    GREYFACTOR = Integer.parseInt(params[5]);
    RANDOMFACTOR = Float.parseFloat(params[6]);
  }catch(Exception e){
    println(e+" in setParams()");
  }
}

void draw(){}

void keyPressed(){
  if(key=='s'||key=='S'||key=='p'||key=='P') setParams();
  if(key=='m'||key=='M'){
    String input = javax.swing.JOptionPane.showInputDialog(this, "How many images do you want to generate?");
    genMany(Integer.parseInt(input));
  }
  newImage();
}

void mousePressed(){
  //String savePath = selectOutput("select an output file");  // Opens file chooser
  fc.showSaveDialog(this);
  if(fc.getSelectedFile()==null) return;
  String savePath = fc.getSelectedFile().getAbsolutePath();
  println("file selected");
  if (savePath == null) {
    // If a file was not selected
    println("No output file was selected...");
  } else {
    // If a file was selected, save image to path
    println("saving to "+savePath);
    save(savePath);
    println("saved");
  }
}

color getPixel(int x, int y) {
  return pixels[x+(y*width)];
}

void setPixel(int x, int y, color c) {
  pixels[x+(y*width)]=c;
}

void falsifyCurrent() {
  for (int i=0;i<width;i++) {
    for (int j=0;j<height;j++) {
      current[i][j]=false;
    }
  }
}

synchronized Pair getNextObject(){
  Pair retval=null;
  while(opperations.size()>0&&(retval=opperations.remove(0/*(int)(Math.random()*opperations.size())*/))==null);
  return retval;
}

void fillAllPixels(){
  while (opperations.size()>0) {
    Pair myPair=getNextObject();
    if(myPair==null) break;
    int x=myPair.x, y=myPair.y;
    if (current[x][y]) continue;
    fillPixel(x, y);
    boolean iscpx = (x==centerPair.x&&y==centerPair.y);
    if (((y+1)<height)&&!current[x][y+1]) {
      if (iscpx||(RANDOMFACTOR==0)||random(RANDOMFACTOR+1)>1) opperations.add(new Pair(x, y+1));
    }
    if (((x+1)<width)&&!current[x+1][y]) {
      if (iscpx||(RANDOMFACTOR==0)||random(RANDOMFACTOR+1)>1) opperations.add(new Pair(x+1, y));
    }
    if (((y-1)>=0)&&!current[x][y-1]) {
      if (iscpx||(RANDOMFACTOR==0)||random(RANDOMFACTOR+1)>1) opperations.add(new Pair(x, y-1));
    }
    if (((x-1)>=0)&&!current[x-1][y]) {
      if (iscpx||(RANDOMFACTOR==0)||random(RANDOMFACTOR+1)>1) opperations.add(new Pair(x-1, y));
    }
  }
  doneCount++;
  if(doneCount==THREADNUM){
    synchronized(this){
      this.notifyAll();
    }
  }
}

void fillAll() {
  loadPixels();
  doneCount=0;
  for(int i=0;i<THREADNUM;i++){
    exec.execute(new Runnable(){
      public void run(){
        System.out.println("running");
        fillAllPixels();
      }
    });
  }
  /*try{
    exec.awaitTermination(10,TimeUnit.SECONDS);
  }catch(InterruptedException ie){}*/
  synchronized(this){
    try{
      wait();
    }catch(InterruptedException ie){}
  }
  //while(doneCount<THREADNUM);
  finalizePixels(1);
  updatePixels();
  pixnum=0;
}

void randomSeedPixels(){
  for(int x=0;x<width;x++){
    for(int y=0;y<height;y++){
      if(!current[x][y]&&random(1000)<2){
        for(int i=x;i<x+10&&i<width;i++){
          for(int j=y;j<y+10&&j<height;j++){
            if(!current[i][j]) fillPixel(i,j);
            //println("("+i+","+j+")");
          }
        }
      }
    }
  }
}

void finalizePixels(int how){
  if(how==0){
    randomSeedPixels();
    for(int x=0;x<width;x++){
      for(int y=0;y<height;y++){
        if(!current[x][y]) fillPixel(x,y);
      }
    }
  }else if(how==1){
    for(int x=0;x<width;x++){
      for(int y=0;y<height;y++){
        if(!current[x][y]) fillPixel(x,y);
      }
    }
  }else if(how==2){
    for(int x=0;x<width;x++){
      for(int y=0;y<height;y++){
        if(!current[x][y]) setPixel(x,y,color(0,0,0));
      }
    }
  }else if(how==3){
    boolean[][] localcurrent = new boolean[width][height];
    opperations.add(centerPair);
    while (opperations.size()>0) {
      Pair myPair=getNextObject();
      int x=myPair.x, y=myPair.y;
      if(localcurrent[x][y]) continue;
      if (!current[x][y]) fillPixel(x, y);
      if (((y+1)<height)&&!localcurrent[x][y+1]) {
        opperations.add(new Pair(x, y+1));
      }
      if (((x+1)<width)&&!localcurrent[x+1][y]) {
        opperations.add(new Pair(x+1, y));
      }
      if (((y-1)>=0)&&!localcurrent[x][y-1]) {
        opperations.add(new Pair(x, y-1));
      }
      if (((x-1)>=0)&&!localcurrent[x-1][y]) {
        opperations.add(new Pair(x-1, y));
      }
      localcurrent[x][y]=true;
    }
  }
}

void printloc(int x, int y){
  print("("+x+","+y+")");
}

void fillPixel(int x, int y) {
  int maxr=255, minr=0, maxg=255, ming=0, maxb=255, minb=0;
  color neighborColors[]=new color[5];
  int neighborsFullYet=0;
  if (((y+1)<height)&&current[x][y+1]) {
    neighborColors[neighborsFullYet++] = getPixel(x, y+1);
  }
  if (((x+1)<width)&&current[x+1][y]) {
    neighborColors[neighborsFullYet++] = getPixel(x+1, y);
  }
  if (((y-1)>=0)&&current[x][y-1]) {
    neighborColors[neighborsFullYet++] = getPixel(x, y-1);
  }
  if (((x-1)>=0)&&current[x-1][y]) {
    neighborColors[neighborsFullYet++] = getPixel(x-1, y);
  }
  for (int i=0;i<neighborsFullYet;i++) {
    color curCol = neighborColors[i];
    int curr=(int)red(curCol), curg=(int)green(curCol), curb=(int)blue(curCol);
    if (maxr>curr) maxr=(curr+posvar);
    if (minr<curr) minr=(curr-negvar);
    if (maxg>curg) maxg=(curg+posvar);
    if (ming<curg) ming=(curg-negvar);
    if (maxb>curb) maxb=(curb+posvar);
    if (minb<curb) minb=(curb-negvar);
  }
  
  if (maxr<0) maxr=5;
  if (maxr>255) maxr=255;
  if (minr<0) minr=0;
  if (minr>255) minr=250;
  if (maxg<0) maxg=5;
  if (maxg>255) maxg=255;
  if (ming<0) ming=0;
  if (ming>255) ming=250;
  if (maxb<0) maxb=5;
  if (maxb>255) maxb=255;
  if (minb<0) minb=0;
  if (minb>255) minb=250;

  if (maxr<minr) {
    maxr=(minr+maxr)/2;
    minr=maxr;
  }
  if (maxg<ming) {
    maxg=(ming+maxg)/2;
    ming=maxg;
  }
  if (maxb<minb) {
    maxb=(minb+maxb)/2;
    minb=maxb;
  }

  int r=bound(biasedRandom(minr, maxr, CENTERBIAS, RBIAS),GREYFACTOR,255-GREYFACTOR);
  int g=bound(biasedRandom(ming, maxg, CENTERBIAS, GBIAS),GREYFACTOR,255-GREYFACTOR);
  int b=bound(biasedRandom(minb, maxb, CENTERBIAS, BBIAS),GREYFACTOR,255-GREYFACTOR);
  setPixel(x, y, color(r, g, b));
  current[x][y]=true;
}

int bound(int x, int min, int max){
  return min(max(x,min),max);
}

int biasedRandom(int minVal, int maxVal, int biastocenter, double biasFactor) {
  //if (framenum!=0) return (int)random(maxVal-minVal+1)+minVal;
  float n = 0F;
  for(int i=0;i<biastocenter;i++){
    n+=(random((float)(maxVal-minVal+biasFactor+1))+minVal)/biastocenter;
  }
  return (int) n;
  //return (int) (random((float)(maxVal-minVal+biasFactor+1))+minVal);
}

