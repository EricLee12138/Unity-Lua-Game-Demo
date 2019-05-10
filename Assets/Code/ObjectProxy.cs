using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class ObjectProxy {
    // --------- transform --------
    private static Dictionary<int, Transform> trans_map = new Dictionary<int, Transform>();
	public static void transRegister(int id, Transform t, bool dont_destroy = true)
    {
        Debug.Assert(!trans_map.ContainsKey(id));
        trans_map[id] = t;
        if (dont_destroy)
        {
            Object.DontDestroyOnLoad(t.gameObject);
        }
    }
    public static void transRegister(int id, GameObject go, bool dont_destroy = true)
    {
        transRegister(id, go.transform, dont_destroy);
    }
    public static void transUnregister(int id, bool destroy = true)
    {
        Transform t;
        if (trans_map.TryGetValue(id, out t))
        {
            trans_map.Remove(id);
            if (null != t)
            {
                Object.Destroy(t.gameObject);
            }
        }
    }
    public static void transSetPosition(int id, Vector3 p)
    {
        trans_map[id].position = p;
    }
    public static void transSetRotation(int id, Vector3 r)
    {
        trans_map[id].localEulerAngles = r;
    }
    public static void transSetScale(int id, Vector3 s)
    {
        trans_map[id].localScale = s;
    }
    public static BoxCollider getBoxCollider(int id)
    {
		var c = trans_map [id].gameObject.GetComponent<BoxCollider> ();
		return c;
    }
    public static void animSetBool(int id, string name, bool value)
    {
        var anim = trans_map [id].gameObject.GetComponent<Animator> ();
        anim.SetBool(name, value);
    }
    public static void animSetFloat(int id, string name, float value)
    {
        var anim = trans_map [id].gameObject.GetComponent<Animator> ();
        anim.SetFloat(name, value);
    }
    // ----------------------------
}
