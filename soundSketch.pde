//Background:
//Connected to the arduino side there are 10 total sensors. Pressing each should make a different sound. One sensor will be used for volume control 
//make the serial print which pad has been touched(eg values 0-9 or letters A-J (Only 9 values displayed as pads.)). This is what the processing code will parse and read in to  play the appropriate sound or toggle volume.
//Last pad will control the volume. toggle between off, medium or high.
//playing approriate sound is the main functionality. probably will use a switch statement or smth. 

//Processing will handle UI
//UI : Do not overcomplicate. Ask if there are questions but keep things clean and simple 
//- will have home page
//     - Bg gradiend top to bottom
//     - "DJ Soundboard" text displayed in the center
//     - big Start button right under title
//-will have play page
//     -  set the gradient to a rectangle only at the top. add waveform. samplecode to help w that at top
//     - waveform will show only in the gradient rectangle 
//      - rest of the screen is some dark shade of grey
//    - displays 9  rounded boxes, each labeled with sound, color similar to dj soundboard, red yellow, blue (pad brightens and fades)
//     - pad boxes in a 3x3 layout.
//    - disply the different soundwaves(maybe embed video? whatever i get from things like WaveVisual.  this is for visual clarity) at the top inside the gradient middle
//     - when coresponding pad clicked, appropriate box lights up while sound being played.
//     - volume will be displyed on the bottom. either as Off, Medium or High
//TASK:  
//set up logic and serial connection
// volume functionality will come later
//probably will use a switch statement. Input should be characters from A-J
//J will be used to toggle the volume
//open the serial connection. read in and parse input. depending on input play correct sound and display waveform
// input will be letters A through J. A- I will corespond to sound files and pads while the last will toggle volume. 
//will also need some arduino code to simulate possible input. No simulation code on procsseing tho.
import processing.serial.*;
Serial myPort;

import processing.sound.*;
SoundFile file;

//  CONSTANTS 
int Y_AXIS = 1;
int X_AXIS = 2;
color c1, c2;

//  STATES 
int HOME = 0;
int PLAY = 1;
int state = HOME;

//  START BUTTON 
float btnX, btnY, btnW = 220, btnH = 80;

//  PAD GRID (3x3) 
int cols = 3;
int rows = 3;

float padW = 120;
float padH = 120;
float padSpacing = 40;

// labels A–I
String[] labels = {
  "A","B","C",
  "D","E","F",
  "G","H","I"
};

// DJ pad colors
color[] padColors = {
  color(255,60,60),   // red
  color(255,200,0),   // yellow
  color(80,150,255),  // blue
  color(80,150,255),  // blue
  color(255,60,60),   // red
  color(255,200,0),   // yellow
  color(255,200,0),   // yellow
  color(80,150,255),  // blue
  color(255,60,60)    // red
};

// Brightness tracking for pad animation
float[] padBrightness = new float[9];
float fadeSpeed = 0.95;

//SOUND FILES STUFF
// volume display
String volumeState = "Medium";
int volumeLevel = 1; // 0=Off, 1=Medium, 2=High

import processing.sound.*;

SoundFile[] sounds = new SoundFile[9]; // 9 pads
String[] filenames = {
  "Air horn.mp3", "Boom.mp3", "Car horn .mp3",
  "Disk spin 1.mp3", "Disk spin 2.mp3", "Disk spin 3.mp3",
  "Disk spin 4.mp3", "Money .mp3", "Suspicious .mp3"
};

Waveform waveform; // one waveform for the currently playing sound
int samples = 100;

// Serial connection status
boolean serialConnected = false;
String serialStatus = "Disconnected";
int lastConnectionCheck = 0;
int connectionCheckInterval = 1000; // Check every second

// Serial input buffer
String serialBuffer = "";

//  SETUP 
void setup() {
  size(700,700);
  
  // Initialize Serial
  printArray(Serial.list());
  
  // Try to open the first available port
  if (Serial.list().length > 0) {
    String portName = Serial.list()[0];
    try {
      myPort = new Serial(this, portName, 9600);
      myPort.bufferUntil('\n'); // Trigger serialEvent on newline
      serialConnected = true;
      serialStatus = "Connected to: " + portName;
      println("✓ " + serialStatus);
    } catch (Exception e) {
      serialConnected = false;
      serialStatus = "Failed to connect to: " + portName;
      println("✗ " + serialStatus);
      println("  Error: " + e.getMessage());
    }
  } else {
    serialConnected = false;
    serialStatus = "No serial ports available - running in demo mode";
    println("✗ " + serialStatus);
  }

  c1 = color(204,102,0);
  c2 = color(0,102,153);

  textAlign(CENTER, CENTER);
  rectMode(CORNER);
  
  // Initialize all sound files
  for(int i = 0; i < sounds.length; i++) {
    sounds[i] = new SoundFile(this, filenames[i]);
    padBrightness[i] = 0; // Start with no brightness
  }

  // initialize waveform (connect it to the first sound by default)
  waveform = new Waveform(this, samples);
  if(sounds[0] != null) {
    waveform.input(sounds[0]);
  }
}

