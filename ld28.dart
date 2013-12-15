/**
 * THIS CODE IS AWFUL!
 * 
 * It was written over a weekend for a game development competition.
 * 
 * I kinda was going to write something sane when I got started, and have the Shader stuff
 * in its own file, but then as Ludum Dare went on, I kinda.. stopped. It's a big spaghetti
 * mess now.
 * 
 * Enjoy!
 * 
 * / Markus "Notch" Persson
 */

library ld28;

import 'dart:html';
import 'dart:web_audio';
import 'dart:convert';
import 'dart:math' as Math;
import 'dart:web_gl' as WebGL;
import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';

part 'shader.dart';

WebGL.RenderingContext gl;

class Sample {
  static AudioContext context;
  static GainNode gainNode;
  
  static Sample jump = new Sample("snd/jump.wav");
  static Sample swingMiss = new Sample("snd/swingMiss.wav");
  static Sample swingChopTree = new Sample("snd/swingTree.wav");
  static Sample swingChopTentacle = new Sample("snd/swingTentacle.wav");
  static Sample swingHitRock = new Sample("snd/swingRock.wav");
  static Sample hurt = new Sample("snd/hurt.wav");
  static Sample powerSwing = new Sample("snd/powerSwing.wav");
  static Sample teleportIn = new Sample("snd/teleportIn.wav");
  static Sample teleportOut = new Sample("snd/teleportOut.wav");
  static Sample blipLeft = new Sample("snd/blip.wav");
  static Sample blipRight = new Sample("snd/blipRight.wav"); // Intentionally swapped
  static Sample blip = new Sample("snd/blipLeft.wav"); // Too lazy to rename;
  
  static bool soundFailed = false;
  static bool soundOn = true;
  
  static void init() {
    try {
      context = new AudioContext();
      gainNode = context.createGainNode();
      gainNode.connectNode(context.destination);

      jump.load();
      swingMiss.load();
      swingChopTree.load();
      swingChopTentacle.load();
      swingHitRock.load();
      hurt.load();
      powerSwing.load();
      teleportIn.load();
      teleportOut.load();
      blipLeft.load();
      blipRight.load();
      blip.load();
    } catch (e) {
      print(e);
      soundFailed = true;
    }
  }

  bool loaded = false;
  HttpRequest request;
  AudioBuffer buffer;
  String path;
  
  Sample(this.path) {
  }
  
  void load() {
    try {
      request = new HttpRequest();
      request.responseType = "arraybuffer";
      request.onLoad.listen(sampleLoaded);
      request.open("GET", path, async:true);
      request.send();
    } catch (e) {
      print(e);
    }
  }
  
  void sampleLoaded(ProgressEvent e) {
    context.decodeAudioData(request.response).then((e){
      buffer = e;
      loaded = true;
    });
  }
  
  void play() {
    if (!loaded || soundFailed || !soundOn) return;
    try {
      AudioBufferSourceNode sourceNode = context.createBufferSource();
      sourceNode.connectNode(gainNode);
      sourceNode.buffer = buffer;
      sourceNode.noteOn(0);
    } catch (e) {
      print(e);
      soundFailed = true;
    }
  }
}

class Obstacle {
  Vector3 pos;
  double radius;
  
  Obstacle(this.pos, this.radius);

  bool tick() {
    return true;
  }
  
  void hurt(bool special) {
  }
  
  void render(Quad quad, Vector3 pos, Vector4 color) {
  }
  
  bool blocks() {
    return true;
  }
  
  void ejectPlayer(Vector2 normal, double length) {
    playerPos.xz-=normal*length;
  }
}

class Tree extends Obstacle {
  int hurtTime = 0;
  bool specialKilled = false;
  
  Tree(var pos) : super(pos, 5.0);

  void hurt(bool special) {
    if (hurtTime==0) {
      specialKilled = special;
/*      if (special) {
        for (int i=0; i<4; i++) {
          obstacles.add(new Loot(pos+new Vector3(random.nextDouble()*16.0-8.0, -2.0-random.nextDouble()*32.0, 0.0),0));
        }
      }*/
      hurtTime = 10;
      hitTree = true;
    }
  }

  bool tick() {
    if (hurtTime>1) {
      hurtTime--;
      if (hurtTime<8) {
        obstacles.add(new Loot(pos+new Vector3(random.nextDouble()*16.0-8.0, -2.0-random.nextDouble()*32.0, 0.0),0));
        if (specialKilled)
          obstacles.add(new Loot(pos+new Vector3(random.nextDouble()*16.0-8.0, -2.0-random.nextDouble()*32.0, 0.0),0));
      }
    }
    return (pos.z-playerPos.z)<32;
  }

  static Vector4 hurtColor = new Vector4(1.0, 0.0, 0.0, 0.8);
  void render(Quad quad, Vector3 pos, Vector4 color) {
    if (hurtTime==1)
      quad.renderBillboard(pos, 32, 48, 64, 0, color);
    else if (hurtTime~/2%2==0)
      quad.renderBillboard(pos, 32, 48, 32, 0, color);
    else 
      quad.renderBillboard(pos, 32, 48, 32, 0, color, hurtColor);
  }
  
  bool blocks() {
    return hurtTime==0;
  }
}

class Tentacle extends Obstacle {
  int hurtTime = 0;
  int life = 3;
  
  Tentacle(var pos) : super(pos, 5.0);

  void hurt(bool special) {
    if (hurtTime==0) {
      hurtTime = 10;
      if (playerPos.y>-4.0) {
        hitTentacle = true;
        life = 0;
      } else {
        hitRock = true;
      }
    }
  }

  bool tick() {
    if (hurtTime>1 || (life>0 && hurtTime>0)) {
      hurtTime--;
      if (hurtTime<10 && life==0) {
        obstacles.add(new Loot(pos+new Vector3(random.nextDouble()*16.0-8.0, -2.0-random.nextDouble()*32.0, 0.0),1));
      }
/*      if (hurtTime<5) {
        obstacles.add(new Loot(pos+new Vector3(random.nextDouble()*16.0-8.0, -2.0-random.nextDouble()*32.0, 0.0)));
      }*/
    }
    return (pos.z-playerPos.z)<32;
  }

