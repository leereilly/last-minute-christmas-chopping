/*
  Copyright (C) 2013 John McCutchan <john@johnmccutchan.com>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

*/

part of vector_math;

class Aabb3 {
  final Vector3 _min;
  final Vector3 _max;

  Vector3 get min => _min;
  Vector3 get max => _max;

  Vector3 get center {
    Vector3 c = new Vector3.copy(_min);
    return c.add(_max).scale(.5);
  }

  Aabb3() :
    _min = new Vector3.zero(),
    _max = new Vector3.zero() {}

  Aabb3.copy(Aabb3 other) :
    _min = new Vector3.copy(other._min),
    _max = new Vector3.copy(other._max) {}

  Aabb3.minmax(Vector3 min_, Vector3 max_) :
    _min = new Vector3.copy(min_),
    _max = new Vector3.copy(max_) {}

  void copyMinMax(Vector3 min_, Vector3 max_) {
    max_.setFrom(_max);
    min_.setFrom(_min);
  }

  void copyCenterAndHalfExtents(Vector3 center, Vector3 halfExtents) {
    center.setFrom(_min);
    center.add(_max);
    center.scale(0.5);
    halfExtents.setFrom(_max);
    halfExtents.sub(_min);
    halfExtents.scale(0.5);
  }

  void copyFrom(Aabb3 o) {
    _min.setFrom(o._min);
    _max.setFrom(o._max);
  }

  void copyInto(Aabb3 o) {
    o._min.setFrom(_min);
    o._max.setFrom(_max);
  }

  Aabb3 transform(Matrix4 T) {
    Vector3 center = new Vector3.zero();
    Vector3 halfExtents = new Vector3.zero();
    copyCenterAndHalfExtents(center, halfExtents);
    T.transform3(center);
    T.absoluteRotate(halfExtents);
    _min.setFrom(center);
    _max.setFrom(center);

    _min.sub(halfExtents);
    _max.add(halfExtents);
    return this;
  }

  Aabb3 rotate(Matrix4 T) {
    Vector3 center = new Vector3.zero();
    Vector3 halfExtents = new Vector3.zero();
    copyCenterAndHalfExtents(center, halfExtents);
    T.absoluteRotate(halfExtents);
    _min.setFrom(center);
    _max.setFrom(center);

    _min.sub(halfExtents);
    _max.add(halfExtents);
    return this;
  }

  Aabb3 transformed(Matrix4 T, Aabb3 out) {
    out.copyFrom(this);
    return out.transform(T);
  }

  Aabb3 rotated(Matrix4 T, Aabb3 out) {
    out.copyFrom(this);
    return out.rotate(T);
  }

  void getPN(Vector3 planeNormal, Vector3 outP, Vector3 outN) {
    outP.x = planeNormal.x < 0.0 ? _min.x : _max.x;
    outP.y = planeNormal.y < 0.0 ? _min.y : _max.y;
    outP.z = planeNormal.z < 0.0 ? _min.z : _max.z;

    outN.x = planeNormal.x < 0.0 ? _max.x : _min.x;
    outN.y = planeNormal.y < 0.0 ? _max.y : _min.y;
    outN.z = planeNormal.z < 0.0 ? _max.z : _min.z;
  }

  /// Set the min and max of [this] so that [this] is a hull of [this] and [other].
  void hull(Aabb3 other) {
    min.x = Math.min(_min.x, other.min.x);
    min.y = Math.min(_min.y, other.min.y);
    min.z = Math.min(_min.z, other.min.z);
    max.x = Math.max(_max.x, other.max.x);
    max.y = Math.max(_max.y, other.max.y);
    max.z = Math.max(_max.z, other.max.y);
  }

  /// Return if [this] contains [other].
  bool contains(Aabb3 other) {
    return min.x < other.min.x &&
           min.y < other.min.y &&
           min.z < other.min.z &&
           max.x > other.max.x &&
           max.y > other.max.y &&
           max.z > other.max.z;
  }

  /// Return if [this] intersects with [other].
  bool intersectsWith(Aabb3 other) {
    return min.x <= other.max.x &&
           min.y <= other.max.y &&
           min.z <= other.max.z &&
           max.x >= other.min.x &&
           max.y >= other.min.y &&
           max.z >= other.min.z;
  }
}
