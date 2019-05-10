using UnityEngine;
using System.Collections;
using System;

public class Cube : MonoBehaviour {
	private void Start () {
		Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
	}
}