  static Vector4 hurtColor = new Vector4(1.0, 0.0, 0.0, 0.8);
  static Vector4 noHurtColor = new Vector4(1.0, 1.0, 1.0, 0.8);
  void render(Quad quad, Vector3 pos, Vector4 color) {
    if (hurtTime==1 && life==0)
      quad.renderBillboard(pos, 32, 48, 64, 48, color);
    else if (hurtTime~/2%2==0)
      quad.renderBillboard(pos, 32, 48, 32, 48, color);
    else if (life==0)
      quad.renderBillboard(pos, 32, 48, 32, 48, color, hurtColor);
    else
      quad.renderBillboard(pos, 32, 48, 32, 48, color, noHurtColor);
  }
  
  bool blocks() {
    return hurtTime==0 || life>0;
  }
  
  void ejectPlayer(Vector2 normal, double length) {
    super.ejectPlayer(normal, length);
    if (playerHurtTime==0) {
      playerPos.xz-=normal*4.0;
      playerPosA.xz-=normal*4.0;
      playerPos.y-=2.5;
      playerPosA.y=-1.5;
      playerHurtTime = 20;
      Sample.hurt.play();
    }
  }
}

class Rock extends Obstacle {
  int hurtTime = 0;
  
  Rock(var pos) : super(pos, 8.0);

  void hurt(bool special) {
    if (hurtTime==0 && blocks()) {
      hitRock = true;
      hurtTime = 10;
    }
  }

  bool tick() {
    if (hurtTime>0) {
      hurtTime--;
    }
    return (pos.z-playerPos.z)<32;
  }

  static Vector4 hurtColor = new Vector4(1.0, 0.0, 0.0, 0.8);
  static Vector4 noHurtColor = new Vector4(1.0, 1.0, 1.0, 0.8);
  void render(Quad quad, Vector3 pos, Vector4 color) {
    if (hurtTime~/2%2==0)
      quad.renderBillboard(pos, 32, 16, 96, 16, color);
    else
      quad.renderBillboard(pos, 32, 16, 96, 16, color, noHurtColor);
  }
  
  bool blocks() {
    return playerPos.y>-8.0;
  }
  
  void ejectPlayer(Vector2 normal, double length) {
    if (playerPos.y>-5.0) {
      super.ejectPlayer(normal, length);
    } else {
      playerPos.y = -8.0;
    }
//    playerPos.xz-=normal*2.0;
//    playerPosA.xz-=normal*2.0;
  }
}

class Loot extends Obstacle {
  double life = 1.0;
  double lifeDrain;
  Vector3 motion;
  Vector3 iPos;
  int type;
  int tickCount = 0;
  
  Loot(Vector3 pos, this.type) : super(pos, 1.0) {
    lifeDrain = random.nextDouble()*0.02+0.04;
    iPos = pos.clone();
    double xa = (random.nextDouble()-0.5)*2.5;
    double ya = (random.nextDouble()-0.5)*2.5-1.5;
    double za = (random.nextDouble()-1.0)*1.2-1.5;
    motion = new Vector3(xa, ya, za);
  }

  void hurt(bool special) {
  }

  bool tick() {
    tickCount++;
    life-=lifeDrain;
    iPos+=motion;
    motion*=0.998;
    double t = Math.sqrt(life);
    pos = iPos*t+playerPos*(1.0-t);
    if (life<=0) {
      if (type==0) playerWood++;
      if (type==1) playerGoop++;
      if (playerGoop>maxGoop) playerGoop = maxGoop;
    }
    return life>0;
  }

  static Vector4 blinkColor = new Vector4(1.0, 1.0, 0.0, 0.6);
  void render(Quad quad, Vector3 pos, Vector4 color) {
    if (tickCount~/4%2==0)
      quad.renderBillboard(pos, 16, 16, 96+type*16, 0, color);
    else
      quad.renderBillboard(pos, 16, 16, 96+type*16, 0, color, blinkColor);
  }
  
  bool blocks() {
    return false;
  }
}

class Particle extends Obstacle {
  double life = 1.0;
  double lifeDrain;
  Vector3 motion;
  int type;
  int tickCount = 0;
  
  Particle(Vector3 pos, this.type) : super(pos, 1.0) {
    lifeDrain = (random.nextDouble()*0.02+0.04)*0.2;
    double xa = (random.nextDouble()-0.5)*2.5;
    double ya = (random.nextDouble()-0.5)*1.5-2.5;
    double za = (random.nextDouble()-0.5)*1.2-1.5;
    motion = new Vector3(xa, ya, za);
  }

  void hurt(bool special) {
  }

  bool tick() {
    tickCount++;
    life-=lifeDrain;
    pos+=motion;
    if (pos.y>0.0){
      pos.y = 0.0;
      motion*=0.9;
    }
    motion.xz*=0.99;
    motion.y+=0.3;
    double t = Math.sqrt(life);
    return life>0;
  }

  static Vector4 blinkColor = new Vector4(1.0, 0.0, 0.0, 0.6);
  void render(Quad quad, Vector3 pos, Vector4 color) {
    if (tickCount~/4%2==0)
      quad.renderBillboard(pos, 16, 16, 96+type*16, 0, color);
    else
      quad.renderBillboard(pos, 16, 16, 96+type*16, 0, color, blinkColor);
  }
  
  bool blocks() {
    return false;
  }
}

class Texture {
  static List<Texture> _pendingTextures = new List<Texture>();
  
  String url;
  WebGL.Texture texture;
  int width, height;
  bool loaded = false;
  
  Texture(this.url) {
    if (gl==null) {
      _pendingTextures.add(this);
    } else {
      _load();
    }
  }
  
  static void loadAll() {
    _pendingTextures.forEach((e)=>e._load());
    _pendingTextures.clear();
  }
  
  void _load() {
    ImageElement img = new ImageElement();
    texture = gl.createTexture();
    img.onLoad.listen((e) {
      gl.bindTexture(WebGL.TEXTURE_2D, texture);
      gl.texImage2DImage(WebGL.TEXTURE_2D, 0, WebGL.RGBA, WebGL.RGBA, WebGL.UNSIGNED_BYTE, img);
      gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.NEAREST);
      gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.NEAREST);
      width = img.width;
      height = img.height;
      loaded = true;
    });
    img.src = url;
  }
}

class Quad {
  Shader shader;
  int posLocation;
  WebGL.UniformLocation objectTransformLocation, cameraTransformLocation, viewTransformLocation, textureTransformLocation;
  WebGL.UniformLocation colorLocation, replaceColorLocation, fogColorLocation, flashlightLocation;
  Texture texture;
  
