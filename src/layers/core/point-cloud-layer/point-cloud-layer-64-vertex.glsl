// Copyright (c) 2015 Uber Technologies, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#define SHADER_NAME point-cloud-layer-64-vertex-shader

attribute vec3 positions;

attribute vec3 instancePositions;
attribute vec2 instancePositions64xyLow;
attribute vec3 instanceNormals;
attribute vec4 instanceColors;
attribute vec3 instancePickingColors;

uniform float renderPickingBuffer;
uniform float opacity;
uniform float radius;
uniform vec2 screenSize;

varying vec4 vColor;
varying vec2 unitPosition;

void main(void) {
  // position on the containing square in [-1, 1] space
  unitPosition = positions.xy;

  vec4 instancePositions64xy = vec4(instancePositions.x, instancePositions64xyLow.x, instancePositions.y, instancePositions64xyLow.y);
  vec2 projected_coord_xy[2];
  project_position_fp64(instancePositions64xy, projected_coord_xy);

  vec2 vertex_pos_localspace[4];
  vec4_fp64(vec4(positions.xy * radius / screenSize * 2.0, 0.0, 0.0), vertex_pos_localspace);

  vec2 vertex_pos_modelspace[4];
  vertex_pos_modelspace[0] = sum_fp64(vertex_pos_localspace[0], projected_coord_xy[0]);
  vertex_pos_modelspace[1] = sum_fp64(vertex_pos_localspace[1], projected_coord_xy[1]);
  vertex_pos_modelspace[2] = sum_fp64(vertex_pos_localspace[2], vec2(project_scale(instancePositions.z), 0.0));
  vertex_pos_modelspace[3] = vec2(1.0, 0.0);

  gl_Position = project_to_clipspace_fp64(vertex_pos_modelspace);

  vec4 position_worldspace = vec4(projected_coord_xy[0].x, projected_coord_xy[1].x, project_scale(instancePositions.z), 1.0);

  // Find the center of the point and add the current vertex
  // vec4 position_worldspace = vec4(project_position(instancePositions), 1.0);
  // vec2 vertex = positions.xy * radius / screenSize * 2.0;
  // gl_Position = project_to_clipspace(position_worldspace) + vec4(vertex, 0.0, 0.0);

  if (renderPickingBuffer > 0.5) {
    vColor = vec4(instancePickingColors / 255., 1.);
  } else {
    // Apply lighting
    float lightWeight = getLightWeight(position_worldspace, instanceNormals);

    // Apply opacity to instance color, or return instance picking color
    vColor = vec4(lightWeight * instanceColors.rgb, instanceColors.a * opacity) / 255.;
  }

  // // Apply lighting
  // float lightWeight = getLightWeight(position_worldspace, instanceNormals);

  // // Apply opacity to instance color, or return instance picking color
  // vec4 color = vec4(lightWeight * instanceColors.rgb, instanceColors.a * opacity) / 255.;
  // vec4 pickingColor = vec4(instancePickingColors / 255., 1.);
  // vColor = mix(color, pickingColor, renderPickingBuffer);
}