//  MAIN DRAW 
void draw() {
  // Check serial connection status periodically
  if (millis() - lastConnectionCheck > connectionCheckInterval) {
    checkSerialConnection();
    lastConnectionCheck = millis();
  }
  
  if(state == HOME) {
    drawHome();
  } else if(state == PLAY) {
    // Fade all pads gradually
    for(int i = 0; i < padBrightness.length; i++) {
      padBrightness[i] *= fadeSpeed;
      if(padBrightness[i] < 0.01) padBrightness[i] = 0;
    }
    drawPlay();
  }
}

// Check if serial connection is still active
void checkSerialConnection() {
  if (myPort != null) {
    if (myPort.active()) {
      if (!serialConnected) {
        serialConnected = true;
        serialStatus = "Connected - receiving data";
        println("✓ Serial connection established");
      }
    } else {
      if (serialConnected) {
        serialConnected = false;
        serialStatus = "Disconnected - check USB cable";
        println("✗ Serial connection lost");
      }
    }
  }
}

//  SERIAL EVENT - Called when data is received
void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  
  if(inString != null) {
    inString = trim(inString); // Remove whitespace
    
    if(inString.length() > 0) {
      println("📡 Received: '" + inString + "'"); // Debug with icon
      
      // Parse the input - expecting single character A-J or numbers 0-9
      char input = inString.charAt(0);
      
      // Convert numeric input to letters if needed (0-9 -> A-J)
      if (input >= '0' && input <= '9') {
        int num = input - '0';
        if (num >= 0 && num <= 9) {
          if (num == 9) {
            input = 'J'; // 9 maps to J for volume
            println("  → Converted to volume control: " + input);
          } else if (num >= 0 && num <= 8) {
            input = (char)('A' + num); // 0->A, 1->B, etc.
            println("  → Converted to pad: " + input);
          }
        }
      }
      
      // Handle volume pad (J) even if not in PLAY state
      if(input == 'J' || input == 'j') {
        println("  → Toggling volume");
        toggleVolume();
      }
      // Handle sound pads A-I only when in PLAY state
      else if(state == PLAY) {
        if(input >= 'A' && input <= 'I') {
          int padIndex = input - 'A'; // Convert A->0, B->1, etc.
          println("  → Playing sound for pad " + labels[padIndex]);
          playSound(padIndex);
        } else if(input >= 'a' && input <= 'i') {
          int padIndex = input - 'a'; // Handle lowercase
          println("  → Playing sound for pad " + labels[padIndex]);
          playSound(padIndex);
        } else {
          println("  ⚠ Unknown input: '" + input + "' (expected A-J or 0-9)");
        }
      } else {
        println("  ⏸ Input ignored (not in PLAY state)");
      }
    }
  }
}

// Toggle volume between Off, Medium, High
void toggleVolume() {
  volumeLevel = (volumeLevel + 1) % 3;
  
  switch(volumeLevel) {
    case 0:
      volumeState = "Off";
      break;
    case 1:
      volumeState = "Medium";
      break;
    case 2:
      volumeState = "High";
      break;
  }
  
  println("🔊 Volume set to: " + volumeState);
  
  // Update volume for all sounds
  float vol = 0;
  if(volumeLevel == 1) vol = 0.5;
  if(volumeLevel == 2) vol = 1.0;
  
  for(SoundFile s : sounds) {
    if(s != null) {
      s.amp(vol);
    }
  }
}

// Play a sound and trigger visual feedback
void playSound(int index) {
  if(index >= 0 && index < sounds.length && sounds[index] != null) {
    // Stop the sound if it's already playing, then play again
    sounds[index].stop();
    sounds[index].play();
    
    // Set waveform input to this sound for visualization
    waveform.input(sounds[index]);
    
    // Trigger pad brightness
    padBrightness[index] = 1.0;
    
    println("🎵 Playing: " + labels[index] + " (" + filenames[index] + ")");
  } else {
    println("⚠ Error: Sound file not loaded for index " + index);
  }
}