  Quad(this.shader) {
    posLocation = gl.getAttribLocation(shader.program, "a_pos");
    
    objectTransformLocation = gl.getUniformLocation(shader.program, "u_objectTransform");
    cameraTransformLocation = gl.getUniformLocation(shader.program, "u_cameraTransform");
    viewTransformLocation = gl.getUniformLocation(shader.program, "u_viewTransform");
    textureTransformLocation = gl.getUniformLocation(shader.program, "u_textureTransform");
    colorLocation = gl.getUniformLocation(shader.program, "u_color");
    fogColorLocation = gl.getUniformLocation(shader.program, "u_fogColor");
    flashlightLocation = gl.getUniformLocation(shader.program, "u_flashLight"); 
    replaceColorLocation = gl.getUniformLocation(shader.program, "u_replaceColor");
    
    Float32List vertexArray = new Float32List(4*3);
    vertexArray.setAll(0*3, [0.0, 0.0, 0.0]);
    vertexArray.setAll(1*3, [0.0, 1.0, 0.0]);
    vertexArray.setAll(2*3, [1.0, 1.0, 0.0]);
    vertexArray.setAll(3*3, [1.0, 0.0, 0.0]);
    
    Int16List indexArray = new Int16List(6);
    indexArray.setAll(0, [0, 1, 2, 0, 2, 3]);

    gl.useProgram(shader.program);
    gl.enableVertexAttribArray(posLocation);
    WebGL.Buffer vertexBuffer =  gl.createBuffer(); 
    gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferDataTyped(WebGL.ARRAY_BUFFER, vertexArray, WebGL.STATIC_DRAW);
    gl.vertexAttribPointer(posLocation, 3, WebGL.FLOAT, false, 0, 0);

    WebGL.Buffer indexBuffer =  gl.createBuffer(); 
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferDataTyped(WebGL.ELEMENT_ARRAY_BUFFER, indexArray, WebGL.STATIC_DRAW);
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indexBuffer);
  }
  
  void setTexture(Texture texture) {
    this.texture = texture;
    gl.bindTexture(WebGL.TEXTURE_2D, texture.texture);
  }
  
  void setFlashlight(Vector3 pos, double intensity) {
    gl.uniform4f(flashlightLocation, pos.x, pos.y, pos.z, intensity);
  }
  
  void setFogColor(Vector3 fogColor) {
    gl.uniform3fv(fogColorLocation, fogColor.storage);
  }

  void setCamera(Matrix4 viewMatrix, Matrix4 cameraMatrix) {
    gl.uniformMatrix4fv(viewTransformLocation, false, viewMatrix.storage);
    gl.uniformMatrix4fv(cameraTransformLocation, false, cameraMatrix.storage);
  }

  Matrix4 objectMatrix = new Matrix4.identity();
  Matrix4 textureMatrix = new Matrix4.identity();
  
  Vector4 whiteColor = new Vector4(1.0, 1.0, 1.0, 1.0);
  Vector4 noReplaceColor = new Vector4(0.0, 0.0, 0.0, 0.0);
  
  void renderBillboard(Vector3 pos, int w, int h, num uo, num vo, [Vector4 color = null, Vector4 replaceColor = null]) {
    if (!texture.loaded) return;
    if (color==null) color = whiteColor;
    if (replaceColor==null) replaceColor = noReplaceColor;
    
    objectMatrix.setIdentity();
    objectMatrix.translate(pos.x-w/2.0, pos.y-h*1.0, pos.z);
    objectMatrix.scale(w*1.0, h*1.0, 0.0);
    gl.uniformMatrix4fv(objectTransformLocation, false, objectMatrix.storage);
    
    textureMatrix.setIdentity();
    textureMatrix.scale(1.0/texture.width, 1.0/texture.height, 0.0);
    textureMatrix.translate((uo+0.25), (vo+0.25), 0.0);
    textureMatrix.scale((w-0.5), (h-0.5), 0.0);
    gl.uniformMatrix4fv(textureTransformLocation, false, textureMatrix.storage);
    
    gl.uniform4fv(colorLocation, color.storage);
    gl.uniform4fv(replaceColorLocation, replaceColor.storage);
    gl.drawElements(WebGL.TRIANGLES, 6, WebGL.UNSIGNED_SHORT, 0);
  }
  
  void render(Vector3 pos, int w, int h, int uo, int vo, Vector4 color) {
    if (!texture.loaded) return;
    
    objectMatrix.setIdentity();
    objectMatrix.translate(pos.x, pos.y, pos.z);
    objectMatrix.scale(w*1.0, h*1.0, 0.0);
    gl.uniformMatrix4fv(objectTransformLocation, false, objectMatrix.storage);
    
    textureMatrix.setIdentity();
    textureMatrix.scale(1.0/texture.width, 1.0/texture.height, 0.0);
    textureMatrix.translate(uo*1.0, vo*1.0, 0.0);
    textureMatrix.scale(w*1.0, h*1.0, 0.0);
    gl.uniformMatrix4fv(textureTransformLocation, false, textureMatrix.storage);
    
    gl.uniform4fv(colorLocation, color.storage);
    gl.uniform4fv(replaceColorLocation, noReplaceColor.storage);
    gl.drawElements(WebGL.TRIANGLES, 6, WebGL.UNSIGNED_SHORT, 0);
  }
}

const int STATE_TITLE_SCREEN = 0; 
const int STATE_PLAY_GAME = 1; 
const int STATE_WIN_GAME = 2; 
const int STATE_LOSE_GAME = 3; 

bool hitTree, hitTentacle, hitRock;

Vector3 playerPos = new Vector3(0.0, 0.0, 0.0);
Vector3 playerPosA = new Vector3(0.0, 0.0, 0.0);
List<Obstacle> obstacles = new List<Obstacle>();
Math.Random random = new Math.Random();
int playerHurtTime = 0;
int playerWood = 0;
int playerGoop = 0;
int maxGoop = 100;
int targetWood = 1000;
int playerTimeLimit = 60*60;
int gameState = STATE_TITLE_SCREEN;

class Game {
  static const ATTACK_DURATION = 10;
  
  CanvasElement canvas;
  Quad quad;

  Texture sheetTexture = new Texture("tex/sheet.png");
  Texture groundTexture = new Texture("tex/ground.png");
  Texture snowTexture = new Texture("tex/snow.png");
  Texture logoTexture = new Texture("tex/logo.png");
  
  List<bool> keysDown = new List<bool>(256);
  List<bool> keysPressed = new List<bool>(256);
  
  List<Vector3> snowOffs = new List<Vector3>(32);
  
  Vector3 fogColor = new Vector3(0.2, 0.2, 0.2);
  
  static const int spawnDuration = 30; 
  int spawnTime = spawnDuration+30;

  
  double fov = 70.0;
  int attackTime = 0;
  
  void start() {
    keysDown.fillRange(0, keysDown.length, false);
    keysPressed.fillRange(0, keysPressed.length, false);
    canvas = querySelector("#game_canvas");
    gl = canvas.getContext("webgl");
    if (gl==null) {
      gl = canvas.getContext("experimental-webgl");
    }
    if (gl==null) {
      crashNoWebGL();
      return;
    }
    quad = new Quad(quadShader);
    Texture.loadAll();
    window.onKeyDown.listen(onKeyDown);
    window.onKeyUp.listen(onKeyUp);
    window.requestAnimationFrame(animate);
    Sample.init();
    
    gl.enable(WebGL.DEPTH_TEST);
    gl.depthFunc(WebGL.LESS);
    gl.enable(WebGL.BLEND);
    gl.blendFunc(WebGL.SRC_ALPHA, WebGL.ONE_MINUS_SRC_ALPHA);
    gl.colorMask(true, true, true, false);
    
    for (int i=0; i<32; i++) {
      snowOffs[i] = new Vector3(random.nextDouble()*256.0, random.nextDouble()*256.0, random.nextDouble());
    }
  }
  
  void onKeyDown(KeyboardEvent e) {
    if (e.keyCode<keysDown.length) {
      if (!keysDown[e.keyCode]) {
        keysPressed[e.keyCode]=true;
        keysDown[e.keyCode]=true;
      }
    }
  }

  void onKeyUp(KeyboardEvent e) {
    if (e.keyCode<keysDown.length) keysDown[e.keyCode]=false;
  }
  
  int lastTime = new DateTime.now().millisecondsSinceEpoch;
  double unprocessedFrames = 0.0;
  
  void animate(double time) {
    try {
      int now = new DateTime.now().millisecondsSinceEpoch;
      unprocessedFrames+=(now-lastTime)*60.0/1000.0; // 60 fps
      lastTime = now;
      if (unprocessedFrames>10.0) unprocessedFrames = 10.0; 
      while (unprocessedFrames>1.0) {
        tick();
        unprocessedFrames-=1.0;
      }
      render();
      
      window.requestAnimationFrame(animate);
    } catch (e) {
      crash(e);
      rethrow;
    }
  }

  int tickCount = 0;
  int playerTime = 0;
  bool canAttack = false;
  int levelProgression = 0;
  
  void tick() {
    tickCount++;
    if (gameState==STATE_TITLE_SCREEN) tickTitleScreen();
    else if (gameState==STATE_PLAY_GAME) tickPlayGame();
    else if (gameState==STATE_WIN_GAME || gameState==STATE_LOSE_GAME) tickWinLoseGame();
    keysPressed.fillRange(0, keysPressed.length, false);
  }
  
  int waitToWinTime = 0;
  void startGame() {
    waitToWinTime = 0;
    levelProgression = 0;
    obstacles.clear();
    playerGoop = 0;
    playerHurtTime = 0;
    playerWood = 0;
    playerTime = 0;
    playerPos.setValues(0.0, 0.0, 0.0);
    playerPosA.setValues(0.0, 0.0, 0.0);
    gameState = STATE_PLAY_GAME;
    spawnTime = spawnDuration+30;
  }

  void tickPlayGame() {
    updateLevelProgression();

    bool gameIsOver = false;
    
    if (playerTime>=playerTimeLimit) {
      playerTime = playerTimeLimit;
      gameIsOver = true;
    }
    if (playerWood>=targetWood) {
      playerWood = targetWood;
      gameIsOver = true;
    }
    if (!gameIsOver && spawnTime>0) {
      if (spawnTime==spawnDuration) {
        Sample.teleportIn.play();
      }
      spawnTime--;
      return;
    }
    
    if (attackTime>0) attackTime--;
    if (playerHurtTime>0) {
      if (!gameIsOver && playerHurtTime%2==0 && playerWood>0) {
        obstacles.add(new Particle(playerPos+new Vector3(0.0, -9.0, 0.0), 0));
        playerWood--;
      }
      playerHurtTime--; 
    }
    if (!gameIsOver) {
      playerTime++;
      double speed = (playerPos.y==0)?0.3:0.2;
      playerPosA.z-=0.1;
      if (keysDown[37]) { // left
        playerPosA.x-=speed;
      }
      if (keysDown[39]) { // right
        playerPosA.x+=speed;
      }
      if (keysDown[65]) { // Jump!
        if (playerPos.y==0) {
          Sample.jump.play();
          playerPosA.y = -2.0;
        }
      }
      if (keysDown[83]) { // Attack!
        if (attackTime==0 && canAttack && playerHurtTime<10) {
          canAttack = false;
          attackTime = ATTACK_DURATION;
          bool special = false;
          if (playerPos.y!=0) {
            if (keysDown[65] && playerGoop>0) {
              obstacles.add(new Particle(playerPos+new Vector3(0.0, -9.0, 0.0), 1));
              playerGoop--;
              playerPosA.y = -0.7;
              playerPosA.z -= 1.0;
              special = true;
            }
          } else {
            playerPosA.y = -0.5;
          }
          if (special) {
            Sample.powerSwing.play();
          }
          hitTree = hitTentacle = hitRock = false;
          attack(special);
          if (!hitTree && !hitRock && !hitTentacle) {
            Sample.swingMiss.play();
          } else {
            if (hitTree) Sample.swingChopTree.play();
            if (hitTentacle) Sample.swingChopTentacle.play();
            if (hitRock) Sample.swingHitRock.play();
          }
        }
      } else {
        canAttack = true;
      }
    }
    Vector3 oldPos = playerPos.clone();
    playerPos+=playerPosA;
    for (int i=0; i<2; i++) {
      ejectPlayer();
    }
    
    for (int i=0; i<obstacles.length; i++) {
      bool alive = obstacles[i].tick();
      if (!alive) obstacles.removeAt(i--);
    }
    
    playerPosA += ((playerPos-oldPos)-playerPosA)*0.1;
    
    playerPosA.x*=(playerPos.y==0)?0.8:0.9;
    playerPosA.y+=0.15;
    playerPosA.z*=0.9;
    
    if (gameIsOver) {
      if (waitToWinTime++>=60 || playerPosA.xz.length2<0.001 && (playerPos.y==0.0 || playerPos.y==-8.0)) {
        playerPosA*=0.0;
        if (spawnTime==0) {
          Sample.teleportOut.play();
        }
        spawnTime++;
        if (spawnTime==60) {
          toWinLoseState(playerWood==targetWood?STATE_WIN_GAME:STATE_LOSE_GAME);
        }
        return;
      }
    }
  }
  