//  HOME PAGE 
void drawHome() {
  setGradient(0, 0, width, height, c1, c2, Y_AXIS);

  fill(255);
  textSize(60);
  text("DJ Soundboard", width/2, height/2 - 100);
  
  // Draw serial status on home screen
  drawSerialStatus();

  drawStartButton();
}

// Draw serial connection status
void drawSerialStatus() {
  // Status background
  fill(0, 0, 0, 200);
  noStroke();
  rect(10, 10, 280, 30, 10);
  
  // Status text
  if (serialConnected) {
    fill(0, 255, 0);
  } else {
    fill(255, 0, 0);
  }
  textSize(12);
  textAlign(LEFT, CENTER);
  text("Serial: " + serialStatus, 20, 25);
  textAlign(CENTER, CENTER);
}

//  START BUTTON 
void drawStartButton() {
  btnX = width/2 - btnW/2;
  btnY = height/2;

  fill(255);
  stroke(0);
  rect(btnX, btnY, btnW, btnH, 20);

  fill(0);
  textSize(26);
  text("START", width/2, btnY + btnH/2);
}

//  PLAY PAGE 
void drawPlay() {
  background(40);
  
  // Draw serial status on play screen too
  drawSerialStatus();

  // gradient bar
  setGradient(0, 0, width, 150, c1, c2, Y_AXIS);

  drawWave();
  drawPads();
  drawVolume();
}

//  PAD GRID 
void drawPads() {
  int index = 0;

  float totalWidth = cols * padW + (cols-1) * padSpacing;
  float startX = width/2 - totalWidth/2;
  float startY = 200;

  for(int r = 0; r < rows; r++) {
    for(int c = 0; c < cols; c++) {
      float x = startX + c * (padW + padSpacing);
      float y = startY + r * (padH + padSpacing);

      // Brighten the pad based on padBrightness
      color brightColor = lerpColor(
        padColors[index], 
        color(255), 
        padBrightness[index]
      );
      
      stroke(brightColor);
      strokeWeight(4);
      fill(brightColor, 180);

      rect(x, y, padW, padH, 25);

      fill(255);
      textSize(22);
      text(labels[index], x + padW/2, y + padH/2);

      index++;
    }
  }
}

//  WAVEFORM 
void drawWave() {
  if(waveform != null) {
    waveform.analyze();

    stroke(255);
    strokeWeight(2);
    noFill();

    beginShape();
    for(int i = 0; i < samples; i++) {
      float x = map(i, 0, samples, 0, width);
      float y = map(waveform.data[i], -1, 1, 20, 130);
      vertex(x, y);
    }
    endShape();
  }
}

//  VOLUME DISPLAY 
void drawVolume() {
  fill(255);
  textSize(20);
  text("Volume: " + volumeState, width/2, height - 40);
}

//  GRADIENT FUNCTION 
void setGradient(int x, int y, float w, float h, color c1, color c2, int axis) {
  noFill();

  if(axis == Y_AXIS) {
    for(int i = y; i <= y + h; i++) {
      float inter = map(i, y, y + h, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(x, i, x + w, i);
    }
  }
}

//  CLICK HANDLING 
void mousePressed() {
  if(state == HOME) {
    if(mouseX > btnX && mouseX < btnX + btnW &&
       mouseY > btnY && mouseY < btnY + btnH) {
      state = PLAY;
      println("🎮 Entered PLAY mode");
    }
  } else if(state == PLAY) {
    // Check if any pad was clicked for testing without Arduino
    float totalWidth = cols * padW + (cols-1) * padSpacing;
    float startX = width/2 - totalWidth/2;
    float startY = 200;
    
    for(int r = 0; r < rows; r++) {
      for(int c = 0; c < cols; c++) {
        float x = startX + c * (padW + padSpacing);
        float y = startY + r * (padH + padSpacing);
        int index = r * cols + c;
        
        if(mouseX > x && mouseX < x + padW &&
           mouseY > y && mouseY < y + padH) {
          // Simulate pad press for testing
          println("🖱️ Mouse clicked pad " + labels[index]);
          playSound(index);
        }
      }
    }
  }
}

// For testing without Arduino - press keys A-I on keyboard
void keyPressed() {
  if(state == PLAY) {
    if(key >= 'a' && key <= 'i') {
      int index = key - 'a';
      println("⌨️ Keyboard press: " + key);
      playSound(index);
    } else if(key >= 'A' && key <= 'I') {
      int index = key - 'A';
      println("⌨️ Keyboard press: " + key);
      playSound(index);
    } else if(key == 'j' || key == 'J') {
      println("⌨️ Keyboard press: " + key + " - toggling volume");
      toggleVolume();
    }
  }
}