  void updateLevelProgression() {
    int lp = (-playerPos.z.floor())+512;
    while (levelProgression<lp) {
      
      double x = (random.nextDouble()-0.5)*128;
      double z = -levelProgression-64.0;
      
      levelProgression+=8;
      if (random.nextInt(4)==0)
        obstacles.add(new Rock(new Vector3(x, 0.0, z)));
      else if (random.nextInt(5)==0)
        obstacles.add(new Tentacle(new Vector3(x, 0.0, z)));
      else
        obstacles.add(new Tree(new Vector3(x, 0.0, z)));
    }
  }
  
  void attack(bool special) {
    getObstaclesIn(playerPos+new Vector3(0.0, 0.0, -16.0), 8.0).forEach((e){e.hurt(special);});
  }
  
  void ejectPlayer() {
    double max = 64.0;
    if (playerPos.x<-max) playerPos.x = -max;
    if (playerPos.x>max) playerPos.x = max;
    if (playerPos.y>0.0) playerPos.y = 0.0;
    if (playerPos.y<-32.0) playerPos.y = -32.0;
    
    double playerRadius = 4.0;
        
    
    for (int i=0; i<obstacles.length; i++) {
      if (!obstacles[i].blocks()) continue;
      Vector2 treePos = obstacles[i].pos.xz;
      Vector2 dist = treePos-playerPos.xz;
      dist.y*=2.0;
      
      double treeRadius = obstacles[i].radius;
      double combinedRadius = playerRadius+treeRadius;
      
      if (dist.length2<combinedRadius*combinedRadius) {
        double length = dist.length;
        dist.normalize();
        obstacles[i].ejectPlayer(dist, combinedRadius-length);
      }
    }
  }
  
  List<Obstacle> getObstaclesIn(Vector3 c, double r) {
    List<Obstacle> result = [];
    for (int i=0; i<obstacles.length; i++) {
      Vector2 treePos = obstacles[i].pos.xz;
      Vector2 dist = treePos-c.xz;
      
      double treeRadius = obstacles[i].radius;
      double combinedRadius = r+treeRadius;
      
      if (dist.length2<combinedRadius*combinedRadius) {
        result.add(obstacles[i]);
      }
    }
    return result;
  }

  Matrix4 createSkewMatrix(double skew) {
    Matrix4 result = new Matrix4.identity();
    result.storage[9] = skew;
    return result;
  }
  
  
  void toTitleScreen() {
    titleScreenPage = 0;
    titleScreenPageOffs = -8.0;
    gameState = STATE_TITLE_SCREEN;
  }

  int titleScreenPage = 0;
  double titleScreenPageOffs = -8.0;
  void tickTitleScreen() {
    if (keysPressed[37]) { // left
      if (titleScreenPage>0) {
        titleScreenPage--;
        Sample.blipLeft.play();
      }
    }
    if (keysPressed[39]) { // right
      if (titleScreenPage<5) {
        titleScreenPage++;
        Sample.blipRight.play();
      }
    }
    if (keysPressed[65] || keysPressed[83]) { // Jump or attack
      Sample.blip.play();
      startGame();
    }
  }

  void tickWinLoseGame() {
    if (keysPressed[65] || keysPressed[83]) { // Jump or attack
      Sample.blip.play();
      toTitleScreen();
    }
  }

  void toWinLoseState(int state) {
    gameState = state;
  }
    
  void render() {
    if (gameState==STATE_TITLE_SCREEN) renderTitleScreen();
    else if (gameState==STATE_PLAY_GAME) renderPlayGame();
    else if (gameState==STATE_WIN_GAME || gameState==STATE_LOSE_GAME) renderWinLoseGame();
  }
  
  void renderWinLoseGame() {
    quad.setFlashlight(playerPos, 1.0);
    fogColor.setValues(0.1, 0.1, 0.2);
    double pixelScale = 2.0;
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(fogColor.r, fogColor.g, fogColor.b, 1.0);
    quad.setFogColor(fogColor);
    gl.clear(WebGL.DEPTH_BUFFER_BIT | WebGL.COLOR_BUFFER_BIT);
    
    Matrix4 viewMatrix = makePerspectiveMatrix(fov*Math.PI/180, canvas.width/canvas.height, 0.01, 3.0);
    double scale = pixelScale*2.0/canvas.height;
    
    double zPos = -tickCount*0.05;
    Matrix4 screenMatrix = new Matrix4.identity().scale(scale, -scale, scale);
    Matrix4 cameraMatrix = new Matrix4.identity().translate(0.0*0.6, 128.0-0.0*0.6, -32.0-zPos);
    Matrix4 floorCameraMatrix = new Matrix4.identity().rotateX(Math.PI/2.0);

    Vector4 whiteColor = new Vector4(0.4, 0.4, 0.4, 1.0);
    Vector4 hurtColor = new Vector4(1.0, 0.0, 0.0, 0.8);

    quad.setCamera(viewMatrix, screenMatrix);
    quad.setTexture(snowTexture);
    for (int i=0; i<16; i++) {
      double z = (-i*16-zPos);
      z -= (z/256.0).ceilToDouble()*256.0;
      z+=zPos+32.0;
      double swing = tickCount*(snowOffs[i].z*0.2+0.1)*0.1;
      double u = snowOffs[i].x+Math.sin(swing)*6;
      double v = snowOffs[i].y-tickCount*0.1-Math.cos(swing).abs()*1;
      quad.renderBillboard(cameraMatrix*new Vector3(0.0, 0.0, z), 512, 256, u, v, whiteColor);
    }

    whiteColor = new Vector4(1.0, 1.0, 1.0, 1.0);
    gl.disable(WebGL.DEPTH_TEST);
    viewMatrix = makeOrthographicMatrix(0, canvas.width, canvas.height, 0, 0.01, 3.0);
    scale = 3.0;
    screenMatrix = new Matrix4.identity().scale(scale, scale, 1.0);

    quad.setCamera(viewMatrix, screenMatrix);
    double pageWidth = (853~/scale)*1.0;
    int xo = (((853~/scale)-256)~/2);
    quad.setTexture(logoTexture);
    if (gameState==STATE_WIN_GAME) {
      quad.render(new Vector3(xo*1.0-16.0, 0.0, -1.0), 128, 128, 0, 128, whiteColor);
    } else {
      quad.render(new Vector3(xo*1.0-16.0, 0.0, -1.0), 128, 128, 128, 128, whiteColor);
    }
    quad.setTexture(sheetTexture);
    drawText("This is Child.", xo+96, 32+8*0, whiteColor);
    
    int pow = random.nextInt(2);
    int xxo = (random.nextInt(3)-1)*pow;
    int yyo = (random.nextInt(3)-1)*pow;
    
    if (gameState==STATE_WIN_GAME) {
      drawText("Santa made Child so happy.", xo+96, 32+8*1, whiteColor);
      drawText("YOU ONLY SPENT ${playerTime~/60} SECONDS!", xo+96+xxo, 32+8*6+yyo, whiteColor);
    } else {
      drawText("Santa made Child sad.", xo+96, 32+8*1, whiteColor);
      drawText("YOU ONLY HAD ONE MINUTE!", xo+96+xxo, 32+8*6+yyo, whiteColor);
    }
    drawText("Santa got a score of ${(playerWood*playerTimeLimit~/playerTime)}.", xo+96, 32+8*3, whiteColor);
    

    if (tickCount~/10%2!=100) {
      whiteColor = new Vector4(1.0, 1.0, 0.5, 1.0);
      int yo = tickCount~/8%3==0?1:0;
      String msg = "Press A or S to continue!"; 
      int xo = ((853~/scale)-msg.length*6)~/2;
      drawText(msg, xo, 160-24+2+yo, whiteColor);
    }
    
    gl.enable(WebGL.DEPTH_TEST);
  }

  void renderTitleScreen() {
    quad.setFlashlight(playerPos, 1.0);
    fogColor.setValues(0.1, 0.1, 0.2);
    double pixelScale = 2.0;
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(fogColor.r, fogColor.g, fogColor.b, 1.0);
    quad.setFogColor(fogColor);
    gl.clear(WebGL.DEPTH_BUFFER_BIT | WebGL.COLOR_BUFFER_BIT);
    
    Matrix4 viewMatrix = makePerspectiveMatrix(fov*Math.PI/180, canvas.width/canvas.height, 0.01, 3.0);
    double scale = pixelScale*2.0/canvas.height;
    
    double zPos = -tickCount*0.05;
    Matrix4 screenMatrix = new Matrix4.identity().scale(scale, -scale, scale);
    Matrix4 cameraMatrix = new Matrix4.identity().translate(0.0*0.6, 128.0-0.0*0.6, -32.0-zPos);
    Matrix4 floorCameraMatrix = new Matrix4.identity().rotateX(Math.PI/2.0);

    Vector4 whiteColor = new Vector4(0.4, 0.4, 0.4, 1.0);
    Vector4 hurtColor = new Vector4(1.0, 0.0, 0.0, 0.8);

    quad.setCamera(viewMatrix, screenMatrix);
    quad.setTexture(snowTexture);
    for (int i=0; i<16; i++) {
      double z = (-i*16-zPos);
      z -= (z/256.0).ceilToDouble()*256.0;
      z+=zPos+32.0;
      double swing = tickCount*(snowOffs[i].z*0.2+0.1)*0.1;
      double u = snowOffs[i].x+Math.sin(swing)*6;
      double v = snowOffs[i].y-tickCount*0.1-Math.cos(swing).abs()*1;
      quad.renderBillboard(cameraMatrix*new Vector3(0.0, 0.0, z), 512, 256, u, v, whiteColor);
    }

    whiteColor = new Vector4(1.0, 1.0, 1.0, 1.0);
    gl.disable(WebGL.DEPTH_TEST);
    viewMatrix = makeOrthographicMatrix(0, canvas.width, canvas.height, 0, 0.01, 3.0);
    scale = 3.0;
    screenMatrix = new Matrix4.identity().scale(scale, scale, 1.0);

/*    int pages = 2;
    int ticksPerPage = 60*2;
    int ticksPerSlide = 40;
    double pageOffset = (tickCount%ticksPerPage)/ticksPerSlide;
    int page = (tickCount~/ticksPerPage-1);
    if (page>0) page%=pages;
    if (pageOffset>1.0) pageOffset = 1.0;
    pageOffset = 1.0-(Math.cos(pageOffset*Math.PI)*0.5+0.5);*/
    titleScreenPageOffs+=(titleScreenPage-titleScreenPageOffs)*0.2;
    double pageOffset = titleScreenPageOffs;
    
    

    quad.setCamera(viewMatrix, screenMatrix);
    double pageWidth = (853~/scale)*1.0;
    for (int i=0; i<6; i++) {
      int xo = ((((853~/scale)-256)~/2)+((i)*pageWidth)-pageOffset*pageWidth).floor();
      if (i==0) {
        quad.setTexture(logoTexture);
        quad.render(new Vector3(xo*1.0, 16.0, -1.0), 256, 128, 0, 0, whiteColor);
      } else if (i==1) {
        quad.setTexture(sheetTexture);
        int animFrame = tickCount~/10%2;
        quad.render(new Vector3(xo*1.0+8, 16.0, -1.0), 16, 24, animFrame*16, 0, whiteColor);
        drawText("This is Santa.", xo+30, 20, whiteColor);
        drawText("Santa has forgotten about christmas.", xo+30, 20+8, whiteColor);
        drawText("Santa's elves needs to make gifts.", xo+30, 20+16, whiteColor);

        quad.render(new Vector3(xo*1.0, 16.0+32+8, -1.0), 32, 48, 32, 0, whiteColor);
        drawText("This is Tree.", xo+28+8, 30+32+8, whiteColor);
        drawText("To make gifts, Santa needs wood.", xo+28+8, 30+32+8+8, whiteColor);
        drawText("To chop Tree, Santa presses S.", xo+28+8, 30+32+16+8, whiteColor);
      } else if (i==2) {
        quad.render(new Vector3(xo*1.0, 16.0+4, -1.0), 32, 16, 96, 16, whiteColor);
        drawText("This is Rock.", xo+36, 22, whiteColor);
        drawText("To jump Rock, Santa presses A.", xo+36, 22+8, whiteColor);

        quad.render(new Vector3(xo*1.0, 16.0+32+8, -1.0), 32, 48, 32, 48, whiteColor);
        drawText("This is Tentacle.", xo+28+8, 30+32+8, whiteColor);
        drawText("Tentacle makes Santa lose wood.", xo+28+8, 30+32+8+8, whiteColor);
        drawText("To chop Tentacle, Santa aims low.", xo+28+8, 30+32+16+8, whiteColor);
      } else if (i==3) {
        int sunPos = xo-(4-(tickCount%847/844)*(256-8)).floor();
        int woodPos = xo-(4-(tickCount%524/524)*(256-8)).floor();
        int goopPos = xo-(4-(Math.sin(tickCount*0.0173823)*0.5+0.5)*(256-8)).floor();
        quad.render((new Vector3(xo*1.0, 4.0+8+8, -1.0)), 256, 8, 0, 256-16, whiteColor);
        
        quad.render((new Vector3(xo*1.0, 64.0, -1.0)), 256, 8, 0, 256-8, whiteColor);
        quad.render((new Vector3(goopPos*1.0, 64.0-4.0, -1.0)), 16, 16, 32, 256-32, whiteColor);
        
        if (woodPos>sunPos) {
          quad.render((new Vector3(sunPos*1.0, 0.0+8+8, -1.0)), 16, 16, 0, 256-32, whiteColor);
          quad.render((new Vector3(woodPos*1.0, 0.0+8+8, -1.0)), 16, 16, 16, 256-32, whiteColor);
        } else {
          quad.render((new Vector3(woodPos*1.0, 0.0+8+8, -1.0)), 16, 16, 16, 256-32, whiteColor);
          quad.render((new Vector3(sunPos*1.0, 0.0+8+8, -1.0)), 16, 16, 0, 256-32, whiteColor);
        }
        drawText("This is Progress Meter.", xo+8, 24+8, whiteColor);
        drawText("To win, make wood reach end before sun.", xo+8, 24+8+8, whiteColor);
        
        drawText("This is Goop Meter.", xo+8, 76, whiteColor);
        drawText("Goop fills by chopping Tentacle.", xo+8, 76+8, whiteColor);
        drawText("Santa holds A and taps S to use Goop.", xo+8, 76+8+8, whiteColor);
      } else if (i==4) {
        String msg = "You only get one minute!!! OMG!"; 
        int pow = random.nextInt(2);
        int xxo = ((256)-msg.length*6)~/2+(random.nextInt(3)-1)*pow;
        int yyo = (random.nextInt(3)-1)*pow;
        drawText(msg, xo+xxo, 58+yyo, whiteColor);
      } else if (i==5) {
        drawText("--- Last Minute Christmas Chopping ---", xo+14, 24, whiteColor);
        drawText("A game made in 48 hours for Ludum Dare", xo+14, 24+16+8*0, whiteColor);
        drawText('programmed in Dart, using WebGL, made ', xo+14, 24+16+8*1, whiteColor);
        drawText('by Markus "Notch" Persson.            ', xo+14, 24+16+8*2, whiteColor);
        drawText('Sunday December 15, 2013. <3', xo+14, 24+16+8*4, whiteColor);
        drawText('See ludumdare.com for more like this!', xo+14, 24+16+8*7, whiteColor);
      }
      
    }
    
    quad.setTexture(sheetTexture);

    if (tickCount~/10%2!=100) {
      whiteColor = new Vector4(1.0, 1.0, 0.5, 1.0);
      int yo = tickCount~/8%3==0?1:0;
      String msg = "Press A or S to start!"; 
      int xo = ((853~/scale)-msg.length*6)~/2;
      drawText(msg, xo, 160-8-24+yo, whiteColor);

      msg = "Press arrow keys for instructions!"; 
      xo = ((853~/scale)-msg.length*6)~/2;
      drawText(msg, xo, 160-24+2+yo, whiteColor);
    }
    
    gl.enable(WebGL.DEPTH_TEST);
 }

  void renderPlayGame() {
    double dayProgress = 1.0-playerTime/playerTimeLimit;
    dayProgress = (Math.sqrt(dayProgress)+dayProgress)*0.5;
    double blueFog = dayProgress*dayProgress*0.4;
    fogColor.setValues(Math.min(dayProgress*0.3,blueFog), Math.min(dayProgress*0.3, blueFog), blueFog);
    double pixelScale = 2.0;
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(fogColor.r, fogColor.g, fogColor.b, 1.0);
    gl.clear(WebGL.DEPTH_BUFFER_BIT | WebGL.COLOR_BUFFER_BIT);
    quad.setFogColor(fogColor);
    
    
    Matrix4 viewMatrix = makePerspectiveMatrix(fov*Math.PI/180, canvas.width/canvas.height, 0.01, 3.0);
    double scale = pixelScale*2.0/canvas.height;
    Matrix4 screenMatrix = new Matrix4.identity().scale(scale, -scale, scale);
    Matrix4 cameraMatrix = new Matrix4.identity().translate(-playerPos.x*0.6, 16.0-playerPos.y*0.6, -32.0-playerPos.z);
    Matrix4 floorCameraMatrix = new Matrix4.identity().rotateX(Math.PI/2.0);

    if (spawnTime>0) {
      double yy = spawnTime-10.0;
      if (yy<0.0) yy = 0.0;
      yy = yy*yy*0.1;
      quad.setFlashlight(new Vector3(playerPos.x*scale*0.4, -(playerPos.y+16.0-yy*4)*scale*0.4, -16.0*scale), (dayProgress*dayProgress)*0.9+0.1);
    } else {
      quad.setFlashlight(new Vector3(playerPos.x*scale*0.4, -(playerPos.y+16.0)*scale*0.4, -33.0*scale), (dayProgress*dayProgress)*0.9+0.1);
    }


    Vector4 whiteColor = new Vector4(1.0, 1.0, 1.0, 1.0);
    Vector4 hurtColor = new Vector4(1.0, 0.0, 0.0, 0.8);


    quad.setCamera(viewMatrix, screenMatrix*cameraMatrix*floorCameraMatrix);
    double groundOffset = (playerPos.z/256.0).ceilToDouble()*256.0;
    quad.setTexture(groundTexture);
    quad.render(new Vector3(-512.0, -240.0+groundOffset, 0.0), 1024, 256, 0, 0, whiteColor);
    quad.render(new Vector3(-512.0, -240.0-256.0+groundOffset, 0.0), 1024, 256, 0, 0, whiteColor);
    
    quad.setCamera(viewMatrix, screenMatrix);
    quad.setTexture(snowTexture);
    for (int i=0; i<16; i++) {
      double z = (-i*16-playerPos.z);
      z -= (z/256.0).ceilToDouble()*256.0;
      z+=playerPos.z+32.0;
      double swing = tickCount*(snowOffs[i].z*0.2+0.1)*0.1;
      double u = snowOffs[i].x+Math.sin(swing)*6;
      double v = snowOffs[i].y-tickCount*0.1-Math.cos(swing).abs()*1;
      quad.renderBillboard(cameraMatrix*new Vector3(0.0, 0.0, z), 512, 256, u, v, whiteColor);
    }
    quad.setTexture(sheetTexture);
    for (int i=0; i<16; i++) {
      double z = (-i*16-playerPos.z);
      z -= (z/256.0).ceilToDouble()*256.0;
      z+=playerPos.z+32.0;
      double swing = (snowOffs[i].z-0.5)*8;
      quad.renderBillboard(cameraMatrix*new Vector3(-80.0+swing, 0.0, z), 32, 48, 128, 0, whiteColor);
      quad.renderBillboard(cameraMatrix*new Vector3(80.0+swing, 0.0, z), 32, 48, 128, 0, whiteColor);
    }
    
    if (spawnTime>0) {
      if (spawnTime<spawnDuration) {
        if (spawnTime~/2%2==0) {
          quad.renderBillboard(cameraMatrix*playerPos, 16, 240, 240, 0, whiteColor);
        }
        if (spawnTime<spawnDuration*3~/3) {
          double yy = spawnTime-10.0;
          if (yy<0.0) yy = 0.0;
          yy = yy*yy*0.1;
          quad.renderBillboard(cameraMatrix*playerPos+new Vector3(0.0, -yy, 0.0), 16, 24, 16, 48, whiteColor);
        }
        if (spawnTime<spawnDuration*2~/3) {
          quad.renderBillboard(cameraMatrix*(new Vector3(playerPos.x, 0.0, playerPos.z)), 16, 8, 0, 24, whiteColor);
        }
      }
    } else {
      if (playerHurtTime>0) {
        if (playerHurtTime~/2%2==0)
          quad.renderBillboard(cameraMatrix*playerPos, 16, 24, 16, 48, whiteColor, hurtColor);
        else
          quad.renderBillboard(cameraMatrix*playerPos, 16, 24, 16, 48, whiteColor);
      } else if (attackTime>5) {
        quad.renderBillboard(cameraMatrix*playerPos, 16, 24, 16, 24, whiteColor);
      } else {
        int animFrame = tickCount~/10%2;
        quad.renderBillboard(cameraMatrix*playerPos, 16, 24, animFrame*16, 0, whiteColor);
      }
      quad.renderBillboard(cameraMatrix*(new Vector3(playerPos.x, 0.0, playerPos.z)), 16, 8, 0, 24, whiteColor);
    }
    obstacles.sort((o0, o1){double z = o0.pos.z-o1.pos.z;if (z==0) return 0; return z<0?-1:1;});
    for (int i=0; i<obstacles.length; i++) {
      if (obstacles[i].pos.z>playerPos.z) {
        whiteColor.a = 1.0-(obstacles[i].pos.z-playerPos.z)/24.0;
      } else {
        whiteColor.a = 1.0;
      }
      
      obstacles[i].render(quad, cameraMatrix*obstacles[i].pos, whiteColor);
    }

    quad.setFlashlight(playerPos, 1.0);

    whiteColor.a = 1.0;
    gl.disable(WebGL.DEPTH_TEST);
    viewMatrix = makeOrthographicMatrix(0, canvas.width, canvas.height, 0, 0.01, 3.0);
    scale = 3.0;
    screenMatrix = new Matrix4.identity().scale(scale, scale, 1.0);

    quad.setCamera(viewMatrix, screenMatrix);

    int xo = ((853~/scale)-256)~/2;
    int sunPos = xo-4+playerTime*(256-8)~/(playerTimeLimit);
    int woodPos = xo-4+playerWood*(256-8)~/(targetWood);
    int goopPos = xo-4+playerGoop*(256-8)~/(maxGoop);
    quad.render((new Vector3(xo*1.0, 4.0, -1.0)), 256, 8, 0, 256-16, whiteColor);
    quad.render((new Vector3(xo*1.0, 160-8-4.0, -1.0)), 256, 8, 0, 256-8, whiteColor);
    quad.render((new Vector3(goopPos*1.0, 160-8-8.0, -1.0)), 16, 16, 32, 256-32, whiteColor);
    if (woodPos>sunPos) {
      quad.render((new Vector3(sunPos*1.0, 0.0, -1.0)), 16, 16, 0, 256-32, whiteColor);
      quad.render((new Vector3(woodPos*1.0, 0.0, -1.0)), 16, 16, 16, 256-32, whiteColor);
    } else {
      quad.render((new Vector3(woodPos*1.0, 0.0, -1.0)), 16, 16, 16, 256-32, whiteColor);
      quad.render((new Vector3(sunPos*1.0, 0.0, -1.0)), 16, 16, 0, 256-32, whiteColor);
    }
    
    gl.enable(WebGL.DEPTH_TEST);
  }
  
  void drawText(String text, int x, int y, Vector4 color) {
    Vector3 pos = new Vector3(x*1.0, y*1.0, -1.0);
    for (int i=0; i<text.length; i++) {
      int cu = text.codeUnitAt(i)-32;
      if (cu>=0 && cu<32*3) {
        quad.render(pos, 6, 8, cu%16*6, cu~/16*8+96, color);
      }
      pos.x+=6.0;
    }
    
  }
}


void crashNoWebGL() {
  querySelector("#game_canvas").remove();
  final NodeValidatorBuilder _htmlValidator=new NodeValidatorBuilder.common()
  ..allowElement('a', attributes: ['href']);
  querySelector("#error_log").setInnerHtml('<pre>No WebGL support detected.\rPlease see <a href="http://get.webgl.org/">get.webgl.org</a>.</pre>', validator: _htmlValidator);
}

void crash(e) {
  querySelector("#game_canvas").remove();
  String message = new HtmlEscape().convert(e.toString());
  querySelector("#error_log").setInnerHtml("<pre>CRASH!\r\r$message</pre>");
}

void main() {
  try {
    new Game().start(); 
  }
  catch (e) {
    crash(e);
    rethrow;
  }
}
